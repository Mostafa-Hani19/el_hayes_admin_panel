import 'package:flutter/foundation.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase URL and API key
  static const String supabaseUrl = 'https://vrxausiiphduaezcsvch.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyeGF1c2lpcGhkdWFlemNzdmNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMTY0MzcsImV4cCI6MjA2Njg5MjQzN30.y5DH3Ng_Gf9OqCy81R61wzfJM4FBuip8NAugDryiVRI';
  
  // Debug flag
  static bool get isDebugMode => kDebugMode;
} 