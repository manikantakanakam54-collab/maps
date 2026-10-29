import 'package:latlong2/latlong.dart';
import '../models/navigation_step.dart';
import 'routing_service.dart';

class _GraphNode {
  final String id;
  final String name;
  final LatLng point;

  const _GraphNode({
    required this.id,
    required this.name,
    required this.point,
  });
}

class CampusRouteEngine {
  static const Distance _distCalc = Distance();

  // Primary Campus Nodes (All key facilities + pedestrian junctions)
  static final Map<String, _GraphNode> _nodes = {
    // Academic Blocks North Row (Academic Corridor)
    'blk-25': const _GraphNode(id: 'blk-25', name: 'Block 25', point: LatLng(31.252777, 75.702468)),
    'blk-26': const _GraphNode(id: 'blk-26', name: 'Block 26', point: LatLng(31.252672, 75.702740)),
    'blk-27': const _GraphNode(id: 'blk-27', name: 'Block 27', point: LatLng(31.252718, 75.703291)),
    'blk-28': const _GraphNode(id: 'blk-28', name: 'Block 28', point: LatLng(31.252778, 75.703804)),
    'blk-29': const _GraphNode(id: 'blk-29', name: 'Block 29', point: LatLng(31.252786, 75.704186)),
    'blk-30': const _GraphNode(id: 'blk-30', name: 'Block 30 - Infotech', point: LatLng(31.252645, 75.704660)),
    'admission': const _GraphNode(id: 'admission', name: 'Admission Block', point: LatLng(31.252720, 75.704746)),
    'lpu-main-parking': const _GraphNode(id: 'lpu-main-parking', name: 'LPU Main Parking', point: LatLng(31.252855, 75.705590)),

    // Academic Blocks Central Hub
    'blk-34': const _GraphNode(id: 'blk-34', name: 'Block 34', point: LatLng(31.2533614, 75.7035391)),

    // Academic South Row
    'library': const _GraphNode(id: 'library', name: 'Central Library', point: LatLng(31.252063, 75.703373)),
    'sd-auditorium': const _GraphNode(id: 'sd-auditorium', name: 'Shanti Devi Mittal Auditorium', point: LatLng(31.252061, 75.704131)),
    'blk-32': const _GraphNode(id: 'blk-32', name: 'Block 32', point: LatLng(31.252040, 75.704783)),
    'blk-36': const _GraphNode(id: 'blk-36', name: 'Block 36', point: LatLng(31.252013, 75.704969)),
    'pnb-bank': const _GraphNode(id: 'pnb-bank', name: 'Punjab National Bank & ATM', point: LatLng(31.252013, 75.704969)),

    // North Hub & Commercial Zone
    'blk-14': const _GraphNode(id: 'blk-14', name: 'Block 14', point: LatLng(31.254399, 75.705596)),
    'msb': const _GraphNode(id: 'msb', name: 'Mittal School of Business', point: LatLng(31.254518, 75.705422)),
    'unipolis': const _GraphNode(id: 'unipolis', name: 'Uni Polis', point: LatLng(31.255083, 75.704869)),
    'uni-mall': const _GraphNode(id: 'uni-mall', name: 'Uni Mall', point: LatLng(31.255823, 75.705445)),
    'hotel-mgmt': const _GraphNode(id: 'hotel-mgmt', name: 'LPU Hotel Management', point: LatLng(31.255645, 75.704313)),
    'blk-15': const _GraphNode(id: 'blk-15', name: 'Block 15', point: LatLng(31.255585, 75.704159)),
    'blk-18': const _GraphNode(id: 'blk-18', name: 'Block 18', point: LatLng(31.255279, 75.703743)),
    'phys-ed': const _GraphNode(id: 'phys-ed', name: 'Physical Education', point: LatLng(31.255228, 75.703387)),
    'mgmt': const _GraphNode(id: 'mgmt', name: 'Management Block', point: LatLng(31.254689, 75.701273)),

    // North Entrance & Hospital
    'uni-hospital': const _GraphNode(id: 'uni-hospital', name: 'Uni Health Care', point: LatLng(31.258182, 75.706727)),
    'main-gate-parking': const _GraphNode(id: 'main-gate-parking', name: 'Main Gate Parking', point: LatLng(31.259875, 75.706047)),

    // West Residential & Hostels
    'bh-1': const _GraphNode(id: 'bh-1', name: 'Boys Hostel 1', point: LatLng(31.251405, 75.700350)),
    'bh-2-3': const _GraphNode(id: 'bh-2-3', name: 'Boys Hostel 2 & 3', point: LatLng(31.249615, 75.701060)),
    'bh-4': const _GraphNode(id: 'bh-4', name: 'Boys Hostel 4', point: LatLng(31.248597, 75.699875)),
    'food-factory': const _GraphNode(id: 'food-factory', name: 'Food Factory', point: LatLng(31.247972, 75.698611)),

    // South Campus (Polytechnic & Aerospace)
    'blk-55': const _GraphNode(id: 'blk-55', name: 'Block 55', point: LatLng(31.247047, 75.703522)),
    'blk-56': const _GraphNode(id: 'blk-56', name: 'Block 56', point: LatLng(31.246546, 75.703589)),
    'blk-57': const _GraphNode(id: 'blk-57', name: 'Block 57', point: LatLng(31.246231, 75.703723)),
    'polytechnic': const _GraphNode(id: 'polytechnic', name: 'School of Polytechnic', point: LatLng(31.246294, 75.704078)),
    'aerospace': const _GraphNode(id: 'aerospace', name: 'School of Aerospace', point: LatLng(31.246918, 75.703311)),

    // Key Pedestrian Corridors / Junctions
    'j-acad-cross': const _GraphNode(id: 'j-acad-cross', name: 'Academic Central Plaza', point: LatLng(31.252750, 75.703550)),
    'j-south-conn': const _GraphNode(id: 'j-south-conn', name: 'South Campus Avenue', point: LatLng(31.249500, 75.703500)),
    'j-north-ave': const _GraphNode(id: 'j-north-ave', name: 'North Boulevard', point: LatLng(31.257000, 75.706100)),
  };

  // Connected Walkway Edges
  static final List<List<String>> _edges = [
    // Academic Corridor Main East-West Walkway
    ['blk-25', 'blk-26'],
    ['blk-26', 'blk-27'],
    ['blk-27', 'j-acad-cross'],
    ['j-acad-cross', 'blk-28'],
    ['blk-27', 'blk-28'], // Direct inter-block pedestrian link
    ['blk-28', 'blk-29'],
    ['blk-29', 'blk-30'],
    ['blk-30', 'admission'],
    ['admission', 'lpu-main-parking'],

    // Academic South Row Walkway
    ['library', 'sd-auditorium'],
    ['sd-auditorium', 'blk-32'],
    ['blk-32', 'blk-36'],
    ['blk-36', 'pnb-bank'],

    // Cross-Walkways Connecting North and South Rows
    ['blk-27', 'library'],
    ['j-acad-cross', 'library'],
    ['j-acad-cross', 'sd-auditorium'],
    ['blk-28', 'sd-auditorium'],
    ['blk-29', 'sd-auditorium'],
    ['blk-30', 'blk-32'],
    ['admission', 'blk-36'],

    // Central Academic Hub (Block 34) Connections
    ['blk-34', 'j-acad-cross'],
    ['blk-34', 'blk-27'],
    ['blk-34', 'blk-28'],
    ['blk-34', 'library'],

    // North-Central Spine to MSB, Block 14, UniPolis, UniMall
    ['blk-34', 'msb'],
    ['msb', 'blk-14'],
    ['blk-14', 'unipolis'],
    ['blk-14', 'uni-mall'],
    ['unipolis', 'uni-mall'],
    ['msb', 'unipolis'],

    // North Academic Sector (Blocks 15, 18, Hotel Mgmt, Physical Ed)
    ['blk-34', 'blk-18'],
    ['blk-18', 'phys-ed'],
    ['blk-18', 'blk-15'],
    ['blk-15', 'hotel-mgmt'],
    ['hotel-mgmt', 'unipolis'],
    ['hotel-mgmt', 'uni-mall'],

    // North Avenue to Hospital and Main Gate
    ['uni-mall', 'j-north-ave'],
    ['j-north-ave', 'uni-hospital'],
    ['uni-hospital', 'main-gate-parking'],

    // West Avenue to Management Block and Hostels
    ['blk-25', 'mgmt'],
    ['blk-25', 'bh-1'],
    ['bh-1', 'bh-2-3'],
    ['bh-2-3', 'bh-4'],
    ['bh-4', 'food-factory'],

    // South Campus Corridor (Polytechnic & Aerospace)
    ['library', 'j-south-conn'],
    ['blk-32', 'j-south-conn'],
    ['j-south-conn', 'blk-55'],
    ['blk-55', 'blk-56'],
    ['blk-56', 'blk-57'],
    ['blk-57', 'polytechnic'],
    ['blk-55', 'aerospace'],
    ['aerospace', 'blk-56'],
  ];

  static Map<String, List<MapEntry<String, double>>>? _cachedAdj;

  static Map<String, List<MapEntry<String, double>>> _getAdjacency() {
    if (_cachedAdj != null) return _cachedAdj!;

    final map = <String, List<MapEntry<String, double>>>{};
    for (final id in _nodes.keys) {
      map[id] = [];
    }

    for (final edge in _edges) {
      final u = edge[0];
      final v = edge[1];
      if (_nodes.containsKey(u) && _nodes.containsKey(v)) {
        final d = _distCalc.as(LengthUnit.Meter, _nodes[u]!.point, _nodes[v]!.point);
        map[u]!.add(MapEntry(v, d));
        map[v]!.add(MapEntry(u, d));
      }
    }

    _cachedAdj = map;
    return map;
  }

  /// Finds the closest node in the campus graph to any arbitrary point.
  static String _findClosestNode(LatLng point) {
    String closest = _nodes.keys.first;
    double minD = double.infinity;

    for (final entry in _nodes.entries) {
      final d = _distCalc.as(LengthUnit.Meter, point, entry.value.point);
      if (d < minD) {
        minD = d;
        closest = entry.key;
      }
    }
    return closest;
  }

  /// Calculates the shortest walkable route across the campus network.
  static RouteResult calculateRoute(LatLng start, LatLng dest, {String? startName, String? destName}) {
    final directDistance = _distCalc.as(LengthUnit.Meter, start, dest);

    // 1. Direct Walk Check:
    // If the distance is under 65 meters (adjacent blocks or close proximity),
    // a pedestrian walks directly along the connected corridor/plaza.
    if (directDistance <= 65) {
      final duration = directDistance / 1.3; // ~1.3 m/s walking speed
      return RouteResult(
        points: [start, dest],
        steps: [
          NavigationStep(
            instruction: destName != null
                ? 'Walk along the campus corridor to $destName'
                : 'Walk along the campus corridor to destination',
            location: start,
            type: 'depart',
            distance: directDistance,
            duration: duration,
          ),
          NavigationStep(
            instruction: destName != null
                ? 'You have arrived at $destName'
                : 'You have arrived at your destination',
            location: dest,
            type: 'arrive',
            distance: 0,
            duration: 0,
          ),
        ],
        distance: directDistance,
        duration: duration,
      );
    }

    // 2. Campus Network Dijkstra:
    final startNodeId = _findClosestNode(start);
    final destNodeId = _findClosestNode(dest);

    // If both snap to the same node (very close together)
    if (startNodeId == destNodeId) {
      final node = _nodes[startNodeId]!;
      final points = [start, node.point, dest];
      final totalD = _distCalc.as(LengthUnit.Meter, start, node.point) +
          _distCalc.as(LengthUnit.Meter, node.point, dest);
      final duration = totalD / 1.3;

      return RouteResult(
        points: points,
        steps: [
          NavigationStep(
            instruction: 'Walk towards ${node.name}',
            location: start,
            type: 'depart',
            distance: totalD,
            duration: duration,
          ),
          NavigationStep(
            instruction: destName != null
                ? 'You have arrived at $destName'
                : 'You have arrived at your destination',
            location: dest,
            type: 'arrive',
            distance: 0,
            duration: 0,
          ),
        ],
        distance: totalD,
        duration: duration,
      );
    }

    // Run Dijkstra
    final adj = _getAdjacency();
    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    for (final node in _nodes.keys) {
      distances[node] = double.infinity;
      previous[node] = null;
      unvisited.add(node);
    }

    distances[startNodeId] = 0;

    while (unvisited.isNotEmpty) {
      String? current;
      double shortest = double.infinity;

      for (final node in unvisited) {
        if (distances[node]! < shortest) {
          shortest = distances[node]!;
          current = node;
        }
      }

      if (current == null || current == destNodeId || shortest == double.infinity) {
        break;
      }

      unvisited.remove(current);

      for (final neighbor in adj[current] ?? []) {
        if (!unvisited.contains(neighbor.key)) continue;
        final alt = distances[current]! + neighbor.value;
        if (alt < distances[neighbor.key]!) {
          distances[neighbor.key] = alt;
          previous[neighbor.key] = current;
        }
      }
    }

    // Reconstruct path
    final pathNodeIds = <String>[];
    String? curr = destNodeId;
    while (curr != null) {
      pathNodeIds.insert(0, curr);
      curr = previous[curr];
    }

    if (pathNodeIds.isEmpty || pathNodeIds.first != startNodeId) {
      // Fallback: direct line if graph path unreachable
      final duration = directDistance / 1.3;
      return RouteResult(
        points: [start, dest],
        steps: [
          NavigationStep(
            instruction: 'Walk towards destination',
            location: start,
            type: 'depart',
            distance: directDistance,
            duration: duration,
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
        duration: duration,
      );
    }

    // Build route points and steps
    final points = <LatLng>[start];
    double totalDistance = 0.0;

    // From start to first node
    final firstNode = _nodes[pathNodeIds.first]!;
    final dToFirst = _distCalc.as(LengthUnit.Meter, start, firstNode.point);
    if (dToFirst > 5) {
      points.add(firstNode.point);
      totalDistance += dToFirst;
    }

    // Along graph path
    for (int i = 0; i < pathNodeIds.length - 1; i++) {
      final u = _nodes[pathNodeIds[i]]!;
      final v = _nodes[pathNodeIds[i + 1]]!;
      final segD = _distCalc.as(LengthUnit.Meter, u.point, v.point);
      totalDistance += segD;
      points.add(v.point);
    }

    // From last node to dest
    final lastNode = _nodes[pathNodeIds.last]!;
    final dFromLast = _distCalc.as(LengthUnit.Meter, lastNode.point, dest);
    if (dFromLast > 5) {
      points.add(dest);
      totalDistance += dFromLast;
    }

    // Generate clear, natural walking navigation steps
    final steps = <NavigationStep>[];
    final totalDuration = totalDistance / 1.3;

    steps.add(
      NavigationStep(
        instruction: 'Start walking along campus path towards ${firstNode.name}',
        location: start,
        type: 'depart',
        distance: dToFirst,
        duration: dToFirst / 1.3,
      ),
    );

    for (int i = 0; i < pathNodeIds.length - 1; i++) {
      final nextNode = _nodes[pathNodeIds[i + 1]]!;
      final currNode = _nodes[pathNodeIds[i]]!;
      final segD = _distCalc.as(LengthUnit.Meter, currNode.point, nextNode.point);

      steps.add(
        NavigationStep(
          instruction: 'Continue straight past ${currNode.name} towards ${nextNode.name}',
          location: currNode.point,
          type: 'continue',
          distance: segD,
          duration: segD / 1.3,
        ),
      );
    }

    steps.add(
      NavigationStep(
        instruction: destName != null
            ? 'Arrive at $destName'
            : 'You have arrived at your destination',
        location: dest,
        type: 'arrive',
        distance: 0,
        duration: 0,
      ),
    );

    return RouteResult(
      points: points,
      steps: steps,
      distance: totalDistance,
      duration: totalDuration,
    );
  }
}
