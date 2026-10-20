import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../models/navigation_step.dart';

class RouteResult {
  final List<LatLng> points;
  final List<NavigationStep> steps;
  final double distance; // in meters
  final double duration; // in seconds
  final bool isOfflineFallback;

  const RouteResult({
    required this.points,
    required this.steps,
    required this.distance,
    required this.duration,
    this.isOfflineFallback = false,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 1) {
      return '< 1 min walk';
    } else if (minutes < 60) {
      return '$minutes min walk';
    } else {
      final hours = minutes ~/ 60;
      final remMins = minutes % 60;
      return '$hours hr $remMins min';
    }
  }
}

class RoutingService {
  Future<RouteResult?> calculateWalkingRoute(LatLng start, LatLng dest) async {
    final url = Uri.parse(AppConstants.getOsrmWalkingRouteUrl(start, dest));

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          // Coordinates
          final rawCoords = (route['geometry']['coordinates'] as List);
          final List<LatLng> points = [
            start,
            ...rawCoords.map<LatLng>((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())),
            dest,
          ];

          // Steps
          final steps = <NavigationStep>[];
          if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
            final leg = route['legs'][0];
            final rawSteps = (leg['steps'] as List? ?? []);

            for (final s in rawSteps) {
              final maneuver = s['maneuver'] ?? {};
              final type = maneuver['type']?.toString() ?? 'turn';
              final modifier = maneuver['modifier']?.toString() ?? '';
              final name = s['name']?.toString() ?? '';
              final distance = (s['distance'] as num?)?.toDouble() ?? 0.0;
              final duration = (s['duration'] as num?)?.toDouble() ?? 0.0;

              final locList = maneuver['location'] as List?;
              LatLng loc = start;
              if (locList != null && locList.length >= 2) {
                loc = LatLng((locList[1] as num).toDouble(), (locList[0] as num).toDouble());
              }

              String instruction;
              if (type == 'arrive') {
                instruction = 'You have arrived at your destination';
              } else if (type == 'depart') {
                instruction = 'Start walking along campus path';
              } else {
                final action = modifier.isNotEmpty ? '$type $modifier' : type;
                final cleanAction = action
                    .replaceAll('sharp ', '')
                    .replaceAll('slight ', '')
                    .trim();
                instruction = name.isNotEmpty
                    ? '$cleanAction onto $name'
                    : cleanAction;
                // Capitalize first letter
                if (instruction.isNotEmpty) {
                  instruction = instruction[0].toUpperCase() + instruction.substring(1);
                }
              }

              steps.add(
                NavigationStep(
                  instruction: instruction,
                  location: loc,
                  type: type,
                  modifier: modifier,
                  distance: distance,
                  duration: duration,
                ),
              );
            }
          }

          final totalDist = (route['distance'] as num).toDouble();
          final totalDur = (route['duration'] as num).toDouble();

          return RouteResult(
            points: points,
            steps: steps,
            distance: totalDist,
            duration: totalDur,
          );
        }
      }
    } catch (_) {}

    // Fallback: Direct walking line if OSRM is offline or timed out
    const distanceCalculator = Distance();
    final directDistance = distanceCalculator.as(LengthUnit.Meter, start, dest);
    // Average walking speed ~1.3 m/s (~4.7 km/h)
    final directDuration = directDistance / 1.3;

    return RouteResult(
      points: [start, dest],
      steps: [
        NavigationStep(
          instruction: 'Head directly towards destination',
          location: start,
          type: 'depart',
          distance: directDistance,
          duration: directDuration,
        ),
        NavigationStep(
          instruction: 'You have arrived at your destination',
          location: dest,
          type: 'arrive',
          distance: 0,
          duration: 0,
        ),
      ],
      distance: directDistance,
      duration: directDuration,
      isOfflineFallback: true,
    );
  }
}
