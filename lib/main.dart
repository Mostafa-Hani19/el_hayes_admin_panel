import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/users_screen.dart';
import 'screens/products_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/banners_screen.dart';
import 'screens/tickers_screen.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final authService = AuthService(supabase);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
      ],
      child: MaterialApp(
        title: Constants.appName,
        theme: ThemeConfig.lightTheme(),
        darkTheme: ThemeConfig.darkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          Constants.loginRoute: (context) => const LoginScreen(),
          Constants.dashboardRoute: (context) => const DashboardScreen(),
          Constants.usersRoute: (context) => const UsersScreen(),
          Constants.productsRoute: (context) => const ProductsScreen(),
          Constants.categoriesRoute: (context) => const CategoriesScreen(),
          Constants.ordersRoute: (context) => const OrdersScreen(),
          Constants.settingsRoute: (context) => const SettingsScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/banners': (context) => const BannersScreen(),
          '/tickers': (context) => const TickersScreen(),
        },
      ),
    );
  }
}
