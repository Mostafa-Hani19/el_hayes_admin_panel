import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/users_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/products_screen.dart';
import 'screens/banners_screen.dart';
import 'screens/tickers_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/support_messages_screen.dart';
import 'screens/login_screen.dart';
import 'models/order_model.dart';
import 'screens/order_details_screen.dart';
import 'screens/branches_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  final supabaseClient = Supabase.instance.client;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService(supabaseClient)),
        ),
        StreamProvider<List<Order>>(
          create: (_) => Order.ordersStream(),
          initialData: const [],
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/users', builder: (context, state) => const UsersScreen()),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/banners',
      builder: (context, state) => const BannersScreen(),
    ),
    GoRoute(
      path: '/tickers',
      builder: (context, state) => const TickersScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/support_messages',
      builder: (context, state) => const SupportMessagesScreen(),
    ),
    GoRoute(
      path: '/branches',
      builder: (context, state) => const BranchesScreen(),
    ),
    GoRoute(
      path: '/order_details/:orderId',
      builder: (context, state) =>
          OrderDetailsScreen(orderId: state.pathParameters['orderId']!),
    ),
  ],
  initialLocation: '/dashboard',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'El Hayes Admin',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Cairo'),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
