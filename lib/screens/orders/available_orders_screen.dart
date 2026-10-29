import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/orders_provider.dart';

class AvailableOrdersScreen extends ConsumerWidget {
  const AvailableOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryOrdersProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.available.isEmpty) {
      return const Center(child: Text('Nenhum pedido disponível no momento.'));
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.available.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final o = state.available[i];
          return InkWell(
            onTap: () => context.go('/pedido/${o.id}'),
            child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(o.pharmacyName.isNotEmpty ? o.pharmacyName : o.pharmacyId,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text('R\$ ${o.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(child: Text(o.deliveryAddress)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${o.items.length} item(ns) • ${o.isDelivery ? "Entrega" : "Retirada"}',
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Aceitar entrega'),
                      onPressed: () async {
                        final ok = await ref
                            .read(deliveryOrdersProvider.notifier)
                            .acceptOrder(o.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Pedido aceito! Vá para "Meus".'
                                  : 'Erro ao aceitar pedido.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
