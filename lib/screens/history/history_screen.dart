import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/orders_provider.dart';
import '../../models/order_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryOrdersProvider);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final delivered = state.mine.where((o) => o.status == OrderStatus.delivered).toList();
    if (delivered.isEmpty) {
      return const Center(child: Text('Nenhuma entrega concluida ainda.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: delivered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final o = delivered[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.check, color: Colors.green)),
            title: Text(o.userName.isNotEmpty ? o.userName : 'Cliente'),
            subtitle: Text(o.deliveryAddress),
            isThreeLine: true,
            trailing: Text('R\$ ${o.totalPrice.toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }
}
