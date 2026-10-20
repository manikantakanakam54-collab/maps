import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/navigation_step.dart';
import '../../models/place.dart';

class TurnByTurnHud extends StatelessWidget {
  final NavigationStep? currentStep;
  final Place destination;
  final double distanceRemaining;
  final double durationRemaining;
  final bool isOffRoute;
  final bool isVoiceMuted;
  final VoidCallback onToggleVoice;
  final VoidCallback onStopNavigation;
  final VoidCallback onRecenter;
  final VoidCallback onOpenGoogleMaps;

  const TurnByTurnHud({
    super.key,
    required this.currentStep,
    required this.destination,
    required this.distanceRemaining,
    required this.durationRemaining,
    required this.isOffRoute,
    required this.isVoiceMuted,
    required this.onToggleVoice,
    required this.onStopNavigation,
    required this.onRecenter,
    required this.onOpenGoogleMaps,
  });

  String get _formattedRemainingDistance {
    if (distanceRemaining < 1000) {
      return '${distanceRemaining.round()} m';
    } else {
      return '${(distanceRemaining / 1000).toStringAsFixed(1)} km';
    }
  }

  String get _formattedRemainingTime {
    final mins = (durationRemaining / 60).round();
    if (mins <= 1) return '1 min';
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOffRoute)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.offRouteRed,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Off route. Recalculating shortest shortcut...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
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
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Maneuver Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        currentStep?.icon ?? Icons.navigation_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Direction details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStep?.instruction ?? 'Proceed to ${destination.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Towards ${destination.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sound & Recenter buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: isVoiceMuted ? 'Unmute Voice' : 'Mute Voice',
                          icon: Icon(
                            isVoiceMuted ? Icons.volume_off : Icons.volume_up,
                            color: isVoiceMuted ? Colors.grey : AppColors.primary,
                          ),
                          onPressed: onToggleVoice,
                        ),
                        IconButton(
                          tooltip: 'Open in Google Maps',
                          icon: const Icon(Icons.explore_rounded, color: Color(0xFF4285F4)),
                          onPressed: onOpenGoogleMaps,
                        ),
                        IconButton(
                          tooltip: 'Recenter',
                          icon: const Icon(Icons.my_location, color: AppColors.primary),
                          onPressed: onRecenter,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Footer ETA and Cancel Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_formattedRemainingTime ($_formattedRemainingDistance)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onStopNavigation,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('End Route', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
