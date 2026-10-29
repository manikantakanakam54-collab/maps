import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../models/place.dart';

class PlaceDetailsSheet extends StatelessWidget {
  final Place place;
  final Position? userPosition;
  final String originName;
  final bool isRouteLoading;
  final double routeDistance;
  final double routeDuration;
  final bool isNavigating;
  final bool isFavorite;
  final VoidCallback onStartNavigation;
  final VoidCallback onOpenGoogleMaps;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;
  final VoidCallback onClose;
  final VoidCallback? onSelectOrigin;

  const PlaceDetailsSheet({
    super.key,
    required this.place,
    required this.userPosition,
    this.originName = 'My Location',
    required this.isRouteLoading,
    required this.routeDistance,
    required this.routeDuration,
    required this.isNavigating,
    required this.isFavorite,
    required this.onStartNavigation,
    required this.onOpenGoogleMaps,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onClose,
    this.onSelectOrigin,
  });

  String get _formattedDuration {
    final mins = (routeDuration / 60).round();
    if (mins <= 1) return '< 1 min walk';
    return '$mins min walk';
  }

  String get _formattedDistance {
    if (routeDistance < 1000) {
      return '${routeDistance.round()} m';
    } else {
      return '${(routeDistance / 1000).toStringAsFixed(2)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final LatLng? userLoc = userPosition != null
        ? LatLng(userPosition!.latitude, userPosition!.longitude)
        : null;

    final distFromUser = place.formattedDistance(userLoc);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRouteLoading)
            const ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
                minHeight: 3,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Image, Info, Close
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        place.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.getCategoryColor(place.category)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            Icons.business_rounded,
                            size: 36,
                            color: AppColors.getCategoryColor(place.category),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.getCategoryColor(place.category)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  place.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getCategoryColor(place.category),
                                  ),
                                ),
                              ),
                              if (distFromUser.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '• $distFromUser',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                place.timings,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      onPressed: onClose,
                    ),
                  ],
                ),

                // Description (if available)
                if (place.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    place.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Origin Row (Allows user to see and switch starting point)
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trip_origin_rounded, size: 14, color: AppColors.routeGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'From: $originName',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onSelectOrigin != null)
                        InkWell(
                          onTap: onSelectOrigin,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Change Start',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.swap_vert_rounded, size: 15, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Route details pill if route calculated
                if (routeDistance > 0 && !isNavigating) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.routeGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.routeGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_walk_rounded, color: AppColors.routeGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Shortest Walk: $_formattedDistance • $_formattedDuration',
                          style: const TextStyle(
                            color: AppColors.routeGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Action Buttons Row
                Row(
                  children: [
                    // Start In-App Navigation Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onStartNavigation,
                        icon: Icon(
                          isNavigating
                              ? Icons.navigation_rounded
                              : Icons.directions_walk_rounded,
                        ),
                        label: Text(
                          isNavigating ? 'In Navigation' : 'In-App Walk',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Google Maps Navigation Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A73E8),
                          side: const BorderSide(color: Color(0xFF4285F4), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onOpenGoogleMaps,
                        icon: const Icon(Icons.explore_rounded, color: Color(0xFF4285F4), size: 18),
                        label: const Text(
                          'Google Maps',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Favorite Button
                    IconButton.filledTonal(
                      tooltip: isFavorite ? 'Remove from Saved' : 'Save Place',
                      style: IconButton.styleFrom(
                        backgroundColor: isFavorite
                            ? Colors.red.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                      ),
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.red : Colors.grey.shade700,
                      ),
                      onPressed: onToggleFavorite,
                    ),
                    const SizedBox(width: 4),

                    // Share Button
                    IconButton.filledTonal(
                      tooltip: 'Share Location',
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                      ),
                      icon: Icon(Icons.share_rounded, color: Colors.grey.shade700),
                      onPressed: onShare,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
