import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeliveryShell extends StatelessWidget {
  final Widget child;
  const DeliveryShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/meus')) return 1;
    if (location.startsWith('/historico')) return 2;
    if (location.startsWith('/perfil')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/meus');
              break;
            case 2:
              context.go('/historico');
              break;
            case 3:
              context.go('/perfil');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Disponíveis'),
          NavigationDestination(icon: Icon(Icons.delivery_dining), label: 'Meus'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
