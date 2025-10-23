import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClubService extends ChangeNotifier {
  static const _prefsKey  = 'club_yards_by_club_json';
  static const _setupKey  = 'club_yards_setup_done';

  /// Order matters (helps UI & tiebreaks)
  static const List<String> clubs = [
    '5-iron', '6-iron', '7-iron', '8-iron', '9-iron', 'PW', 'SW', 'LW',
  ];

  /// Baseline yardages
  static const Map<String, int> _defaults = {
    '5-iron': 180,
    '6-iron': 170,
    '7-iron': 160,
    '8-iron': 150,
    '9-iron': 140,
    'PW'    : 120,
    'SW'    : 100,
    'LW'    : 80,
  };

  // ---- State ----
  final Map<String, int> _yards = {..._defaults};
  bool _loaded = false;
  bool _setupDone = false;

  /// Existing getters (kept)
  Map<String, int> get yardsByClub => Map.unmodifiable(_yards);
  bool get isLoaded => _loaded;
  bool get isSetupDone => _setupDone;

  /// New getters for screens
  Map<String, int> get defaultYardages => Map.unmodifiable(_defaults);
  Map<String, int> get currentYardages => Map.unmodifiable(
        _yards.isEmpty ? _defaults : _yards,
      );

  // ---------- Persistence ----------
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_yards));
  }

  /// Your original load(); screens can also call loadYardages()
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _setupDone = prefs.getBool(_setupKey) ?? false;

    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      for (final c in clubs) {
        final v = map[c];
        if (v is num) _yards[c] = v.round();
      }
    } else {
      // first run: default values
      _yards
        ..clear()
        ..addAll(_defaults);
    }
    _loaded = true;
    notifyListeners();
  }

  /// Alias used by some screens
  Future<void> loadYardages() => load();

  /// Save a whole map (used by Setup screen)
  Future<void> saveYardages(Map<String, int> newYards) async {
    // keep only known clubs; coerce to positive ints
    _yards
      ..clear()
      ..addAll({
        for (final c in clubs)
          c: (newYards[c] ?? _defaults[c] ?? 0).clamp(1, 2000),
      });
    await _save();
    notifyListeners();
  }

  // Set a single club value (you already had this; kept)
  Future<void> setYardage(String club, int yards) async {
    if (!_yards.containsKey(club)) return;
    _yards[club] = yards;
    await _save();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _yards
      ..clear()
      ..addAll(_defaults);
    await _save();
    notifyListeners();
  }

  Future<void> setSetupDone(bool v) async {
    _setupDone = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupKey, v);
    notifyListeners();
  }

  // ---------- Recommendation ----------
  /// “Shortest that reaches”; if none reaches, return longest
  String recommendForYards(int targetYards) {
    final entries = _yards.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // low -> high
    for (final e in entries) {
      if (e.value >= targetYards) return e.key;
    }
    final longest = _yards.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return longest.key;
  }

  /// Optional helper: 12/1/2… o’clock from a bearing
  static String clockFromBearing(double bearingDegrees) {
    final n = (bearingDegrees % 360 + 360) % 360;
    final idx = ((n + 15) ~/ 30) % 12;
    const labels = ['12','1','2','3','4','5','6','7','8','9','10','11'];
    return "${labels[idx]} o'clock";
  }
}
