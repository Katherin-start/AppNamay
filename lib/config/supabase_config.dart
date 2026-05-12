import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Credenciales de Supabase
  static const String supabaseUrl = 'https://ouhahctvbkodfzhxtllx.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91aGFoY3R2YmtvZGZ6aHh0bGx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU4ODU0ODgsImV4cCI6MjA5MTQ2MTQ4OH0.rDbgqeW41qv_F1hiudqNkp-9iR2sZXhG-iaiaslUYfY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      debug: true,
    );
  }

  static SupabaseClient get supabaseClient => Supabase.instance.client;

  static GoTrueClient get auth => Supabase.instance.client.auth;
}
