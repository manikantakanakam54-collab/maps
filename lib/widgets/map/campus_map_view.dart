import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/place.dart';

class CampusMapView extends StatelessWidget {
  final MapController mapController;
  final String mapStyle;
  final List<Place> places;
  final Place? selectedPlace;
  final Position? userPosition;
  final double? userHeading;
  final List<LatLng> routePoints;
  final ValueChanged<Place> onSelectPlace;
  final VoidCallback onManualPan;

  const CampusMapView({
    super.key,
    required this.mapController,
    required this.mapStyle,
    required this.places,
    required this.selectedPlace,
    required this.userPosition,
    required this.userHeading,
    required this.routePoints,
    required this.onSelectPlace,
    required this.onManualPan,
  });

  String get _tileUrlTemplate {
    switch (mapStyle) {
      case 'google_hybrid':
        return AppConstants.googleHybridUrl;
      case 'google_streets':
        return AppConstants.googleStreetsUrl;
      case 'google_satellite':
        return AppConstants.googleSatelliteUrl;
      case 'google_terrain':
        return AppConstants.googleTerrainUrl;
      case 'carto_light':
        return AppConstants.cartoLightUrl;
      case 'carto_dark':
        return AppConstants.cartoDarkUrl;
      default:
        return AppConstants.googleHybridUrl;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Academic Blocks':
        return Icons.school_rounded;
      case 'Library':
        return Icons.local_library_rounded;
      case 'Hostels':
        return Icons.hotel_rounded;
      case 'Administration':
        return Icons.account_balance_rounded;
      case 'Food Courts':
        return Icons.restaurant_rounded;
      case 'Sports':
        return Icons.fitness_center_rounded;
      case 'Hospitals':
        return Icons.local_hospital_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: AppConstants.campusCenter,
        initialZoom: AppConstants.defaultZoom,
        minZoom: AppConstants.minZoom,
        maxZoom: AppConstants.maxZoom,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) {
            onManualPan();
          }
        },
      ),
      children: [
        // Map Tiles
        TileLayer(
          urlTemplate: _tileUrlTemplate,
          userAgentPackageName: AppConstants.userAgentPackage,
        ),

        // Navigation Route Polyline
        if (routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Outer border / glow line
              Polyline(
                points: routePoints,
                strokeWidth: 8.0,
                color: const Color(0xFF047857).withValues(alpha: 0.5),
              ),
              // Inner solid route line
              Polyline(
                points: routePoints,
                strokeWidth: 5.0,
                color: AppColors.routeGreen,
              ),
            ],
          ),

        // Campus Places Markers
        MarkerLayer(
          markers: places.map((place) {
            final isSelected = selectedPlace?.name == place.name;
            final catColor = AppColors.getCategoryColor(place.category);

            return Marker(
              point: place.point,
              width: 100,
              height: 64,
              child: GestureDetector(
                onTap: () => onSelectPlace(place),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _categoryIcon(place.category),
                        size: isSelected ? 24 : 18,
                        color: isSelected ? Colors.white : catColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.shade300, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // User GPS Position & Heading Marker
        if (userPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(userPosition!.latitude, userPosition!.longitude),
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    // Heading arrow / dot
                    Transform.rotate(
                      angle: ((userHeading ?? 0) * (math.pi / 180)),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
