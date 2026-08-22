/// A past SOS event, as recorded by the backend when it was triggered.
/// Mirrors `apps.accounts.models.SosLog` / `HistorySosEventSerializer`.
class SosLogModel {
  const SosLogModel({
    required this.id,
    required this.locationLat,
    required this.locationLng,
    required this.triggeredAt,
    this.resolvedAt,
  });

  final String id;
  final double locationLat;
  final double locationLng;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;

  bool get isResolved => resolvedAt != null;

  factory SosLogModel.fromJson(Map<String, dynamic> json) {
    return SosLogModel(
      id: json['id'].toString(),
      locationLat: (json['location_lat'] as num).toDouble(),
      locationLng: (json['location_lng'] as num).toDouble(),
      triggeredAt: DateTime.parse(json['triggered_at'] as String).toLocal(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String).toLocal()
          : null,
    );
  }
}
