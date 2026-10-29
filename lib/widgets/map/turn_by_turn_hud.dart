import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/navigation_step.dart';
import '../../models/place.dart';

class TurnByTurnHud extends StatelessWidget {
  final NavigationStep? currentStep;
  final NavigationStep? nextStep;
  final Place destination;
  final double distanceRemaining;
  final double durationRemaining;
  final bool isOffRoute;
  final bool isVoiceMuted;
  final bool isFollowingLocation;
  final VoidCallback onToggleVoice;
  final VoidCallback onStopNavigation;
  final VoidCallback onRecenter;
  final VoidCallback onOpenGoogleMaps;

  const TurnByTurnHud({
    super.key,
    required this.currentStep,
    this.nextStep,
    required this.destination,
    required this.distanceRemaining,
    required this.durationRemaining,
    required this.isOffRoute,
    required this.isVoiceMuted,
    this.isFollowingLocation = true,
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

  String get _etaClockTime {
    final now = DateTime.now().add(Duration(seconds: durationRemaining.round()));
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  String get _formattedStepDistance {
    final d = currentStep?.distance ?? 0.0;
    if (d <= 0) return '';
    if (d < 1000) return 'In ${d.round()} m';
    return 'In ${(d / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomBarBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Stack(
      children: [
        // 1. TOP GOOGLE MAPS NAVIGATION BANNER
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Off-Route Alert Banner (if user strays away)
              if (isOffRoute)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.offRouteRed,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
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
                          'Off route. Recalculating shortest path...',
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

              // Main Google Maps Navigation Header Card
              Container(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                decoration: BoxDecoration(
                  color: const Color(0xFF137333), // Google Maps Navigation Green
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    children: [
                      // Large Turn Maneuver Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentStep?.icon ?? Icons.navigation_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Navigation Instruction Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_formattedStepDistance.isNotEmpty) ...[
                              Text(
                                _formattedStepDistance,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              currentStep?.instruction ?? 'Proceed to ${destination.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (nextStep != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Then: ${nextStep!.instruction}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Right Control Buttons (Sound & Google Maps fallback)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: isVoiceMuted ? 'Unmute Voice' : 'Mute Voice',
                            icon: Icon(
                              isVoiceMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: onToggleVoice,
                          ),
                          IconButton(
                            tooltip: 'Open in Google Maps App',
                            icon: const Icon(
                              Icons.explore_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: onOpenGoogleMaps,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. FLOATING RE-CENTER BUTTON (Appears when map is panned away from user)
        if (!isFollowingLocation)
          Positioned(
            bottom: 95,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'nav_recenter_fab',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF137333),
              elevation: 6,
              onPressed: onRecenter,
              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF137333)),
              label: const Text(
                'Re-center',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF137333),
                ),
              ),
            ),
          ),

        // 3. BOTTOM GOOGLE MAPS TRIP BAR (Time, Distance, Clock ETA, Exit Button)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: bottomBarBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // ETA Info (Green ETA time, distance, arrival clock)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formattedRemainingTime,
                                style: const TextStyle(
                                  color: Color(0xFF137333),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($_formattedRemainingDistance)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled_rounded,
                                size: 14,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ETA: $_etaClockTime • Walking to ${destination.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Red Circular Google Maps "✕" Exit Button
                    GestureDetector(
                      onTap: onStopNavigation,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
