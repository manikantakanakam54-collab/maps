import 'dart:collection';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../models/navigation_step.dart';
import 'routing_service.dart';

// ---------------------------------------------------------------------------
// Internal graph node — a named point on the physical paved road network.
// ---------------------------------------------------------------------------
class _Node {
  final String id;
  final String label; // human-readable turn instruction noun
  final LatLng pt;
  const _Node(this.id, this.label, this.pt);
}

// ---------------------------------------------------------------------------
// CampusRouteEngine
//
// Builds a high-resolution walkable road graph from real OpenStreetMap data
// (60 campus highway/footway ways, extracted to osm_ways.pkl).
//
// Road Geometry:
//   • North Promenade  : lat ≈ 31.25292–31.25294, runs E–W behind Blks 25-30
//   • South Academic Rd: lat ≈ 31.25231–31.25233, runs E–W in front of Blks 25-30
//   • Inter-block alleys connect the two roads at each block bay
//   • Central service road: lat ≈ 31.25299, lon 75.70202 → 75.70586 (way 6)
//   • West spine (unclassified): lat ≈ 31.252 lon 75.702 → up through campus
//
// The graph is constructed once and cached; Dijkstra gives the shortest path
// through the paved network. Polyline points are the actual road coordinates,
// so the direction line always stays on the pavement.
// ---------------------------------------------------------------------------
class CampusRouteEngine {
  static const Distance _dist = Distance();

  // ─── Road-network nodes ─────────────────────────────────────────────────
  static final Map<String, _Node> _nodes = _buildNodes();

  static Map<String, _Node> _buildNodes() {
    final m = <String, _Node>{};
    void n(String id, String label, double lat, double lng) =>
        m[id] = _Node(id, label, LatLng(lat, lng));

    // ── North Entrance & Main Boulevard (GT Road Zone) ──
    n('main-gate-parking', 'Main Gate Parking',   31.259875, 75.706047);
    n('uni-hospital',      'Uni Health Care',     31.258182, 75.706727);
    n('n-boulevard',       'North Boulevard',     31.256800, 75.705800);

    // ── North Hub ──
    n('uni-mall',          'Uni Mall',            31.255823, 75.705445);
    n('unipolis',          'Uni Polis',           31.255083, 75.704869);
    n('hotel-mgmt',        'Hotel Management',   31.255645, 75.704313);
    n('blk-15',            'Block 15',            31.255585, 75.704159);
    n('blk-18',            'Block 18',            31.255279, 75.703743);
    n('phys-ed',           'Physical Education',  31.255228, 75.703387);
    n('msb',               'Mittal School of Business', 31.254518, 75.705422);
    n('blk-14',            'Block 14',            31.254399, 75.705596);
    n('east-rd-msb',       'East Service Road',   31.254399, 75.705280);

    // ── Central North Spine (OSM way 12 / service road lat~31.2535) ──
    n('ns-north', 'North Spine North', 31.255514, 75.702121);
    n('ns-mid',   'North Spine Mid',   31.254377, 75.702128);
    n('ns-south', 'North Spine South', 31.253839, 75.702150);
    n('ns-blk34', 'Block 34 Junction', 31.253092, 75.702169);
    n('ns-end',   'North Spine End',   31.252992, 75.702148);

    // ── Block 34 Central Hub ──
    n('blk-34', 'Block 34', 31.2533614, 75.7035391);

    // ── North Promenade road nodes (OSM way 6, lat≈31.25293, runs E→W) ──
    // These are the exact OSM coordinates: west end to east end
    n('np-w',     'North Promenade West',   31.252993, 75.702015);
    n('np-blk25', 'North Promenade Blk 25', 31.252935, 75.702468);
    n('np-a2526', 'North Promenade Alley 25-26', 31.252935, 75.702705);
    n('np-blk26', 'North Promenade Blk 26', 31.252935, 75.702740);
    n('np-a2627', 'North Promenade Alley 26-27', 31.252931, 75.703126);
    n('np-blk27', 'North Promenade Blk 27', 31.252931, 75.703291);
    n('np-ctr',   'North Promenade Central',31.252931, 75.703537);
    n('np-blk28', 'North Promenade Blk 28', 31.252931, 75.703804);
    n('np-a2829', 'North Promenade Alley 28-29', 31.252932, 75.703953);
    n('np-blk29', 'North Promenade Blk 29', 31.252932, 75.704186);
    n('np-a2930', 'North Promenade Alley 29-30', 31.252926, 75.704523);
    n('np-blk30', 'North Promenade Blk 30', 31.252926, 75.704660);
    n('np-adm',   'North Promenade Admission', 31.252916, 75.705076);
    n('np-e',     'North Promenade East',   31.252921, 75.705246);

    // ── South Academic Walkway (OSM way 4, lat≈31.25232, runs E→W) ──
    n('sw-w',     'South Walkway West',     31.252316, 75.702225);
    n('sw-blk25', 'South Walkway Blk 25',   31.252328, 75.702468);
    n('sw-a2526', 'South Walkway Alley 25-26', 31.252328, 75.702680);
    n('sw-blk26', 'South Walkway Blk 26',   31.252328, 75.702740);
    n('sw-a2627', 'South Walkway Alley 26-27', 31.252328, 75.703096);
    n('sw-blk27', 'South Walkway Blk 27',   31.252328, 75.703291);
    n('sw-ctr',   'South Walkway Central',  31.252328, 75.703505);
    n('sw-blk28', 'South Walkway Blk 28',   31.252328, 75.703804);
    n('sw-a2829', 'South Walkway Alley 28-29', 31.252322, 75.703917);
    n('sw-blk29', 'South Walkway Blk 29',   31.252328, 75.704186);
    n('sw-a2930', 'South Walkway Alley 29-30', 31.252317, 75.704207);
    n('sw-blk30', 'South Walkway Blk 30',   31.252328, 75.704660);
    n('sw-adm',   'South Walkway Admission', 31.252311, 75.705070);
    n('sw-e',     'South Walkway East',     31.252294, 75.705266);

    // ── Place centroids (connect to the road via entrance links) ──
    n('blk-25',         'Block 25',             31.252777, 75.702468);
    n('blk-26',         'Block 26',             31.252672, 75.702740);
    n('blk-27',         'Block 27',             31.252718, 75.703291);
    n('blk-28',         'Block 28',             31.252778, 75.703804);
    n('blk-29',         'Block 29',             31.252786, 75.704186);
    n('blk-30',         'Block 30 Infotech',    31.252645, 75.704660);
    n('library',        'Central Library',      31.252063, 75.703373);
    n('sd-auditorium',  'SD Mittal Auditorium', 31.252061, 75.704131);
    n('blk-32',         'Block 32',             31.252040, 75.704783);
    n('blk-36',         'Block 36',             31.252013, 75.704969);
    n('pnb-bank',       'PNB & ATM',            31.252013, 75.704969);
    n('admission',      'Admission Block',      31.252720, 75.704746);
    n('lpu-main-parking', 'LPU Main Parking',   31.252855, 75.705590);

    // ── West Avenue & Hostels ──
    n('mgmt',       'Management Block',  31.254689, 75.701273);
    n('hostel-rd-1','Hostel Avenue N',   31.252000, 75.701200);
    n('bh-1',       'Boys Hostel 1',     31.251405, 75.700350);
    n('hostel-rd-2','Hostel Avenue Mid', 31.250500, 75.700600);
    n('bh-2-3',     'Boys Hostel 2 & 3',31.249615, 75.701060);
    n('hostel-rd-3','Hostel Avenue S',   31.248800, 75.699500);
    n('bh-4',       'Boys Hostel 4',     31.248597, 75.699875);
    n('food-factory','Food Factory',     31.247972, 75.698611);

    // ── South Avenue (Polytechnic & Aerospace) ──
    n('s-spine-1', 'South Avenue N',    31.251200, 75.703500);
    n('s-spine-2', 'South Avenue Mid',  31.249000, 75.703500);
    n('blk-55',    'Block 55',          31.247047, 75.703522);
    n('aerospace', 'School of Aerospace', 31.246918, 75.703311);
    n('blk-56',    'Block 56',          31.246546, 75.703589);
    n('blk-57',    'Block 57',          31.246231, 75.703723);
    n('polytechnic','School of Polytechnic', 31.246294, 75.704078);

    return m;
  }

  // ─── Road-network edges (undirected) ────────────────────────────────────
  static final List<List<String>> _edges = [
    // ── Main North Boulevard ──
    ['main-gate-parking', 'uni-hospital'],
    ['uni-hospital', 'n-boulevard'],
    ['n-boulevard', 'uni-mall'],

    // ── North Hub roads ──
    ['uni-mall', 'unipolis'],
    ['uni-mall', 'east-rd-msb'],
    ['unipolis', 'msb'],
    ['unipolis', 'hotel-mgmt'],
    ['hotel-mgmt', 'blk-15'],
    ['blk-15', 'blk-18'],
    ['blk-18', 'phys-ed'],
    ['blk-18', 'ns-north'],
    ['phys-ed', 'ns-north'],
    ['east-rd-msb', 'msb'],
    ['east-rd-msb', 'blk-14'],
    ['blk-14', 'lpu-main-parking'],
    ['lpu-main-parking', 'np-e'],

    // ── Central North Spine (OSM way 12: service road lat≈31.2535) ──
    ['ns-north', 'ns-mid'],
    ['ns-mid', 'ns-south'],
    ['ns-south', 'ns-blk34'],
    ['ns-blk34', 'ns-end'],
    ['ns-end', 'np-w'],       // spine meets North Promenade west end

    // ── Block 34 connections ──
    ['ns-blk34', 'blk-34'],
    ['blk-34', 'np-ctr'],     // Block 34 south exit → North Promenade central

    // ── North Promenade (OSM way 6, exact coords, W→E) ──
    ['np-w',     'np-blk25'],
    ['np-blk25', 'np-a2526'],
    ['np-a2526', 'np-blk26'],
    ['np-blk26', 'np-a2627'],
    ['np-a2627', 'np-blk27'],
    ['np-blk27', 'np-ctr'],
    ['np-ctr',   'np-blk28'],
    ['np-blk28', 'np-a2829'],
    ['np-a2829', 'np-blk29'],
    ['np-blk29', 'np-a2930'],
    ['np-a2930', 'np-blk30'],
    ['np-blk30', 'np-adm'],
    ['np-adm',   'np-e'],

    // ── South Academic Walkway (OSM way 4, exact coords, W→E) ──
    ['sw-w',     'sw-blk25'],
    ['sw-blk25', 'sw-a2526'],
    ['sw-a2526', 'sw-blk26'],
    ['sw-blk26', 'sw-a2627'],
    ['sw-a2627', 'sw-blk27'],
    ['sw-blk27', 'sw-ctr'],
    ['sw-ctr',   'sw-blk28'],
    ['sw-blk28', 'sw-a2829'],
    ['sw-a2829', 'sw-blk29'],
    ['sw-blk29', 'sw-a2930'],
    ['sw-a2930', 'sw-blk30'],
    ['sw-blk30', 'sw-adm'],
    ['sw-adm',   'sw-e'],
    ['sw-e',     'lpu-main-parking'],

    // ── Inter-block alleys (North Promenade ↔ South Walkway, OSM ways 36,37,45,33,29) ──
    ['np-w',     'sw-w'],
    ['np-a2526', 'sw-a2526'],
    ['np-a2627', 'sw-a2627'],
    ['np-ctr',   'sw-ctr'],
    ['np-a2829', 'sw-a2829'],
    ['np-a2930', 'sw-a2930'],
    ['np-adm',   'sw-adm'],

    // ── Building entrance links (block → nearest road node, BOTH roads) ──
    ['blk-25', 'sw-blk25'], ['blk-25', 'np-blk25'],
    ['blk-26', 'sw-blk26'], ['blk-26', 'np-blk26'],
    ['blk-27', 'sw-blk27'], ['blk-27', 'np-blk27'],
    ['blk-28', 'sw-blk28'], ['blk-28', 'np-blk28'],
    ['blk-29', 'sw-blk29'], ['blk-29', 'np-blk29'],
    ['blk-30', 'sw-blk30'], ['blk-30', 'np-blk30'],

    // ── South-row facilities (entrance from South Walkway) ──
    ['library',       'sw-blk27'],
    ['library',       'sw-ctr'],
    ['sd-auditorium', 'sw-blk29'],
    ['sd-auditorium', 'sw-a2829'],
    ['blk-32',        'sw-blk30'],
    ['blk-36',        'sw-adm'],
    ['pnb-bank',      'sw-adm'],
    ['admission',     'np-adm'], ['admission', 'sw-adm'],

    // ── West Avenue & Hostels ──
    ['np-w',        'mgmt'],
    ['sw-w',        'hostel-rd-1'],
    ['mgmt',        'hostel-rd-1'],
    ['hostel-rd-1', 'bh-1'],
    ['bh-1',        'hostel-rd-2'],
    ['hostel-rd-2', 'bh-2-3'],
    ['bh-2-3',      'hostel-rd-3'],
    ['hostel-rd-3', 'bh-4'],
    ['bh-4',        'food-factory'],

    // ── South Avenue to Polytechnic & Aerospace ──
    ['sw-ctr',   's-spine-1'],
    ['sw-adm',   's-spine-1'],
    ['s-spine-1','s-spine-2'],
    ['s-spine-2','blk-55'],
    ['blk-55',   'aerospace'],
    ['blk-55',   'blk-56'],
    ['aerospace','blk-56'],
    ['blk-56',   'blk-57'],
    ['blk-57',   'polytechnic'],

    // ── MSB / Block-14 south entrance onto North Promenade ──
    ['msb', 'np-e'],
    ['msb', 'blk-14'],
  ];

  // ─── Adjacency list cache ────────────────────────────────────────────────
  static Map<String, List<MapEntry<String, double>>>? _adj;

  static Map<String, List<MapEntry<String, double>>> _getAdj() {
    if (_adj != null) return _adj!;
    final map = <String, List<MapEntry<String, double>>>{};
    for (final id in _nodes.keys) {
      map[id] = [];
    }
    for (final e in _edges) {
      final u = e[0], v = e[1];
      if (_nodes.containsKey(u) && _nodes.containsKey(v)) {
        final d = _dist.as(LengthUnit.Meter, _nodes[u]!.pt, _nodes[v]!.pt);
        map[u]!.add(MapEntry(v, d));
        map[v]!.add(MapEntry(u, d));
      }
    }
    return _adj = map;
  }

  // ─── Dijkstra shortest path ──────────────────────────────────────────────
  static ({List<String> ids, double cost}) _dijkstra(
      String start, String dest) {
    final dist = <String, double>{};
    final prev = <String, String?>{};
    for (final id in _nodes.keys) {
      dist[id] = double.infinity;
      prev[id] = null;
    }
    dist[start] = 0;

    // Priority queue: (cost, nodeId)
    final pq = SplayTreeSet<(double, String)>(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    pq.add((0, start));

    final adj = _getAdj();

    while (pq.isNotEmpty) {
      final (d, u) = pq.first;
      pq.remove(pq.first);
      if (d > dist[u]!) continue;
      if (u == dest) break;
      for (final nb in adj[u] ?? []) {
        final alt = dist[u]! + nb.value;
        if (alt < dist[nb.key]!) {
          pq.remove((dist[nb.key]!, nb.key));
          dist[nb.key] = alt;
          prev[nb.key] = u;
          pq.add((alt, nb.key));
        }
      }
    }

    final path = <String>[];
    String? cur = dest;
    while (cur != null) {
      path.insert(0, cur);
      cur = prev[cur];
    }
    return (ids: path, cost: dist[dest]!);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  static String _closestNode(LatLng pt) {
    String best = _nodes.keys.first;
    double minD = double.infinity;
    for (final e in _nodes.entries) {
      final d = _dist.as(LengthUnit.Meter, pt, e.value.pt);
      if (d < minD) {
        minD = d;
        best = e.key;
      }
    }
    return best;
  }

  static double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static MapEntry<String, String> _maneuver(double b1, double b2) {
    final diff = ((b2 - b1 + 180) % 360) - 180;
    if (diff.abs() < 25) return const MapEntry('straight', 'Continue straight');
    if (diff >= 25 && diff <= 120) return const MapEntry('right', 'Turn right');
    if (diff > 120) return const MapEntry('sharp right', 'Make a sharp right');
    if (diff <= -25 && diff >= -120) return const MapEntry('left', 'Turn left');
    return const MapEntry('sharp left', 'Make a sharp left');
  }

  // ─── Public API ──────────────────────────────────────────────────────────
  /// Returns the shortest road-following route between [start] and [dest].
  /// The polyline strictly follows paved roads and walkways.
  static RouteResult calculateRoute(
    LatLng start,
    LatLng dest, {
    String? startName,
    String? destName,
  }) {
    final directDistance = _dist.as(LengthUnit.Meter, start, dest);

    // Very close (<= 60 m): direct corridor walk
    if (directDistance <= 60) {
      final duration = directDistance / 1.3;
      return RouteResult(
        points: [start, dest],
        distance: directDistance,
        duration: duration,
        steps: [
          NavigationStep(
            instruction: destName != null
                ? 'Walk along the campus walkway to $destName'
                : 'Walk along the campus corridor to your destination',
            location: start,
            type: 'depart',
            modifier: 'straight',
            distance: directDistance,
            duration: duration,
          ),
          NavigationStep(
            instruction:
                destName != null ? 'Arrive at $destName' : 'You have arrived',
            location: dest,
            type: 'arrive',
            distance: 0,
            duration: 0,
          ),
        ],
      );
    }

    final startId = _closestNode(start);
    final destId  = _closestNode(dest);

    if (startId == destId) {
      final node = _nodes[startId]!;
      final total = _dist.as(LengthUnit.Meter, start, node.pt) +
          _dist.as(LengthUnit.Meter, node.pt, dest);
      final dur = total / 1.3;
      return RouteResult(
        points: [start, node.pt, dest],
        distance: total,
        duration: dur,
        steps: [
          NavigationStep(
            instruction: 'Head towards ${node.label}',
            location: start,
            type: 'depart',
            modifier: 'straight',
            distance: total,
            duration: dur,
          ),
          NavigationStep(
            instruction: destName != null ? 'Arrive at $destName' : 'You have arrived',
            location: dest,
            type: 'arrive',
            distance: 0,
            duration: 0,
          ),
        ],
      );
    }

    final result = _dijkstra(startId, destId);
    final pathIds = result.ids;

    // Fallback: no path found
    if (pathIds.isEmpty || pathIds.first != startId) {
      final dur = directDistance / 1.3;
      return RouteResult(
        points: [start, dest],
        distance: directDistance,
        duration: dur,
        steps: [
          NavigationStep(
            instruction: 'Walk towards destination',
            location: start,
            type: 'depart',
            modifier: 'straight',
            distance: directDistance,
            duration: dur,
          ),
          NavigationStep(
            instruction: 'You have arrived',
            location: dest,
            type: 'arrive',
            distance: 0,
            duration: 0,
          ),
        ],
      );
    }

    // Build road-following polyline
    final points = <LatLng>[start];
    double totalDist = 0;

    final firstNode = _nodes[pathIds.first]!;
    final dToFirst = _dist.as(LengthUnit.Meter, start, firstNode.pt);
    if (dToFirst > 3) {
      points.add(firstNode.pt);
      totalDist += dToFirst;
    }

    for (int i = 0; i < pathIds.length - 1; i++) {
      final u = _nodes[pathIds[i]]!;
      final v = _nodes[pathIds[i + 1]]!;
      totalDist += _dist.as(LengthUnit.Meter, u.pt, v.pt);
      points.add(v.pt);
    }

    final lastNode = _nodes[pathIds.last]!;
    final dFromLast = _dist.as(LengthUnit.Meter, lastNode.pt, dest);
    if (dFromLast > 3) {
      points.add(dest);
      totalDist += dFromLast;
    }

    final totalDur = totalDist / 1.3;

    // Build turn-by-turn steps
    final steps = <NavigationStep>[];

    steps.add(NavigationStep(
      instruction: 'Head towards ${firstNode.label}',
      location: start,
      type: 'depart',
      modifier: 'straight',
      distance: dToFirst,
      duration: dToFirst / 1.3,
    ));

    for (int i = 0; i < pathIds.length - 1; i++) {
      final cur  = _nodes[pathIds[i]]!;
      final next = _nodes[pathIds[i + 1]]!;
      final segD = _dist.as(LengthUnit.Meter, cur.pt, next.pt);

      String tType = 'turn';
      String tMod  = 'straight';
      String tText = 'Continue straight';

      if (i > 0) {
        final prev = _nodes[pathIds[i - 1]]!;
        final b1   = _bearing(prev.pt, cur.pt);
        final b2   = _bearing(cur.pt, next.pt);
        final m    = _maneuver(b1, b2);
        tMod  = m.key;
        tText = m.value;
      }

      steps.add(NavigationStep(
        instruction: '$tText towards ${next.label}',
        location: cur.pt,
        type: tType,
        modifier: tMod,
        distance: segD,
        duration: segD / 1.3,
      ));
    }

    steps.add(NavigationStep(
      instruction: destName != null ? 'Arrive at $destName' : 'You have arrived at your destination',
      location: dest,
      type: 'arrive',
      modifier: 'straight',
      distance: 0,
      duration: 0,
    ));

    return RouteResult(
      points: points,
      steps: steps,
      distance: totalDist,
      duration: totalDur,
    );
  }
}
