import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/campus_data.dart';
import '../models/navigation_step.dart';
import '../models/place.dart';
import '../services/google_maps_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import '../services/routing_service.dart';
import '../services/supabase_service.dart';
import '../services/tts_service.dart';
import '../widgets/auth/auth_modal_sheet.dart';
import '../widgets/common/campus_drawer.dart';
import '../widgets/emergency/emergency_sheet.dart';
import '../widgets/map/campus_map_view.dart';
import '../widgets/map/map_controls.dart';
import '../widgets/map/turn_by_turn_hud.dart';
import '../widgets/places/category_filter_bar.dart';
import '../widgets/places/place_details_sheet.dart';
import '../widgets/places/places_bottom_sheet.dart';
import '../widgets/search/campus_search_bar.dart';
import '../widgets/search/search_suggestions_overlay.dart';

class MapScreen extends StatefulWidget {
  final PreferencesService prefs;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MapScreen({
    super.key,
    required this.prefs,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final LocationService _locationService = LocationService();
  final RoutingService _routingService = RoutingService();
  final TtsService _ttsService = TtsService();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double?>? _headingSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AuthState>? _authSubscription;

  late List<Place> _places;
  String _selectedCategory = 'All';
  Place? _selectedPlace;
  Place? _selectedOriginPlace;
  String _originDisplayName = 'My Location';
  Position? _currentPosition;
  double? _heading;
  User? _currentUser;
  String? _profilePicPath;
  late Set<String> _favorites;
  late String _mapStyle;

  bool _isNavigating = false;
  bool _isOffRoute = false;
  bool _isLocating = false;
  bool _isFollowingLocation = false;
  bool _isRouteLoading = false;
  bool _isOffline = false;

  List<LatLng> _routePoints = [];
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  double _routeDistance = 0.0;
  double _routeDuration = 0.0;

  List<Place> _searchSuggestions = [];

  List<Place> get _visiblePlaces {
    if (_selectedCategory == 'All') {
      return _places;
    }
    return _places.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _places = List.from(CampusData.defaultPlaces);
    _favorites = widget.prefs.getFavorites();
    _mapStyle = widget.prefs.getMapStyle();
    _ttsService.isMuted = !widget.prefs.isVoiceEnabled();
    _currentUser = SupabaseService.currentUser;

    _initServices();
  }

  Future<void> _initServices() async {
    await _ttsService.init();

    // Check connectivity
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _handleConnectivityChange(connectivityResult);
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
    } catch (_) {}

    // Auth state changes
    _authSubscription = SupabaseService.authStateChanges.listen((data) {
      if (mounted) {
        setState(() => _currentUser = data.session?.user);
      }
    });

    // Start location & compass
    _startLocationUpdates();
    _startCompassUpdates();

    // Fetch dynamic places from Supabase
    _fetchSupabasePlaces();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.contains(ConnectivityResult.none);
    if (mounted && offline != _isOffline) {
      setState(() => _isOffline = offline);
      if (offline) {
        _showToast('Offline Mode: Using cached campus map');
      }
    }
  }

  Future<void> _startLocationUpdates() async {
    final hasPerm = await _locationService.checkAndRequestPermission();
    if (!hasPerm) return;

    try {
      final initialPos = await _locationService.getCurrentPosition();
      if (initialPos != null && mounted) {
        setState(() {
          _currentPosition = initialPos;
          _isFollowingLocation = true;
        });
        _mapController.move(
          LatLng(initialPos.latitude, initialPos.longitude),
          AppConstants.defaultZoom,
        );
      }
    } catch (_) {}

    _positionSubscription?.cancel();
    _positionSubscription = _locationService.getPositionStream().listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = pos);

      if (_isFollowingLocation) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom,
        );
      }

      if (_isNavigating) {
        _processNavigationProgress(pos);
      }
    });
  }

  void _startCompassUpdates() {
    _headingSubscription?.cancel();
    _headingSubscription = _locationService.getHeadingStream()?.listen((heading) {
      if (mounted && heading != null) {
        setState(() => _heading = heading);
      }
    });
  }

  Future<void> _fetchSupabasePlaces() async {
    final fetched = await SupabaseService.fetchPlaces();
    if (fetched.isNotEmpty && mounted) {
      setState(() {
        for (final p in fetched) {
          final index = _places.indexWhere((existing) => existing.name == p.name);
          if (index >= 0) {
            _places[index] = p;
          } else {
            _places.add(p);
          }
        }
      });
    }
  }

  // Navigation Logic
  Future<void> _buildAndStartRoute(
    Place place, {
    bool autoStartNav = false,
    Place? customOrigin,
  }) async {
    _searchFocusNode.unfocus();
    setState(() {
      _selectedPlace = place;
      _searchSuggestions = [];
      _isRouteLoading = true;
      if (customOrigin != null) {
        _selectedOriginPlace = customOrigin;
      }
    });

    LatLng start;
    String startName;

    if (_selectedOriginPlace != null) {
      start = _selectedOriginPlace!.point;
      startName = _selectedOriginPlace!.name;
    } else {
      // Determine user position or campus entry
      Position? startPos = _currentPosition;
      if (startPos == null) {
        startPos = await _locationService.getCurrentPosition();
        if (startPos != null && mounted) {
          setState(() => _currentPosition = startPos);
        }
      }

      if (startPos != null) {
        final userCoord = LatLng(startPos.latitude, startPos.longitude);
        const distCalc = Distance();
        final distFromCenter = distCalc.as(LengthUnit.Meter, userCoord, AppConstants.campusCenter);

        if (distFromCenter <= AppConstants.maxCampusRadiusMeters) {
          // User is on campus!
          start = userCoord;
          startName = 'My Location';
        } else {
          // User is off-campus! Set start to Campus Main Gate to show the true campus walk
          start = AppConstants.campusMainGate;
          startName = 'Main Gate Entrance';
          _showToast('Showing shortest walk from Campus Main Gate');
        }
      } else {
        // Fallback to Main Gate if GPS not available
        start = AppConstants.campusMainGate;
        startName = 'Main Gate Entrance';
      }
    }

    setState(() => _originDisplayName = startName);

    final routeResult = await _routingService.calculateWalkingRoute(
      start,
      place.point,
      startName: startName,
      destName: place.name,
    );

    if (!mounted) return;

    if (routeResult != null) {
      setState(() {
        _routePoints = routeResult.points;
        _navigationSteps = routeResult.steps;
        _routeDistance = routeResult.distance;
        _routeDuration = routeResult.duration;
        _currentStepIndex = 0;
        _isRouteLoading = false;
        _isFollowingLocation = (_selectedOriginPlace == null);
        if (autoStartNav) {
          _isNavigating = true;
          _isFollowingLocation = true;
        }
      });

      if (autoStartNav) {
        _mapController.move(start, 18.5);
        _ttsService.speak('Starting walking navigation to ${place.name}.');
      } else {
        _fitRouteBounds();
        _ttsService.speak('Shortest path found to ${place.name}.');
      }
    } else {
      setState(() => _isRouteLoading = false);
      _showToast('Could not calculate route. Showing place location.');
      _mapController.move(place.point, 17.5);
    }
  }

  void _showOriginSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose Starting Point',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Calculating shortest walk to ${_selectedPlace?.name ?? "destination"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                      ),
                      title: const Text('My Current GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Route directly from where you are standing'),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedOriginPlace = null);
                        if (_selectedPlace != null) {
                          _buildAndStartRoute(_selectedPlace!);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.routeGreen,
                        child: Icon(Icons.door_front_door_rounded, color: Colors.white, size: 20),
                      ),
                      title: const Text('Campus Main Gate (GT Road Entrance)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Primary university entrance on Delhi-Jalandhar Highway'),
                      onTap: () {
                        Navigator.pop(ctx);
                        final mainGate = _places.firstWhere(
                          (p) => p.name.contains('Main Gate'),
                          orElse: () => const Place(
                            id: 'main-gate',
                            name: 'Main Gate Parking',
                            lat: 31.259875,
                            lng: 75.706047,
                            category: 'Administration',
                            imageUrl: '',
                            description: 'Campus Main Gate on GT Road',
                            timings: '24 Hours',
                          ),
                        );
                        setState(() => _selectedOriginPlace = mainGate);
                        if (_selectedPlace != null) {
                          _buildAndStartRoute(_selectedPlace!, customOrigin: mainGate);
                        }
                      },
                    ),
                    const Divider(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Or pick any Campus Block / Place:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: _places.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final p = _places[index];
                          if (p.name == _selectedPlace?.name) return const SizedBox.shrink();
                          return ListTile(
                            leading: Icon(
                              Icons.location_on_rounded,
                              color: AppColors.getCategoryColor(p.category),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(p.category),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _selectedOriginPlace = p);
                              if (_selectedPlace != null) {
                                _buildAndStartRoute(_selectedPlace!, customOrigin: p);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _fitRouteBounds() {
    if (_routePoints.isEmpty) return;
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in _routePoints) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.fromLTRB(40, 140, 40, 260),
      ),
    );
  }

  void _processNavigationProgress(Position pos) {
    if (_routePoints.isEmpty || _selectedPlace == null) return;

    final cur = LatLng(pos.latitude, pos.longitude);
    const distanceCalculator = Distance();

    // Check step announcements
    if (_currentStepIndex < _navigationSteps.length) {
      final step = _navigationSteps[_currentStepIndex];
      final distToStep = distanceCalculator.as(LengthUnit.Meter, cur, step.location);

      if (distToStep < 18 && !step.announced) {
        _ttsService.speak(step.instruction);
        step.announced = true;
        if (_currentStepIndex < _navigationSteps.length - 1) {
          _currentStepIndex++;
        }
      }
    }

    // Check arrival
    final distToDest = distanceCalculator.as(LengthUnit.Meter, cur, _selectedPlace!.point);
    if (distToDest < 15) {
      _ttsService.speak('You have arrived at ${_selectedPlace!.name}!');
      _showToast('You have arrived at ${_selectedPlace!.name}!');
      _stopNavigation();
      return;
    }

    // Check off-route
    double minDistToPath = double.infinity;
    for (final p in _routePoints) {
      final d = distanceCalculator.as(LengthUnit.Meter, cur, p);
      if (d < minDistToPath) minDistToPath = d;
    }

    if (minDistToPath > 35 && !_isOffRoute) {
      setState(() => _isOffRoute = true);
      _ttsService.speak('Off route. Recalculating shortest path.');
      _buildAndStartRoute(_selectedPlace!, autoStartNav: true);
    } else if (minDistToPath <= 15 && _isOffRoute) {
      setState(() => _isOffRoute = false);
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _isOffRoute = false;
      _routePoints = [];
      _navigationSteps = [];
      _currentStepIndex = 0;
      _selectedOriginPlace = null;
    });
    _ttsService.stop();
  }

  // UI Event Handlers
  void _onSearchQueryChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchSuggestions = []);
      return;
    }

    final matches = _places.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();

    setState(() => _searchSuggestions = matches);
  }

  void _onSearchSubmitted(String query) {
    _searchFocusNode.unfocus();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    widget.prefs.addRecentSearch(query);

    final match = _places.firstWhere(
      (p) => p.name.toLowerCase().contains(q),
      orElse: () => _places.first,
    );
    _selectPlace(match);
  }

  void _selectPlace(Place place) {
    _searchController.text = place.name;
    _searchFocusNode.unfocus();
    widget.prefs.addRecentSearch(place.name);
    _buildAndStartRoute(place, autoStartNav: false);
  }

  void _goToUserLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _currentPosition = pos;
          _isFollowingLocation = true;
          _isLocating = false;
        });
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          18.0,
        );
      } else {
        setState(() => _isLocating = false);
        _showToast('Unable to determine location. Check GPS permissions.');
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _resetNorth() {
    _mapController.rotate(0.0);
    _showToast('Orientation reset to North');
  }

  void _onSelectMapStyle(String style) {
    setState(() => _mapStyle = style);
    widget.prefs.setMapStyle(style);
  }

  void _toggleFavorite(Place place) async {
    await widget.prefs.toggleFavorite(place.name);
    setState(() {
      _favorites = widget.prefs.getFavorites();
    });
    final isFav = _favorites.contains(place.name);
    _showToast(isFav ? '${place.name} added to saved places' : '${place.name} removed from saved');
  }

  void _openInGoogleMaps(Place place) async {
    final origin = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;
    final launched = await GoogleMapsService.launchNavigation(
      destination: place.point,
      origin: origin,
      destinationTitle: place.name,
    );
    if (!launched) {
      _showToast('Opening Google Maps location...');
      await GoogleMapsService.openPlaceInGoogleMaps(place.point, name: place.name);
    }
  }

  void _shareLocation() async {
    if (_currentPosition == null) {
      _showToast('Waiting for campus GPS signal to share live location');
      return;
    }
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final shareText = 'I am currently at Lovely Professional University (LPU Campus).\nMy live location: $mapsUrl';

    await SharePlus.instance.share(
      ShareParams(text: shareText),
    );
  }

  void _openEmergencySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const EmergencySheet(),
    );
  }

  void _openAuthSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AuthModalSheet(
        onSuccess: (msg) {
          _showToast(msg);
          setState(() => _currentUser = SupabaseService.currentUser);
        },
      ),
    );
  }

  void _openProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentUser?.email ?? 'My Profile',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                title: const Text('Take Profile Picture (Camera)'),
                onTap: () => _pickAndCropImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () => _pickAndCropImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await SupabaseService.signOut();
                  if (mounted) {
                    setState(() => _currentUser = null);
                    _showToast('Signed out successfully');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    Navigator.pop(context);
    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
        ],
      );

      if (cropped != null && mounted) {
        setState(() => _profilePicPath = cropped.path);
        _showToast('Profile photo updated!');
      }
    } catch (e) {
      _showToast('Could not crop image: $e');
    }
  }

  void _showFavoritesSheet() {
    final favPlaces = _places.where((p) => _favorites.contains(p.name)).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Saved Places (${favPlaces.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (favPlaces.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'No saved places yet.\nTap the heart icon on any campus place to save it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: favPlaces.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          favPlaces[i].imageUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.place, color: AppColors.primary),
                        ),
                      ),
                      title: Text(favPlaces[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(favPlaces[i].category),
                      trailing: const Icon(Icons.directions_walk_rounded, color: AppColors.primary),
                      onTap: () {
                        Navigator.pop(ctx);
                        _selectPlace(favPlaces[i]);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _headingSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _authSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _locationService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePlaces;
    final totalBlocks = _places.where((p) => p.category == 'Academic Blocks').length;
    final currentNavStep = (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length)
        ? _navigationSteps[_currentStepIndex]
        : null;

    return Scaffold(
      key: _scaffoldKey,
      drawer: CampusDrawer(
        currentUser: _currentUser,
        totalBlocksCount: totalBlocks,
        favoritesCount: _favorites.length,
        isDarkMode: widget.isDarkMode,
        isVoiceEnabled: !_ttsService.isMuted,
        onToggleDarkMode: (_) => widget.onToggleTheme(),
        onToggleVoice: (val) {
          setState(() => _ttsService.isMuted = !val);
          widget.prefs.setVoiceEnabled(val);
        },
        onOpenAuth: () {
          Navigator.pop(context);
          _openAuthSheet();
        },
        onSignOut: () async {
          Navigator.pop(context);
          await SupabaseService.signOut();
          if (mounted) {
            setState(() => _currentUser = null);
            _showToast('Signed out');
          }
        },
        onOpenEmergency: () {
          Navigator.pop(context);
          _openEmergencySheet();
        },
        onShowFavorites: () {
          Navigator.pop(context);
          _showFavoritesSheet();
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Campus Map View
            CampusMapView(
              mapController: _mapController,
              mapStyle: _mapStyle,
              places: visible,
              selectedPlace: _selectedPlace,
              userPosition: _currentPosition,
              userHeading: _heading,
              routePoints: _routePoints,
              isNavigating: _isNavigating,
              onSelectPlace: _selectPlace,
              onManualPan: () {
                if (_isFollowingLocation) {
                  setState(() => _isFollowingLocation = false);
                }
              },
            ),

            // Google Maps Navigation HUD (Active when navigating)
            if (_isNavigating && _selectedPlace != null)
              Positioned.fill(
                child: TurnByTurnHud(
                  currentStep: currentNavStep,
                  nextStep: (_navigationSteps.length > _currentStepIndex + 1)
                      ? _navigationSteps[_currentStepIndex + 1]
                      : null,
                  destination: _selectedPlace!,
                  distanceRemaining: _routeDistance,
                  durationRemaining: _routeDuration,
                  isOffRoute: _isOffRoute,
                  isVoiceMuted: _ttsService.isMuted,
                  isFollowingLocation: _isFollowingLocation,
                  onToggleVoice: () {
                    setState(() => _ttsService.toggleMute());
                    widget.prefs.setVoiceEnabled(!_ttsService.isMuted);
                  },
                  onStopNavigation: _stopNavigation,
                  onOpenGoogleMaps: () => _openInGoogleMaps(_selectedPlace!),
                  onRecenter: () {
                    final pt = _selectedOriginPlace?.point ??
                        (_currentPosition != null
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : (_routePoints.isNotEmpty ? _routePoints.first : AppConstants.campusCenter));
                    _mapController.move(pt, 18.5);
                    setState(() => _isFollowingLocation = true);
                  },
                ),
              ),

            // Search Bar & Categories (Active when NOT in full navigation mode)
            if (!_isNavigating)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CampusSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      currentUser: _currentUser,
                      profilePicPath: _profilePicPath,
                      isOffline: _isOffline,
                      onChanged: _onSearchQueryChanged,
                      onSubmitted: _onSearchSubmitted,
                      onClear: () {
                        _searchController.clear();
                        setState(() => _searchSuggestions = []);
                      },
                      onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                      onShareLocation: _shareLocation,
                      onProfileTap: () {
                        if (_currentUser == null) {
                          _openAuthSheet();
                        } else {
                          _openProfileSheet();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    CategoryFilterBar(
                      selectedCategory: _selectedCategory,
                      onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
                    ),
                    // Auto-complete Suggestions Overlay
                    SearchSuggestionsOverlay(
                      suggestions: _searchSuggestions,
                      recentSearches: widget.prefs.getRecentSearches(),
                      userPosition: _currentPosition,
                      onSelectPlace: _selectPlace,
                      onSelectRecentQuery: (q) {
                        _searchController.text = q;
                        _onSearchSubmitted(q);
                      },
                      onClearRecents: () async {
                        await widget.prefs.clearRecentSearches();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

            // Floating Map Controls (Compass, Style, Location, SOS)
            if (!_isNavigating)
              Positioned(
                right: 16,
                bottom: _selectedPlace != null ? 240 : 160,
                child: MapControls(
                  heading: _heading,
                  isLocating: _isLocating,
                  isFollowingLocation: _isFollowingLocation,
                  currentMapStyle: _mapStyle,
                  onRecenterNorth: _resetNorth,
                  onGoToUserLocation: _goToUserLocation,
                  onSelectMapStyle: _onSelectMapStyle,
                  onOpenEmergency: _openEmergencySheet,
                ),
              ),

            // Place Details Sheet (if a place is clicked)
            if (_selectedPlace != null && !_isNavigating)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: PlaceDetailsSheet(
                  place: _selectedPlace!,
                  userPosition: _currentPosition,
                  originName: _originDisplayName,
                  onSelectOrigin: _showOriginSelectionSheet,
                  isRouteLoading: _isRouteLoading,
                  routeDistance: _routeDistance,
                  routeDuration: _routeDuration,
                  isNavigating: _isNavigating,
                  isFavorite: _favorites.contains(_selectedPlace!.name),
                  onStartNavigation: () {
                    if (_routePoints.isEmpty) {
                      _buildAndStartRoute(_selectedPlace!, autoStartNav: true);
                    } else {
                      setState(() {
                        _isNavigating = true;
                        _isFollowingLocation = true;
                      });
                      final startPt = _selectedOriginPlace?.point ??
                          (_currentPosition != null
                              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                              : (_routePoints.isNotEmpty ? _routePoints.first : AppConstants.campusCenter));
                      _mapController.move(startPt, 18.5);
                      _ttsService.speak('Starting walking navigation to ${_selectedPlace!.name}.');
                    }
                  },
                  onOpenGoogleMaps: () => _openInGoogleMaps(_selectedPlace!),
                  onToggleFavorite: () => _toggleFavorite(_selectedPlace!),
                  onShare: () {
                    final p = _selectedPlace!;
                    final url = 'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}';
                    SharePlus.instance.share(
                      ShareParams(text: 'Meet me at ${p.name} (LPU Campus): $url'),
                    );
                  },
                  onClose: () {
                    setState(() {
                      _selectedPlace = null;
                      _selectedOriginPlace = null;
                      _routePoints = [];
                      _navigationSteps = [];
                    });
                  },
                ),
              ),

            // Places List Bottom Sheet (when no place is selected and not navigating)
            if (_selectedPlace == null && !_isNavigating)
              PlacesBottomSheet(
                places: visible,
                selectedCategory: _selectedCategory,
                userPosition: _currentPosition,
                onSelectPlace: _selectPlace,
              ),
          ],
        ),
      ),
    );
  }
}
