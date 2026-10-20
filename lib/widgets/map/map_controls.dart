import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class MapControls extends StatelessWidget {
  final double? heading;
  final bool isLocating;
  final bool isFollowingLocation;
  final String currentMapStyle;
  final VoidCallback onRecenterNorth;
  final VoidCallback onGoToUserLocation;
  final ValueChanged<String> onSelectMapStyle;
  final VoidCallback onOpenEmergency;

  const MapControls({
    super.key,
    required this.heading,
    required this.isLocating,
    required this.isFollowingLocation,
    required this.currentMapStyle,
    required this.onRecenterNorth,
    required this.onGoToUserLocation,
    required this.onSelectMapStyle,
    required this.onOpenEmergency,
  });

  void _showStylePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Map Style & Layers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.satellite_alt_rounded, color: AppColors.primary),
                  title: const Text('Google Maps Hybrid (Satellite)'),
                  subtitle: const Text('High-resolution aerial view with campus block labels'),
                  trailing: (currentMapStyle == 'google_hybrid' || currentMapStyle == 'standard')
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelectMapStyle('google_hybrid');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_road_rounded, color: AppColors.primary),
                  title: const Text('Google Maps Streets'),
                  subtitle: const Text('Google official road & street navigation map'),
                  trailing: currentMapStyle == 'google_streets'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelectMapStyle('google_streets');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.terrain_rounded, color: AppColors.primary),
                  title: const Text('Google Maps Terrain'),
                  subtitle: const Text('Campus topography, lawns and athletic grounds'),
                  trailing: currentMapStyle == 'google_terrain'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelectMapStyle('google_terrain');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_rounded, color: AppColors.primary),
                  title: const Text('OpenStreetMap Default'),
                  subtitle: const Text('Community mapped campus walkways'),
                  trailing: currentMapStyle == 'osm'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelectMapStyle('osm');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.nights_stay_rounded, color: AppColors.primary),
                  title: const Text('Dark Mode Navigator'),
                  subtitle: const Text('Night-friendly high contrast theme'),
                  trailing: currentMapStyle == 'carto_dark'
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelectMapStyle('carto_dark');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emergency SOS Button
        FloatingActionButton.small(
          heroTag: 'emergency_btn',
          onPressed: onOpenEmergency,
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          tooltip: 'Campus Emergency & Medical SOS',
          child: const Icon(Icons.emergency_rounded, size: 22),
        ),
        const SizedBox(height: 10),

        // Compass Rose (Points North, tap resets North)
        FloatingActionButton.small(
          heroTag: 'compass_btn',
          onPressed: onRecenterNorth,
          backgroundColor: btnBg,
          tooltip: 'Tap to reset North',
          child: Transform.rotate(
            angle: ((heading ?? 0) * (math.pi / 180)),
            child: const Icon(
              Icons.explore_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Map Layers / Style switcher
        FloatingActionButton.small(
          heroTag: 'layers_btn',
          onPressed: () => _showStylePicker(context),
          backgroundColor: btnBg,
          tooltip: 'Change Map Style',
          child: const Icon(Icons.layers_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 10),

        // My Location Button
        FloatingActionButton(
          heroTag: 'location_btn',
          onPressed: onGoToUserLocation,
          backgroundColor: btnBg,
          tooltip: 'My GPS Location',
          child: isLocating
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                )
              : Icon(
                  isFollowingLocation
                      ? Icons.navigation_rounded
                      : Icons.my_location_rounded,
                  color: isFollowingLocation ? Colors.blueAccent : AppColors.primary,
                  size: 26,
                ),
        ),
      ],
    );
  }
}
