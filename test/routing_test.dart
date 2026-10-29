import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lpu_maps/constants/campus_data.dart';
import 'package:lpu_maps/services/campus_route_engine.dart';
import 'package:lpu_maps/services/routing_service.dart';

void main() {
  group('Campus Shortest Walk Routing Tests', () {
    final routingService = RoutingService();

    test('Block 27 to Block 28 calculates direct short walk (under 55m, not 875m)', () async {
      final b27 = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Block 27');
      final b28 = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Block 28');

      final result = await routingService.calculateWalkingRoute(
        b27.point,
        b28.point,
        startName: b27.name,
        destName: b28.name,
      );

      expect(result, isNotNull);
      // Actual straight-line distance is ~49m. Must NOT be an 800m+ detour!
      expect(result!.distance, lessThan(55.0));
      expect(result.duration, lessThan(60.0)); // Under 1 minute
      expect(result.points.length, greaterThanOrEqualTo(2));
      expect(result.formattedDuration, contains('< 1 min'));
    });

    test('Block 30 to Block 32 calculates short cross-walk (~68m, not 360m)', () async {
      final b30 = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Block 30 - Infotech');
      final b32 = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Block 32');

      final result = await routingService.calculateWalkingRoute(
        b30.point,
        b32.point,
        startName: b30.name,
        destName: b32.name,
      );

      expect(result, isNotNull);
      expect(result!.distance, lessThan(80.0));
    });

    test('Block 25 to Block 30 calculates road-following academic corridor walk (realistic distance)', () async {
      final b25 = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Block 25');
      final b30 = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Block 30 - Infotech');

      final result = await routingService.calculateWalkingRoute(
        b25.point,
        b30.point,
        startName: b25.name,
        destName: b30.name,
      );

      expect(result, isNotNull);
      // Road-following path along North Promenade is ~257m (straight-line is ~215m).
      // It must NOT be an OSRM 750m+ outer detour; 320m cap still keeps it realistic.
      expect(result!.distance, lessThan(320.0));
      expect(result.distance, greaterThan(100.0)); // Must be more than straight line
    });

    test('CampusRouteEngine connects Central Library to Block 34 directly (~148m)', () {
      final library = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Central Library');
      final b34 = CampusData.defaultPlaces.firstWhere((p) => p.name == 'Block 34');

      final result = CampusRouteEngine.calculateRoute(
        library.point,
        b34.point,
        startName: library.name,
        destName: b34.name,
      );

      expect(result.distance, lessThan(160.0));
      expect(result.steps.length, greaterThanOrEqualTo(2));
    });

    test('Arbitrary nearby coordinates (< 65m) always receive direct walkable path', () {
      const p1 = LatLng(31.25275, 75.70330);
      const p2 = LatLng(31.25277, 75.70370);

      final result = CampusRouteEngine.calculateRoute(p1, p2);
      expect(result.distance, lessThan(50.0));
      expect(result.points.length, equals(2));
    });
  });
}
