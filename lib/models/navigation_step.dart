import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class NavigationStep {
  final String instruction;
  final LatLng location;
  final String type;
  final String modifier;
  final double distance;
  final double duration;
  bool announced;

  NavigationStep({
    required this.instruction,
    required this.location,
    required this.type,
    this.modifier = '',
    this.distance = 0.0,
    this.duration = 0.0,
    this.announced = false,
  });

  IconData get icon {
    switch (type) {
      case 'arrive':
        return Icons.flag_rounded;
      case 'depart':
        return Icons.navigation_rounded;
      case 'turn':
      case 'fork':
      case 'end of road':
        if (modifier.contains('left')) {
          if (modifier.contains('sharp') || modifier.contains('slight')) {
            return Icons.turn_sharp_left_rounded;
          }
          return Icons.turn_left_rounded;
        } else if (modifier.contains('right')) {
          if (modifier.contains('sharp') || modifier.contains('slight')) {
            return Icons.turn_sharp_right_rounded;
          }
          return Icons.turn_right_rounded;
        } else if (modifier.contains('straight')) {
          return Icons.straight_rounded;
        }
        return Icons.turn_right_rounded;
      case 'roundabout':
      case 'rotary':
        return Icons.roundabout_right_rounded;
      default:
        if (modifier.contains('left')) return Icons.turn_left_rounded;
        if (modifier.contains('right')) return Icons.turn_right_rounded;
        return Icons.straight_rounded;
    }
  }
}
