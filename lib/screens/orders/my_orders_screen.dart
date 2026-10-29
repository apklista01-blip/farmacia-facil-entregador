import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/orders_provider.dart';
import '../../models/order_model.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryOrdersProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final active = state.mine.where((o) => o.status == OrderStatus.delivering).toList();
    final delivered = state.mine.where((o) => o.status == OrderStatus.delivered).toList();

    if (active.isEmpty && delivered.isEmpty) {
      return const Center(child: Text('Você ainda não tem entregas.'));
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.isNotEmpty) ...[
            const Text('Em rota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...active.map((o) => _OrderCard(order: o, onDeliver: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirmar entrega'),
                      content: const Text('Deseja marcar este pedido como entregue?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  final ok = await ref.read(deliveryOrdersProvider.notifier).markDelivered(o.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Entrega concluída!' : 'Erro ao concluir.')),
                    );
                  }
                })),

            const SizedBox(height: 16),
          ],
          if (delivered.isNotEmpty) ...[
            const Text('Concluídas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...delivered.map((o) => _OrderCard(order: o)),
          ],
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onDeliver;
  const _OrderCard({required this.order, this.onDeliver});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/pedido/${order.id}'),
      child: Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.status.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.userName.isNotEmpty ? order.userName : 'Cliente',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('R\$ ${order.totalPrice.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(child: Text(order.deliveryAddress)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${order.items.length} item(ns) • ${order.pharmacyName}',
                style: const TextStyle(color: Colors.black54)),
            if (onDeliver != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Marcar como entregue'),
                  onPressed: onDeliver,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
