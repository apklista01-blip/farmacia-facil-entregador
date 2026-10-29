import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/delivery_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/orders/available_orders_screen.dart';
import '../screens/orders/my_orders_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(deliveryAuthProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      if (!authState.isLoggedIn && !loggingIn && !registering) return '/login';
      if (authState.isLoggedIn && (loggingIn || registering)) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => DeliveryShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const AvailableOrdersScreen()),
          GoRoute(path: '/pedido/:id', builder: (context, state) => OrderDetailScreen(orderId: state.pathParameters['id']!)),
          GoRoute(path: '/meus', builder: (context, state) => const MyOrdersScreen()),
          GoRoute(path: '/historico', builder: (context, state) => const HistoryScreen()),
          GoRoute(path: '/perfil', builder: (context, state) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
