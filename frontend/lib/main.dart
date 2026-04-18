// QueueLess Flutter app entry point

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/models.dart';
import 'services/api_service.dart';
import 'services/providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/owner/owner_home_screen.dart';

void main() {
  runApp(const QueueLessApp());
}

class QueueLessApp extends StatelessWidget {
  const QueueLessApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Change this to your backend URL when deploying.
    final api = ApiService(baseUrl: 'http://localhost:8080');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api)..init()),
        ChangeNotifierProvider(create: (_) => BusinessProvider(api)),
        ChangeNotifierProvider(create: (_) => QueueProvider(api)),
        ChangeNotifierProvider(create: (_) => InventoryProvider(api)),
      ],
      child: MaterialApp(
        title: 'QueueLess',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const _RootNavigator(),
      ),
    );
  }
}

/// Navigates to the appropriate home screen based on auth state.
class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) return const LoginScreen();

    return switch (auth.user!.role) {
      UserRole.customer => const CustomerHomeScreen(),
      UserRole.businessOwner => const OwnerHomeScreen(),
    };
  }
}
