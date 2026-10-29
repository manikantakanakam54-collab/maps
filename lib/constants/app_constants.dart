import 'package:latlong2/latlong.dart';

class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://iusnddjarbfndaaiqfnv.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Se6fv4fycRYZqGChH7d74w_fqbtXc6L';

  // LPU Campus Coordinates
  static const LatLng campusCenter = LatLng(31.2533614, 75.7035391);
  static const LatLng campusMainGate = LatLng(31.259875, 75.706047);
  static const double maxCampusRadiusMeters = 1600.0;
  static const double defaultZoom = 16.5;
  static const double minZoom = 14.0;
  static const double maxZoom = 19.5;

  // Map Tile Providers
  static const String googleHybridUrl = 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
  static const String googleStreetsUrl = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  static const String googleSatelliteUrl = 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
  static const String googleTerrainUrl = 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
  static const String openStreetMapUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String cartoLightUrl = 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';
  static const String cartoDarkUrl = 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png';
  static const String userAgentPackage = 'com.lpu.maps';

  // Categories
  static const List<String> categories = [
    'All',
    'Academic Blocks',
    'Library',
    'Hostels',
    'Administration',
    'Food Courts',
    'Sports',
    'Hospitals',
  ];

  // Routing API
  static String getOsrmWalkingRouteUrl(LatLng start, LatLng destination) {
    return 'https://router.project-osrm.org/route/v1/foot/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=true&alternatives=false';
  }
}
