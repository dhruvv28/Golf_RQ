import 'dart:collection';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class VoiceCoach extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final Queue<String> _queue = Queue();
  bool _busy = false;
  bool _enabled = true;
  double _speechRate = 0.6; // Slightly faster for better accessibility
  double _pitch = 1.0;

  bool get isEnabled => _enabled;
  bool get isSpeaking => _busy;

  Future<void> init() async {
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage("en-US");
    await _tts.setVolume(1.0);
    
    // Set up completion handler
    _tts.setCompletionHandler(() {
      _busy = false;
      _processQueue();
    });
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      await stop();
    }
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.1, 2.0);
    await _tts.setSpeechRate(_speechRate);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
    notifyListeners();
  }

  Future<void> say(String msg) async {
    if (!_enabled || msg.trim().isEmpty) return;
    
    _queue.add(msg);
    if (_busy) return;
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty || _busy) return;
    
    _busy = true;
    final next = _queue.removeFirst();
    await _tts.speak(next);
  }

  Future<void> stop() async {
    await _tts.stop();
    _queue.clear();
    _busy = false;
  }

  // Accessibility-specific methods
  Future<void> announceScreen(String screenName) async {
    await say("Now on $screenName screen");
  }

  Future<void> announceNavigation(String destination) async {
    await say("Navigating to $destination");
  }

  Future<void> announceAction(String action) async {
    await say("$action completed");
  }

  Future<void> announceError(String error) async {
    await say("Error: $error");
  }

  Future<void> announceSuccess(String message) async {
    await say("Success: $message");
  }

  Future<void> announceData(String data) async {
    await say(data);
  }

  // Golf-specific announcements
  Future<void> announceShot(String club, double distance) async {
    await say("Shot recorded: $club, ${distance.round()} yards");
  }

  Future<void> announceRecommendation(String club, double targetDistance) async {
    await say("Recommended club: $club for ${targetDistance.round()} yards");
  }

  Future<void> announceDistance(double distance) async {
    await say("Distance to hole: ${distance.round()} yards");
  }

  Future<void> announceSession(String action) async {
    await say("Practice session $action");
  }

  Future<void> announceGoal(String goalTitle, double progress) async {
    final percentage = (progress * 100).round();
    await say("Goal: $goalTitle, ${percentage}% complete");
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

