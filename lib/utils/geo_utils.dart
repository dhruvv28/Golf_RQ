// lib/utils/geo_utils.dart
import 'dart:math';

double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  final dLon = (lon2 - lon1) * pi / 180.0;
  lat1 = lat1 * pi / 180.0;
  lat2 = lat2 * pi / 180.0;

  final y = sin(dLon) * cos(lat2);
  final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
  final brng = atan2(y, x);
  final brngDeg = (brng * 180 / pi + 360) % 360;
  return brngDeg;
}


double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat/2)*sin(dLat/2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
      sin(dLon/2)*sin(dLon/2);
  final c = 2 * atan2(sqrt(a), sqrt(1-a));
  return R * c;
}

double initialBearingDeg(double lat1, double lon1, double lat2, double lon2) {
  // 0° = North, clockwise
  final phi1 = _deg2rad(lat1);
  final phi2 = _deg2rad(lat2);
  final lam1 = _deg2rad(lon1);
  final lam2 = _deg2rad(lon2);
  final y = sin(lam2 - lam1) * cos(phi2);
  final x = cos(phi1)*sin(phi2) - sin(phi1)*cos(phi2)*cos(lam2 - lam1);
  final brng = atan2(y, x);
  final deg = (_rad2deg(brng) + 360.0) % 360.0;
  return deg;
}

double metersToYards(double m) => m * 1.0936133;

double _deg2rad(double d) => d * pi / 180.0;
double _rad2deg(double r) => r * 180.0 / pi;
