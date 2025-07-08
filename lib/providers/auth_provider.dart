import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SupabaseClient supabase = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  // Getter for Supabase client
  SupabaseClient get supabaseClient => supabase;

  Future<void> _init() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.getCurrentUser();
      _listenToAuthChanges();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        _currentUser = await _authService.getCurrentUser();
      } else if (event.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      // 1. تسجيل الدخول
      debugPrint('AuthProvider: Attempting to sign in with email: $email');
      final user = await _authService.signInWithEmailAndPassword(email, password);

      if (user == null) throw Exception('Failed to sign in.');
      debugPrint('AuthProvider: User signed in successfully: ${user.email}');

      // 2. جلب بيانات is_admin من جدول Supabase
      debugPrint('AuthProvider: Checking admin status for user: ${user.id}');
      final profileResponse = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .maybeSingle();

      final isAdmin = profileResponse?['is_admin'] ?? false;
      debugPrint('AuthProvider: is_admin from database: $isAdmin');
      debugPrint('AuthProvider: Raw profile response: $profileResponse');

      _currentUser = user.copyWith(role: isAdmin ? 'admin' : 'user');
      debugPrint('AuthProvider: User role set to: ${_currentUser?.role}');
      return true;
    } catch (e) {
      debugPrint('AuthProvider: Sign in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setErrorMessage(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}
