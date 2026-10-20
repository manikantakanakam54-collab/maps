import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_colors.dart';
import '../../models/place.dart';

class SearchSuggestionsOverlay extends StatelessWidget {
  final List<Place> suggestions;
  final List<String> recentSearches;
  final Position? userPosition;
  final ValueChanged<Place> onSelectPlace;
  final ValueChanged<String> onSelectRecentQuery;
  final VoidCallback onClearRecents;

  const SearchSuggestionsOverlay({
    super.key,
    required this.suggestions,
    required this.recentSearches,
    required this.userPosition,
    required this.onSelectPlace,
    required this.onSelectRecentQuery,
    required this.onClearRecents,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    final LatLng? userLoc = userPosition != null
        ? LatLng(userPosition!.latitude, userPosition!.longitude)
        : null;

    if (suggestions.isEmpty && recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: [
            // If showing suggestions
            if (suggestions.isNotEmpty)
              ...suggestions.map((place) {
                final distStr = place.formattedDistance(userLoc);
                return ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      place.imageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 44,
                        height: 44,
                        color: AppColors.getCategoryColor(place.category)
                            .withValues(alpha: 0.2),
                        child: Icon(
                          Icons.place_rounded,
                          color: AppColors.getCategoryColor(place.category),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    place.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    place.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: distStr.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            distStr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => onSelectPlace(place),
                );
              }),

            // If suggestions are empty but user has recent searches
            if (suggestions.isEmpty && recentSearches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Searches',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: onClearRecents,
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              ...recentSearches.map(
                (query) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.history_rounded, size: 20, color: Colors.grey),
                  title: Text(query, style: const TextStyle(fontSize: 14)),
                  trailing: const Icon(Icons.north_west_rounded, size: 16, color: Colors.grey),
                  onTap: () => onSelectRecentQuery(query),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
