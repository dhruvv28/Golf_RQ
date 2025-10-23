
// lib/widgets/direction_indicator.dart
import 'dart:math';
import 'package:flutter/material.dart';

class DirectionIndicator extends StatelessWidget {
  final double? targetBearing;   // degrees
  final double? currentHeading;  // degrees
  final double? distance;        // yards

  const DirectionIndicator({
    super.key,
    required this.targetBearing,
    required this.currentHeading,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    if (targetBearing == null || currentHeading == null) {
      return const Text('Waiting for direction data...', style: TextStyle(fontSize: 16));
    }

    final diff = ((targetBearing! - currentHeading!) + 360) % 360;
    // rotate arrow so it points toward target relative to phone heading
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: diff * pi / 180,
          child: const Icon(Icons.navigation, size: 96, color: Colors.green),
        ),
        const SizedBox(height: 12),
        Text(
          'Distance: ${distance?.toStringAsFixed(0) ?? "--"} yards',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'Bearing: ${targetBearing!.toStringAsFixed(1)}°',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}

