import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../models/journey_model.dart';

enum JourneyProviderStatus { idle, loading, active, completed, error }

/// Manages journey tracking state.
///
/// This does NOT do live/continuous GPS tracking — by design, per product
/// decision to avoid the cost/complexity of a live-sharing setup (Firestore)
/// for now. Instead it takes exactly two GPS fixes: one when the user taps
/// "Start Journey", one when they tap "End Journey", and computes the
/// straight-line distance between them (haversine — same formula as the
/// backend's apps.core.utils.haversine_km, so the number matches whether
/// computed here or recomputed server-side).
///
/// Archived to GET/POST /api/v1/journey/summaries/ once the journey ends.
class JourneyProvider extends ChangeNotifier {
  JourneyProviderStatus _status = JourneyProviderStatus.idle;
  JourneyModel? _activeJourney;
  List<JourneyModel> _history = [];
  String? _errorMessage;

  JourneyProviderStatus get status => _status;
  JourneyModel? get activeJourney => _activeJourney;
  List<JourneyModel> get history => _history;
  String? get errorMessage => _errorMessage;
  bool get hasActiveJourney => _activeJourney != null;

  Future<void> loadHistory() async {
    if (_status == JourneyProviderStatus.loading) return;
    _status = JourneyProviderStatus.loading;
    notifyListeners();
    try {
      final response = await ApiService.instance.get('journey/summaries/');
      final data = response.data;
      final results = data is Map<String, dynamic>
          ? (data['results'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);
      _history = results
          .map((j) => JourneyModel.fromApiJson(j as Map<String, dynamic>))
          .toList();
      _status = JourneyProviderStatus.idle;
    } catch (e) {
      _errorMessage = e.toString();
      _status = JourneyProviderStatus.error;
    }
    notifyListeners();
  }

  Future<bool> startJourney({
    required String startAddress,
    String? destinationAddress,
  }) async {
    try {
      final position = await _getCurrentPosition();
      _activeJourney = JourneyModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startAddress: startAddress,
        startTime: DateTime.now(),
        destinationAddress: destinationAddress,
        status: JourneyStatus.active,
        startLat: position.latitude,
        startLng: position.longitude,
      );
      _status = JourneyProviderStatus.active;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> endJourney() async {
    final active = _activeJourney;
    if (active == null) return false;

    try {
      // Second (and only other) GPS fix — captured only when the user
      // explicitly ends the journey, not on a timer or stream.
      final position = await _getCurrentPosition();
      final endLat = position.latitude;
      final endLng = position.longitude;

      double? distanceKm;
      if (active.startLat != null && active.startLng != null) {
        distanceKm = haversineKm(active.startLat!, active.startLng!, endLat, endLng);
      }

      final now = DateTime.now();

      // Backend has no separate address/geocoding field yet — store the
      // raw coordinates as "lat,lng" text in start_point/end_point so the
      // exact points are still recoverable (and verifiable on a map) later.
      final response = await ApiService.instance.post('journey/summaries/', data: {
        'start_point': '${active.startLat},${active.startLng}',
        'end_point': '$endLat,$endLng',
        'started_at': active.startTime.toUtc().toIso8601String(),
        'ended_at': now.toUtc().toIso8601String(),
        'distance_km': distanceKm,
        'was_completed_safely': true,
      });

      final saved = JourneyModel.fromApiJson(response.data as Map<String, dynamic>);
      _history.insert(0, saved);
      _activeJourney = null;
      _status = JourneyProviderStatus.completed;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Requests location permission if needed and returns a single fix.
  /// Throws (caller must catch) if services are off or permission denied —
  /// there is deliberately no silent fallback, since a journey's whole
  /// point is having an accurate start/end point.
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
}
