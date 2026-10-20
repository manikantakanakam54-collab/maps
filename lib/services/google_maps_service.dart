import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapsService {
  /// Opens Google Maps for turn-by-turn walking navigation from [origin] (or current location) to [destination].
  static Future<bool> launchNavigation({
    required LatLng destination,
    LatLng? origin,
    String? destinationTitle,
  }) async {
    final destLat = destination.latitude;
    final destLng = destination.longitude;

    // 1. On Android native app, try launching the Google Maps Navigation Intent directly
    if (!kIsWeb && Platform.isAndroid) {
      final nativeNavUri = Uri.parse('google.navigation:q=$destLat,$destLng&mode=w');
      try {
        if (await canLaunchUrl(nativeNavUri)) {
          final launched = await launchUrl(
            nativeNavUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {}
    }

    // 2. Universal Web / iOS / Android Fallback: Google Maps Directions API URL
    String webUrl;
    if (origin != null) {
      final origLat = origin.latitude;
      final origLng = origin.longitude;
      webUrl = 'https://www.google.com/maps/dir/?api=1&origin=$origLat,$origLng&destination=$destLat,$destLng&travelmode=walking';
    } else {
      webUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=walking';
    }

    final uri = Uri.parse(webUrl);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {}

    return false;
  }

  /// Opens Google Maps pinned at the location
  static Future<bool> openPlaceInGoogleMaps(LatLng point, {String? name}) async {
    final query = name != null && name.isNotEmpty
        ? Uri.encodeComponent('$name, Lovely Professional University')
        : '${point.latitude},${point.longitude}';
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
