import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'; // debugPrint + kIsWeb
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/shot.dart';

class DbService {
  static const _dbName   = 'golfball.db';
  static const _table    = 'shots';
  static const _prefsKey = 'shots_web_cache';

  Database? _db;
  SharedPreferences? _prefs;

  // Cache the latest emission so late subscribers (e.g., History screen)
  // immediately receive the most recent list without waiting for a new write.
  List<Shot> _latestShots = const <Shot>[];
  final _shotsCtrl = StreamController<List<Shot>>.broadcast();
  Stream<List<Shot>> get shotsStream async* {
    // Immediately replay the latest cached value to new subscribers.
    yield _latestShots;
    yield* _shotsCtrl.stream;
  }

  Future<void> init() async {
    debugPrint('[DbService] init() kIsWeb=$kIsWeb');

    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
      await _emitAllSafe();
      return;
    }

    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        debugPrint('[DbService] creating table $_table');
        await db.execute('''
          CREATE TABLE $_table(
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT    NOT NULL,
            lat       REAL    NOT NULL,
            lon       REAL    NOT NULL,
            distance  REAL    NOT NULL,
            club      TEXT    NOT NULL,
            notes     TEXT
          );
        ''');
      },
    );

    await _emitAllSafe();
  }

  Future<void> dispose() async {
    await _shotsCtrl.close();
    await _db?.close();
  }

  /// Save a shot and emit the updated list.
  Future<int> saveShot(Shot s) async {
    debugPrint('[DbService] saveShot: ${s.club} ${s.distance} yd');
    if (s.club.isEmpty) {
      throw ArgumentError('Shot.club must be provided');
    }

    if (kIsWeb) {
      final list   = await getShots();
      // Find the highest ID and increment it
      final maxId = list.isEmpty ? 0 : list.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b);
      final nextId = maxId + 1;
      final withId = Shot(
        id: nextId,
        timestamp: s.timestamp,
        lat: s.lat,
        lon: s.lon,
        distance: s.distance,
        club: s.club,
        notes: s.notes,
      );
      final newList = [withId, ...list];
      final jsonStr = jsonEncode(newList.map((s) => s.toMap()).toList());

      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_prefsKey, jsonStr);

      await _emitAllSafe();
      return nextId;
    }

    final id = await _db!.insert(_table, _shotToMap(s));
    debugPrint('[DbService] inserted row id=$id');
    await _emitAllSafe();
    return id;
  }

  Future<List<Shot>> getShots() async {
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
      final jsonStr = _prefs!.getString(_prefsKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final raw  = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
      final list = raw.map((m) => Shot.fromMap(m)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }

    final rows = await _db!.query(_table, orderBy: 'datetime(timestamp) DESC');
    return rows.map(_shotFromMap).toList();
  }

  Future<void> deleteShot(int id) async {
    if (kIsWeb) {
      final list = await getShots();
      final filtered = list.where((s) => s.id != id).toList();
      final jsonStr  = jsonEncode(filtered.map(_shotToMap).toList());

      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_prefsKey, jsonStr);
      await _emitAllSafe();
      return;
    }

    await _db!.delete(_table, where: 'id = ?', whereArgs: [id]);
    await _emitAllSafe();
  }

  Future<void> _emitAllSafe() async {
    try {
      final all = await getShots();
      debugPrint('[DbService] emitting ${all.length} shots');
      debugPrint('[DbService] shots: ${all.map((s) => '${s.club} ${s.distance}yd').join(', ')}');
      _latestShots = all;
      if (!_shotsCtrl.isClosed) {
        _shotsCtrl.add(all);
        debugPrint('[DbService] stream updated with ${all.length} shots');
      } else {
        debugPrint('[DbService] stream controller is closed!');
      }
    } catch (e) {
      debugPrint('[DbService] emit error: $e');
      if (!_shotsCtrl.isClosed) _shotsCtrl.add(const []);
    }
  }

  Map<String, dynamic> _shotToMap(Shot s) => {
        'id': s.id,
        'timestamp': s.timestamp.toIso8601String(),
        'lat': s.lat,
        'lon': s.lon,
        'distance': s.distance,
        'club': s.club,
        'notes': s.notes,
      };

  Shot _shotFromMap(Map<String, dynamic> m) => Shot(
        id: m['id'] as int?,
        timestamp: DateTime.parse(m['timestamp'] as String),
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
        distance: (m['distance'] as num).toDouble(),
        club: m['club'] as String,
        notes: m['notes'] as String?,
      );
}
