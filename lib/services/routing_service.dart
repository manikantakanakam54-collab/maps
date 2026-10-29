import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/app_constants.dart';
import '../models/navigation_step.dart';
import 'campus_route_engine.dart';

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
    if (duration <= 60) {
      return '< 1 min walk';
    }
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes min walk';
    } else {
      final hours = minutes ~/ 60;
      final remMins = minutes % 60;
      return '$hours hr $remMins min';
    }
  }
}

class RoutingService {
  static const Distance _distCalc = Distance();

  Future<RouteResult?> calculateWalkingRoute(
    LatLng start,
    LatLng dest, {
    String? startName,
    String? destName,
  }) async {
    final directDistance = _distCalc.as(LengthUnit.Meter, start, dest);

    // 1. Immediately compute the dedicated campus walking graph route
    final campusRoute = CampusRouteEngine.calculateRoute(
      start,
      dest,
      startName: startName,
      destName: destName,
    );

    // 2. Short Distance / Proximity Rule:
    // If destination is within 70 meters (e.g. adjacent academic blocks or nearby courtyard),
    // always use the direct campus walkway path. OSRM snaps to distant outer roads and causes
    // absurd 800+ meter loops.
    if (directDistance <= 70) {
      return campusRoute;
    }

    // 3. For longer walks across campus, attempt OSRM with strict detour validation
    try {
      final url = Uri.parse(AppConstants.getOsrmWalkingRouteUrl(start, dest));
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final totalDist = (route['distance'] as num).toDouble();
          final totalDur = (route['duration'] as num).toDouble();

          // DETOUR SANITY CHECK:
          // A realistic walking route in a university campus should never be > 1.45x
          // of the direct distance for medium walks, or > 1.65x for any walk.
          // Furthermore, if OSRM is longer than our campus walkway graph route,
          // OSRM is taking an unnecessary detour around buildings or fences!
          final isOsrmDetour = (directDistance < 300 && totalDist > directDistance * 1.45) ||
              (totalDist > directDistance * 1.65) ||
              (totalDist > campusRoute.distance + 25);

          if (!isOsrmDetour) {
            final rawCoords = (route['geometry']['coordinates'] as List);
            final List<LatLng> points = [
              start,
              ...rawCoords.map<LatLng>(
                (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              ),
              dest,
            ];

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
                  loc = LatLng(
                    (locList[1] as num).toDouble(),
                    (locList[0] as num).toDouble(),
                  );
                }

                String instruction;
                if (type == 'arrive') {
                  instruction = destName != null
                      ? 'You have arrived at $destName'
                      : 'You have arrived at your destination';
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
                  if (instruction.isNotEmpty) {
                    instruction =
                        instruction[0].toUpperCase() + instruction.substring(1);
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

            return RouteResult(
              points: points,
              steps: steps,
              distance: totalDist,
              duration: totalDur,
            );
          }
        }
      }
    } catch (_) {
      // Network timeout or OSRM unavailable -> gracefully use campusRoute
    }

    // Return the verified shortest campus network route
    return campusRoute;
  }
}
