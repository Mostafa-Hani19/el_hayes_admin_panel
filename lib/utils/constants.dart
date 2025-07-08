import 'package:flutter/material.dart';

class Constants {
  // App info
  static const String appName = 'El Hayes Admin Panel';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String usersRoute = '/users';
  static const String productsRoute = '/products';
  static const String categoriesRoute = '/categories';
  static const String ordersRoute = '/orders';
  
  // Shared preferences keys
  static const String themePreference = 'theme_preference';
  static const String authTokenKey = 'auth_token';
  
  // Sizes
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;
  
  // Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 2);
  
  // Responsive breakpoints
  static const double mobileBreakpoint = 650;
  static const double tabletBreakpoint = 1100;
  
  // Helper methods for responsive design
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;
} 