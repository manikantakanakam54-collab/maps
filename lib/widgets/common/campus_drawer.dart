import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';

class CampusDrawer extends StatelessWidget {
  final User? currentUser;
  final int totalBlocksCount;
  final int favoritesCount;
  final bool isDarkMode;
  final bool isVoiceEnabled;
  final ValueChanged<bool> onToggleDarkMode;
  final ValueChanged<bool> onToggleVoice;
  final VoidCallback onOpenAuth;
  final VoidCallback onSignOut;
  final VoidCallback onOpenEmergency;
  final VoidCallback onShowFavorites;

  const CampusDrawer({
    super.key,
    required this.currentUser,
    required this.totalBlocksCount,
    required this.favoritesCount,
    required this.isDarkMode,
    required this.isVoiceEnabled,
    required this.onToggleDarkMode,
    required this.onToggleVoice,
    required this.onOpenAuth,
    required this.onSignOut,
    required this.onOpenEmergency,
    required this.onShowFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/lpu_logo.png',
                        width: 36,
                        height: 36,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.map_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LPU Maps Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Lovely Professional University',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // User account badge
                if (currentUser != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_circle, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            currentUser!.email ?? 'Logged In',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onOpenAuth,
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('Sign In / Register', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Quick Preferences
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Preferences & Tools',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Dark Theme'),
                  value: isDarkMode,
                  onChanged: onToggleDarkMode,
                ),
                SwitchListTile(
                  secondary: Icon(
                    isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text('Voice Guidance'),
                  value: isVoiceEnabled,
                  onChanged: onToggleVoice,
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                  title: const Text('Saved Locations'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$favoritesCount',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  onTap: onShowFavorites,
                ),
                ListTile(
                  leading: const Icon(Icons.emergency_rounded, color: Colors.red),
                  title: const Text('Emergency & SOS Contacts'),
                  onTap: onOpenEmergency,
                ),

                const Divider(),

                // Campus Information
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Campus Information',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.apartment_rounded, color: AppColors.primary),
                  title: const Text('Total Academic Blocks'),
                  subtitle: Text('$totalBlocksCount Blocks on Campus'),
                ),
                const ListTile(
                  leading: Icon(Icons.landscape_rounded, color: AppColors.primary),
                  title: Text('Campus Area'),
                  subtitle: Text('600+ Acres of Smart Infrastructure'),
                ),
                const ListTile(
                  leading: Icon(Icons.person_pin_rounded, color: AppColors.primary),
                  title: Text('Founder & Chancellor'),
                  subtitle: Text('Dr. Ashok Kumar Mittal (MP Rajya Sabha)'),
                ),
                const ListTile(
                  leading: Icon(Icons.code_rounded, color: AppColors.primary),
                  title: Text('App Developer'),
                  subtitle: Text('K Manikanta (LPU Student Project)'),
                ),

                if (currentUser != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.red),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                    onTap: onSignOut,
                  ),
                ],
              ],
            ),
          ),

          // Footer version
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'LPU Maps v1.1.0 • Upgraded Edition',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
