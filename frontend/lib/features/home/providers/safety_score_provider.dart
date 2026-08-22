import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/api_service.dart';

enum SafetyScoreStatus { idle, loading, loaded, error }

/// Fetches an AI/rule-based safety score for the user's current area.
///
/// Uses a single one-time GPS fix (Geolocator.getCurrentPosition) rather
/// than a continuous location stream — this intentionally does NOT do live
/// location sharing/tracking, per product decision to hold off on that
/// (cost/complexity of Firestore live tracking is a separate, later piece).
///
/// Backend: GET /api/v1/ai/area-score/?lat=&lng= — already fully
/// implemented server-side (apps.ai_assistant.services.get_area_safety_score),
/// scores off nearby Community incident reports, and needs no LLM API key.
class SafetyScoreProvider extends ChangeNotifier {
  SafetyScoreStatus _status = SafetyScoreStatus.idle;
  int? _score;
  int _nearbyReportCount = 0;
  List<String> _categories = [];
  String? _errorMessage;

  SafetyScoreStatus get status => _status;
  int? get score => _score;
  int get nearbyReportCount => _nearbyReportCount;
  List<String> get categories => _categories;
  String? get errorMessage => _errorMessage;

  Future<void> loadScore() async {
    if (_status == SafetyScoreStatus.loading) return;
    _status = SafetyScoreStatus.loading;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const _SafetyScoreException('Location services are turned off on your device.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const _SafetyScoreException('Location permission denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw const _SafetyScoreException('Location permission permanently denied.');
      }

      // One-time fix only — no stream, no continuous tracking, no sharing.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      Response response;
      try {
        response = await ApiService.instance.get(
          'ai/area-score/',
          queryParameters: {
            'lat': position.latitude,
            'lng': position.longitude,
          },
        );
      } on DioException catch (e) {
        // Network/server failure is NOT a location problem — keep them distinct.
        final reason = e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout
            ? "Can't reach the server — check your backend is running and reachable."
            : 'Server error while fetching the safety score.';
        throw _SafetyScoreException(reason);
      }

      final data = response.data as Map<String, dynamic>;
      _score = data['score'] as int?;
      _nearbyReportCount = data['nearby_report_count'] as int? ?? 0;
      _categories = (data['categories'] as List<dynamic>? ?? [])
          .map((c) => c.toString())
          .toList();
      _status = SafetyScoreStatus.loaded;
    } on _SafetyScoreException catch (e) {
      _errorMessage = e.message;
      _status = SafetyScoreStatus.error;
    } catch (e) {
      _errorMessage = e.toString();
      _status = SafetyScoreStatus.error;
    }
    notifyListeners();
  }
}

class _SafetyScoreException implements Exception {
  const _SafetyScoreException(this.message);
  final String message;
}
