import 'dart:math';
import 'package:flutter/material.dart';

class QuickAimOverlay extends StatelessWidget {
  final double? targetBearingDeg; // 0..360, nullable
  final double? headingDeg;       // device heading 0..360, nullable

  const QuickAimOverlay({super.key, this.targetBearingDeg, this.headingDeg});

  @override
  Widget build(BuildContext context) {
    final delta = _deltaDeg(targetBearingDeg, headingDeg); // 0..360 or null
    final turn = delta == null ? null : (delta <= 180 ? delta : -(360 - delta));

    String text;
    if (targetBearingDeg == null || headingDeg == null) {
      text = "Point to target";
    } else if (turn!.abs() < 3) {
      text = "AIMED • FIRE";
    } else if (turn > 0) {
      text = "TURN ${turn.toStringAsFixed(0)}° RIGHT";
    } else {
      text = "TURN ${turn.abs().toStringAsFixed(0)}° LEFT";
    }

    final arrowAngle = _radians((turn ?? 0));

    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: arrowAngle,
                  child: const Icon(Icons.navigation, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double? _deltaDeg(double? t, double? h) {
    if (t == null || h == null) return null;
    final d = (t - h + 360) % 360;
    return d;
  }

  static double _radians(double deg) => deg * pi / 180.0;
}
