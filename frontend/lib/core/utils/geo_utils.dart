import 'dart:math' show asin, cos, pi, sin, sqrt;

/// Great-circle distance between two lat/lng points in kilometers.
/// Mirrors apps.core.utils.haversine_km on the backend exactly, so a
/// journey's distance is the same number whether computed here (for
/// instant UI feedback) or recomputed server-side later.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  double toRad(double deg) => deg * pi / 180;
  final rLat1 = toRad(lat1);
  final rLat2 = toRad(lat2);
  final dLat = toRad(lat2 - lat1);
  final dLng = toRad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(rLat1) * cos(rLat2) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * asin(sqrt(a));
  const earthRadiusKm = 6371;
  return earthRadiusKm * c;
}
