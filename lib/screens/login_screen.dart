// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_email');
    if (rememberedEmail != null) {
      setState(() {
        _emailController.text = rememberedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

Future<void> _handleSignIn() async {
  if (_formKey.currentState?.validate() ?? false) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Clear any previous errors
      authProvider.setErrorMessage(null);
      
      // Debug print
      debugPrint('Attempting to sign in with email: $email');
      
      // Attempt to sign in
      final success = await authProvider.signIn(email, password);

      // Debug print
      debugPrint('Sign in success: $success');
      
      if (!success || !mounted) {
        debugPrint('Login failed or widget unmounted');
        return;
      }
      
      // Get Supabase client and current user ID
      final supabase = authProvider.supabaseClient;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        debugPrint('User ID is null after login');
        authProvider.setErrorMessage('Login failed: Could not get user ID');
        return;
      }
      
      // Directly check is_admin in the database
      debugPrint('Checking is_admin for user: $userId');
      final response = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();
      
      debugPrint('Admin check response: $response');
      final isAdmin = response != null && response['is_admin'] == true;
      debugPrint('Is admin based on direct DB check: $isAdmin');
      
      if (!isAdmin) {
        debugPrint('User is not an admin based on direct DB check');
        authProvider.setErrorMessage('Access denied. Only admins can login.');
        await authProvider.signOut(); // Sign out non-admin users
        return;
      }
      
      // Remember Me logic
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', email);
      } else {
        await prefs.remove('remembered_email');
      }
      
      // Navigate to dashboard if all checks pass
      debugPrint('Navigating to dashboard');
      Navigator.pushReplacementNamed(context, Constants.dashboardRoute);
    } catch (e) {
      debugPrint('Login error: ${e.toString()}');
      authProvider.setErrorMessage('Login failed: ${e.toString()}');
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust container width based on available width
          double containerWidth;
          if (constraints.maxWidth > 1200) {
            containerWidth = 450; // Large desktop
          } else if (constraints.maxWidth > 800) {
            containerWidth = 400; // Desktop/tablet
          } else if (constraints.maxWidth > 600) {
            containerWidth = 350; // Small tablet
          } else {
            containerWidth = constraints.maxWidth * 0.9; // Mobile
          }
          
          return Center(
            child: SingleChildScrollView(
              child: Container(
                width: containerWidth,
                padding: EdgeInsets.all(
                  isSmallScreen ? Constants.defaultPadding : Constants.largePadding
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Constants.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Admin Login',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: isSmallScreen ? Constants.defaultPadding : Constants.largePadding),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: Constants.defaultPadding),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: Validators.validatePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSignIn(),
                          ),
                          const SizedBox(height: Constants.smallPadding),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text('Remember me'),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final emailController = TextEditingController(text: _emailController.text);
                                      return AlertDialog(
                                        title: const Text('Reset Password'),
                                        content: TextFormField(
                                          controller: emailController,
                                          decoration: const InputDecoration(labelText: 'Enter your email'),
                                          keyboardType: TextInputType.emailAddress,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final email = emailController.text.trim();
                                              if (email.isEmpty) return;
                                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                              final success = await authProvider.resetPassword(email);
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(success
                                                      ? 'Password reset email sent.'
                                                      : 'Failed to send reset email.'),
                                                ),
                                              );
                                            },
                                            child: const Text('Send'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text('Forgot Password?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: Constants.defaultPadding),
                          if (authProvider.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: Constants.defaultPadding,
                              ),
                              child: Text(
                                authProvider.errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _handleSignIn,
                              child: authProvider.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }
} 