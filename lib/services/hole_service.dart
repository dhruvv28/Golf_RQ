import 'package:flutter/foundation.dart';

class HoleTarget {
  final double? lat;              // optional
  final double? lon;              // optional
  final double? distanceYards;    // optional

  const HoleTarget({this.lat, this.lon, this.distanceYards});

  bool get hasCoords => lat != null && lon != null;
  bool get hasDistance => distanceYards != null;
}

class HoleService extends ChangeNotifier {
  HoleTarget _target = const HoleTarget();
  HoleTarget get target => _target;

  void setHoleLatLon(double lat, double lon) {
    _target = HoleTarget(lat: lat, lon: lon);
    notifyListeners();
  }

  void setHoleDistanceYards(double yards) {
    _target = HoleTarget(distanceYards: yards);
    notifyListeners();
  }

  void clear() {
    _target = const HoleTarget();
    notifyListeners();
  }
}
