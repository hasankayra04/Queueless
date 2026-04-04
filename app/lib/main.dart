import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/inventory_service.dart';
import 'services/queue_service.dart';
import 'screens/login_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/owner_dashboard_screen.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(apiClient)),
        ChangeNotifierProvider(create: (_) => QueueService(apiClient)),
        ChangeNotifierProvider(create: (_) => InventoryService(apiClient)),
      ],
      child: const QueueLessApp(),
    ),
  );
}

class QueueLessApp extends StatelessWidget {
  const QueueLessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QueueLess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }
          if (auth.isOwner) {
            return const OwnerDashboardScreen();
          }
          return const CustomerHomeScreen();
        },
      ),
    );
  }
}
