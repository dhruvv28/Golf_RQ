import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/practice_session.dart';

class PracticeSessionService extends ChangeNotifier {
  static const _prefsKey = 'practice_sessions';
  
  List<PracticeSession> _sessions = [];
  PracticeSession? _currentSession;
  
  List<PracticeSession> get sessions => _sessions;
  PracticeSession? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession != null;

  Future<void> init() async {
    await _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final raw = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
        _sessions = raw.map((m) => PracticeSession.fromMap(m)).toList();
        
        // Find active session
        try {
          _currentSession = _sessions.firstWhere((s) => s.isActive);
        } catch (e) {
          _currentSession = null;
        }
      }
    } catch (e) {
      debugPrint('[PracticeSessionService] Error loading sessions: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_sessions.map((s) => s.toMap()).toList());
      await prefs.setString(_prefsKey, jsonStr);
    } catch (e) {
      debugPrint('[PracticeSessionService] Error saving sessions: $e');
    }
  }

  Future<PracticeSession> startSession({
    required String name,
    String? courseName,
    String? weatherConditions,
    String? notes,
  }) async {
    // End any existing session
    if (_currentSession != null) {
      await endSession();
    }

    final session = PracticeSession(
      name: name,
      startTime: DateTime.now(),
      courseName: courseName,
      weatherConditions: weatherConditions,
      notes: notes,
    );

    _sessions.insert(0, session);
    _currentSession = session;
    
    await _saveSessions();
    notifyListeners();
    
    debugPrint('[PracticeSessionService] Started session: $name');
    return session;
  }

  Future<void> endSession({String? notes}) async {
    if (_currentSession == null) return;

    final updatedSession = PracticeSession(
      id: _currentSession!.id,
      name: _currentSession!.name,
      startTime: _currentSession!.startTime,
      endTime: DateTime.now(),
      notes: notes ?? _currentSession!.notes,
      shotIds: _currentSession!.shotIds,
      courseName: _currentSession!.courseName,
      weatherConditions: _currentSession!.weatherConditions,
    );

    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
    }

    _currentSession = null;
    await _saveSessions();
    notifyListeners();
    
    debugPrint('[PracticeSessionService] Ended session: ${updatedSession.name}');
  }

  Future<void> addShotToCurrentSession(int shotId) async {
    if (_currentSession == null) return;

    final updatedSession = PracticeSession(
      id: _currentSession!.id,
      name: _currentSession!.name,
      startTime: _currentSession!.startTime,
      endTime: _currentSession!.endTime,
      notes: _currentSession!.notes,
      shotIds: [..._currentSession!.shotIds, shotId],
      courseName: _currentSession!.courseName,
      weatherConditions: _currentSession!.weatherConditions,
    );

    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      _currentSession = updatedSession;
    }

    await _saveSessions();
    notifyListeners();
  }

  Future<void> deleteSession(int sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSession?.id == sessionId) {
      _currentSession = null;
    }
    await _saveSessions();
    notifyListeners();
  }

  List<PracticeSession> getRecentSessions(int count) {
    return _sessions.take(count).toList();
  }

  PracticeSession? getSessionById(int id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
