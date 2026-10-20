import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';

class CampusSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final User? currentUser;
  final String? profilePicPath;
  final bool isOffline;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onOpenDrawer;
  final VoidCallback onShareLocation;
  final VoidCallback onProfileTap;

  const CampusSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.currentUser,
    required this.profilePicPath,
    required this.isOffline,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onOpenDrawer,
    required this.onShareLocation,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOffline)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'Offline Mode (Using cached map data)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Menu / Drawer Button
              IconButton(
                tooltip: 'Open Menu',
                icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
                onPressed: onOpenDrawer,
              ),

              // Search Text Field
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Block, Library, Hostel...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              // Clear Button (if typing)
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  onPressed: onClear,
                ),

              // Share Location Button
              IconButton(
                tooltip: 'Share Live Location',
                icon: const Icon(Icons.share_location_rounded, color: AppColors.primary),
                onPressed: onShareLocation,
              ),

              // Profile Avatar
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: profilePicPath != null
                        ? FileImage(File(profilePicPath!))
                        : null,
                    child: profilePicPath == null
                        ? Icon(
                            currentUser != null ? Icons.person_rounded : Icons.person_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
