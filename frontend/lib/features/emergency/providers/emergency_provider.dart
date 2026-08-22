import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/api_service.dart';

enum EmergencyStatus { idle, counting, active, sent }

/// Manages SOS / emergency feature state, siren audio, and flashlight.
class EmergencyProvider extends ChangeNotifier {
  EmergencyStatus _status = EmergencyStatus.idle;
  int _countdown = 5;
  bool _isSirenOn = false;
  bool _isFlashlightOn = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _lastError;

  EmergencyStatus get status => _status;
  int get countdown => _countdown;
  bool get isSirenOn => _isSirenOn;
  bool get isFlashlightOn => _isFlashlightOn;
  bool get isSosActive => _status == EmergencyStatus.active;
  /// Non-null when the last SOS log call failed to reach the backend.
  /// The siren/UI still stay active — this is surfaced so the screen can
  /// show a small "not confirmed sent" banner without blocking the flow.
  String? get lastError => _lastError;

  /// Start the SOS countdown and automatically start the loud emergency siren.
  Future<void> startCountdown() async {
    if (_status == EmergencyStatus.counting) return;
    _status = EmergencyStatus.counting;
    _countdown = 5;
    notifyListeners();

    // Automate siren sound immediately on SOS button click
    await startSiren();

    while (_countdown > 0 && _status == EmergencyStatus.counting) {
      await Future.delayed(const Duration(seconds: 1));
      _countdown--;
      notifyListeners();
    }

    if (_status == EmergencyStatus.counting) {
      await _sendSos();
    }
  }

  void cancelCountdown() {
    if (_status == EmergencyStatus.counting) {
      _status = EmergencyStatus.idle;
      _countdown = 5;
      stopSiren();
      notifyListeners();
    }
  }

  Future<void> _sendSos() async {
    _status = EmergencyStatus.active;
    _lastError = null;
    notifyListeners();

    // Ensure siren is sounding during active SOS emergency
    if (!_isSirenOn) {
      await startSiren();
    }

    // Safety-critical: never let a network/location failure block the
    // countdown from resolving into an active SOS state. The siren and UI
    // must stay active regardless — we just record whether the log made it
    // to the backend so the screen can show a "not confirmed" hint.
    try {
      final position = await _getCurrentPosition();
      await ApiService.instance.post(
        'accounts/sos-log/',
        data: {
          'location_lat': position.latitude,
          'location_lng': position.longitude,
          'triggered_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      _lastError = 'Could not confirm SOS was sent: $e';
      debugPrint('SOS log failed: $e');
    }
    notifyListeners();

    // TODO: Send SMS to trusted contacts (see backend Twilio integration plan)
    // TODO: Start live location sharing (Journey Phase B / Firestore)
  }

  Future<void> cancelSos() async {
    _status = EmergencyStatus.idle;
    await stopSiren();
    notifyListeners();
    try {
      await ApiService.instance.post('accounts/sos-log/cancel/');
    } catch (e) {
      debugPrint('SOS cancel notify failed: $e');
    }
  }

  /// Requests location permission if needed and returns the current
  /// position. Throws if permission is permanently denied or location
  /// services are off — callers must catch this.
  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Start loud emergency siren audio in loop mode.
  Future<void> startSiren() async {
    _isSirenOn = true;
    notifyListeners();
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('sounds/siren.wav'));
    } catch (e) {
      debugPrint('Siren audio play error: $e');
    }
  }

  /// Stop siren audio.
  Future<void> stopSiren() async {
    _isSirenOn = false;
    notifyListeners();
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Siren audio stop error: $e');
    }
  }

  /// Toggle siren audio on/off.
  Future<void> toggleSiren() async {
    if (_isSirenOn) {
      await stopSiren();
    } else {
      await startSiren();
    }
  }

  void toggleFlashlight() {
    _isFlashlightOn = !_isFlashlightOn;
    notifyListeners();
  }

  void reset() {
    _status = EmergencyStatus.idle;
    _countdown = 5;
    stopSiren();
    _isFlashlightOn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
