import 'package:latlong2/latlong.dart';

class Place {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String category;
  final String imageUrl;
  final String description;
  final String timings;

  const Place({
    required this.name,
    required this.lat,
    required this.lng,
    required this.category,
    required this.imageUrl,
    this.id = '',
    this.description = '',
    this.timings = '8:00 AM - 6:00 PM',
  });

  LatLng get point => LatLng(lat, lng);

  double distanceInMetersTo(LatLng userLocation) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, userLocation, point);
  }

  String formattedDistance(LatLng? userLocation) {
    if (userLocation == null) return '';
    final meters = distanceInMetersTo(userLocation);
    if (meters < 1000) {
      return '${meters.round()} m away';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km away';
    }
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Campus Location',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Academic Blocks',
      imageUrl: json['image_url'] as String? ??
          'https://www.lpu.in/infrastructure/images/Infrastructure/Academic-Blocks-1.jpg',
      description: json['description'] as String? ?? '',
      timings: json['timings'] as String? ?? '8:00 AM - 6:00 PM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'category': category,
      'image_url': imageUrl,
      'description': description,
      'timings': timings,
    };
  }

  Place copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    String? category,
    String? imageUrl,
    String? description,
    String? timings,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      timings: timings ?? this.timings,
    );
  }
}
