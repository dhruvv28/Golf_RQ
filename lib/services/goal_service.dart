import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/goal.dart';
import '../models/shot.dart';

class GoalService extends ChangeNotifier {
  static const _prefsKey = 'goals';
  
  List<Goal> _goals = [];
  
  List<Goal> get goals => _goals;
  List<Goal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<Goal> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  List<Goal> get overdueGoals => _goals.where((g) => g.isOverdue).toList();

  Future<void> init() async {
    await _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final raw = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
        _goals = raw.map((m) => Goal.fromMap(m)).toList();
      }
    } catch (e) {
      debugPrint('[GoalService] Error loading goals: $e');
    }
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_goals.map((g) => g.toMap()).toList());
      await prefs.setString(_prefsKey, jsonStr);
    } catch (e) {
      debugPrint('[GoalService] Error saving goals: $e');
    }
  }

  Future<Goal> createGoal({
    required String title,
    required String description,
    required GoalType type,
    required double targetValue,
    required DateTime targetDate,
    String? club,
  }) async {
    final goal = Goal(
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      currentValue: 0,
      targetDate: targetDate,
      createdAt: DateTime.now(),
      club: club,
    );

    _goals.insert(0, goal);
    await _saveGoals();
    notifyListeners();
    
    debugPrint('[GoalService] Created goal: $title');
    return goal;
  }

  Future<void> updateGoalProgress(int goalId, double newValue) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final goal = _goals[index];
    final updatedGoal = Goal(
      id: goal.id,
      title: goal.title,
      description: goal.description,
      type: goal.type,
      targetValue: goal.targetValue,
      currentValue: newValue,
      targetDate: goal.targetDate,
      createdAt: goal.createdAt,
      isCompleted: newValue >= goal.targetValue,
      club: goal.club,
    );

    _goals[index] = updatedGoal;
    await _saveGoals();
    notifyListeners();
  }

  Future<void> completeGoal(int goalId) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index == -1) return;

    final goal = _goals[index];
    final updatedGoal = Goal(
      id: goal.id,
      title: goal.title,
      description: goal.description,
      type: goal.type,
      targetValue: goal.targetValue,
      currentValue: goal.targetValue,
      targetDate: goal.targetDate,
      createdAt: goal.createdAt,
      isCompleted: true,
      club: goal.club,
    );

    _goals[index] = updatedGoal;
    await _saveGoals();
    notifyListeners();
  }

  Future<void> deleteGoal(int goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    await _saveGoals();
    notifyListeners();
  }

  Future<void> updateGoalsFromShots(List<Shot> shots) async {
    // Update goals based on current shot data
    for (final goal in _goals.where((g) => !g.isCompleted)) {
      double newValue = 0;
      
      switch (goal.type) {
        case GoalType.consistency:
          // Calculate standard deviation for the club or overall
          final relevantShots = goal.club != null 
              ? shots.where((s) => s.club == goal.club).toList()
              : shots;
          if (relevantShots.length >= 3) {
            newValue = _calculateStdDev(relevantShots.map((s) => s.distance).toList());
          }
          break;
          
        case GoalType.distance:
          // Calculate average distance
          final relevantShots = goal.club != null 
              ? shots.where((s) => s.club == goal.club).toList()
              : shots;
          if (relevantShots.isNotEmpty) {
            newValue = relevantShots.map((s) => s.distance).reduce((a, b) => a + b) / relevantShots.length;
          }
          break;
          
        case GoalType.practice:
          // Count practice sessions or shots
          newValue = shots.length.toDouble();
          break;
          
        case GoalType.accuracy:
          // Calculate accuracy percentage (shots within target range)
          final relevantShots = goal.club != null 
              ? shots.where((s) => s.club == goal.club).toList()
              : shots;
          if (relevantShots.isNotEmpty) {
            final avg = relevantShots.map((s) => s.distance).reduce((a, b) => a + b) / relevantShots.length;
            final withinRange = relevantShots.where((s) => 
                (s.distance - avg).abs() <= 15).length;
            newValue = (withinRange / relevantShots.length) * 100;
          }
          break;
          
        case GoalType.improvement:
          // General improvement metric
          newValue = shots.length.toDouble();
          break;
      }
      
      await updateGoalProgress(goal.id!, newValue);
    }
  }

  double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.fold<double>(0, (acc, v) => acc + (v - mean) * (v - mean)) / (values.length - 1);
    return sqrt(variance);
  }

  List<Goal> getGoalsByType(GoalType type) {
    return _goals.where((g) => g.type == type).toList();
  }

  List<Goal> getGoalsByClub(String club) {
    return _goals.where((g) => g.club == club).toList();
  }
}
