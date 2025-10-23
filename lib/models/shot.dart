class Shot {
  final int? id;
  final DateTime timestamp;
  final double lat;
  final double lon;
  final double distance; // meters
  final String club; // REQUIRED – no fallback
  final String? notes;

  Shot({
    this.id,
    required this.timestamp,
    required this.lat,
    required this.lon,
    required this.distance,
    required this.club,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'lat': lat,
        'lon': lon,
        'distance': distance,
        'club': club,
        'notes': notes,
      };

  factory Shot.fromMap(Map<String, dynamic> m) => Shot(
        id: m['id'] as int?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
        distance: (m['distance'] as num).toDouble(),
        club: m['club'] as String,
        notes: m['notes'] as String?,
      );
}
