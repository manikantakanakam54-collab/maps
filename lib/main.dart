import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'screens/splash_screen.dart';
import 'services/location_service.dart';
import 'services/preferences_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/auth/auth_modal_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend
  await SupabaseService.initialize();

  // Initialize SharedPreferences
  final prefs = await PreferencesService.init();

  runApp(LpuMapsApp(prefs: prefs));
}

class LpuMapsApp extends StatefulWidget {
  final PreferencesService prefs;

  const LpuMapsApp({super.key, required this.prefs});

  @override
  State<LpuMapsApp> createState() => _LpuMapsAppState();
}

class _LpuMapsAppState extends State<LpuMapsApp> {
  late ThemeMode _themeMode;
  bool _hasStarted = false;
  bool _isLocatingOnStart = false;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.prefs.getThemeMode();
    // If user is already authenticated, start directly into map
    if (SupabaseService.currentUser != null) {
      _hasStarted = true;
    }
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
    });
    widget.prefs.setThemeMode(_themeMode);
  }

  Future<void> _startApp() async {
    setState(() => _isLocatingOnStart = true);

    final locationService = LocationService();
    await locationService.checkAndRequestPermission();

    if (mounted) {
      setState(() {
        _isLocatingOnStart = false;
        _hasStarted = true;
      });
    }
  }

  void _openAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AuthModalSheet(
        onSuccess: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
          );
          setState(() => _hasStarted = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;

    return MaterialApp(
      title: 'LPU Maps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _hasStarted
          ? MapScreen(
              prefs: widget.prefs,
              isDarkMode: isDark,
              onToggleTheme: _toggleTheme,
            )
          : Builder(
              builder: (ctx) => SplashScreen(
                isFindingLocation: _isLocatingOnStart,
                onStart: _startApp,
                onOpenAuth: () => _openAuthSheet(ctx),
              ),
            ),
    );
  }
}
