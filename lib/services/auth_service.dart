import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabaseClient;

  AuthService(this._supabaseClient);

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return null;

      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('AuthService: Signing in with email: $email');
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        debugPrint('AuthService: Sign in successful, user ID: ${response.user!.id}');
        final userData = await _supabaseClient
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
        
        debugPrint('AuthService: User profile data: $userData');
        
        // Check if is_admin field exists in the profile data
        if (userData.containsKey('is_admin')) {
          debugPrint('AuthService: is_admin field found: ${userData['is_admin']}');
        } else {
          debugPrint('AuthService: is_admin field NOT found in profile data');
        }
        
        return UserModel.fromJson(userData);
      }
      debugPrint('AuthService: Sign in failed, user is null');
      return null;
    } catch (e) {
      debugPrint('AuthService: Error signing in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabaseClient.auth.currentUser != null;
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final user = await getCurrentUser();
      return user?.role == 'admin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Stream of auth changes
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;
} 