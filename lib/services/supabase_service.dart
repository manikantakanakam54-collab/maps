import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/place.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
      );
    } catch (_) {}
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<List<Place>> fetchPlaces() async {
    try {
      final response = await client.from('places').select();
      final List<dynamic> data = response as List<dynamic>;

      return data.map((row) {
        final map = row as Map<String, dynamic>;
        return Place(
          id: map['id']?.toString() ?? '',
          name: map['name']?.toString() ?? 'Campus Point',
          lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
          lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
          category: map['category']?.toString() ?? 'Academic Blocks',
          imageUrl: map['image_url']?.toString() ??
              'https://www.lpu.in/infrastructure/images/Infrastructure/Academic-Blocks-1.jpg',
          description: map['description']?.toString() ?? '',
          timings: map['timings']?.toString() ?? '8:00 AM - 6:00 PM',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
