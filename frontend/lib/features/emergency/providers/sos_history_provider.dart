import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../models/sos_log_model.dart';

enum SosHistoryStatus { idle, loading, loaded, error }

/// Loads the authenticated user's past SOS events so they can verify — after
/// the fact — that the location an SOS actually saved was correct.
///
/// GET /api/v1/history/sos-events/
class SosHistoryProvider extends ChangeNotifier {
  SosHistoryStatus _status = SosHistoryStatus.idle;
  List<SosLogModel> _events = [];
  String? _errorMessage;

  SosHistoryStatus get status => _status;
  List<SosLogModel> get events => _events;
  String? get errorMessage => _errorMessage;

  Future<void> loadHistory() async {
    if (_status == SosHistoryStatus.loading) return;
    _status = SosHistoryStatus.loading;
    notifyListeners();
    try {
      final response = await ApiService.instance.get('history/sos-events/');
      final data = response.data;
      // DRF paginated response: { count, results: [...] }; falls back to a
      // bare list in case pagination isn't enabled for this view.
      final results = data is Map<String, dynamic>
          ? (data['results'] as List<dynamic>? ?? [])
          : (data as List<dynamic>? ?? []);
      _events = results
          .map((j) => SosLogModel.fromJson(j as Map<String, dynamic>))
          .toList();
      _status = SosHistoryStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = SosHistoryStatus.error;
    }
    notifyListeners();
  }
}
