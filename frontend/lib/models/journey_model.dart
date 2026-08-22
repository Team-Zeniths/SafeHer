/// Represents a journey tracking session.
///
/// TODO: Sync field names with backend `/journeys` endpoint.
class JourneyModel {
  const JourneyModel({
    required this.id,
    required this.startAddress,
    required this.startTime,
    this.destinationAddress,
    this.endTime,
    this.status = JourneyStatus.active,
    this.distanceKm,
    this.durationMinutes,
    this.checkInCount = 0,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
  });

  final String id;
  final String startAddress;
  final DateTime startTime;
  final String? destinationAddress;
  final DateTime? endTime;
  final JourneyStatus status;
  final double? distanceKm;
  final int? durationMinutes;
  final int checkInCount;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;

  bool get isActive => status == JourneyStatus.active;
  bool get isCompleted => status == JourneyStatus.completed;

  /// Parses a JourneySummary row as returned by the real backend
  /// (GET/POST /api/v1/journey/summaries/) — snake_case field names,
  /// distinct from the camelCase [fromJson] used for local persistence.
  /// start_point/end_point are stored as "lat,lng" strings (no geocoding
  /// yet), so this also parses them back out for the map-verify dialog.
  factory JourneyModel.fromApiJson(Map<String, dynamic> json) {
    double? parseCoord(String? point, int index) {
      if (point == null) return null;
      final parts = point.split(',');
      if (parts.length != 2) return null;
      return double.tryParse(parts[index].trim());
    }

    final startPoint = json['start_point'] as String?;
    final endPoint = json['end_point'] as String?;

    return JourneyModel(
      id: json['id'].toString(),
      startAddress: startPoint ?? 'Unknown location',
      startTime: DateTime.parse(json['started_at'] as String).toLocal(),
      destinationAddress: endPoint,
      endTime: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String).toLocal() : null,
      status: JourneyStatus.completed,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      startLat: parseCoord(startPoint, 0),
      startLng: parseCoord(startPoint, 1),
      endLat: parseCoord(endPoint, 0),
      endLng: parseCoord(endPoint, 1),
    );
  }

  factory JourneyModel.fromJson(Map<String, dynamic> json) {
    return JourneyModel(
      id: json['id']?.toString() ?? '',
      startAddress: json['startAddress'] as String? ?? 'Unknown location',
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      destinationAddress: json['destinationAddress'] as String?,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'] as String) : null,
      status: JourneyStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => JourneyStatus.active,
      ),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      durationMinutes: json['durationMinutes'] as int?,
      checkInCount: json['checkInCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startAddress': startAddress,
        'startTime': startTime.toIso8601String(),
        'destinationAddress': destinationAddress,
        'endTime': endTime?.toIso8601String(),
        'status': status.name,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'checkInCount': checkInCount,
      };

  JourneyModel copyWith({
    String? id,
    String? startAddress,
    DateTime? startTime,
    String? destinationAddress,
    DateTime? endTime,
    JourneyStatus? status,
    double? distanceKm,
    int? durationMinutes,
    int? checkInCount,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
  }) {
    return JourneyModel(
      id: id ?? this.id,
      startAddress: startAddress ?? this.startAddress,
      startTime: startTime ?? this.startTime,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      checkInCount: checkInCount ?? this.checkInCount,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
    );
  }
}

enum JourneyStatus { active, completed, cancelled }
