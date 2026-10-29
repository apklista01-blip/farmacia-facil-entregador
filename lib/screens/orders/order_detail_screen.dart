import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/orders_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Future<String?> _loadUserPhone(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return doc.data()?['phone'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openMaps(String address) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDeliver() async {
    final ok = await showDialog<bool>(
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
    if (ok == true) {
      final success = await ref.read(deliveryOrdersProvider.notifier).markDelivered(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Entrega concluida!' : 'Erro ao concluir.')),
        );
        if (success) Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.read(deliveryAuthProvider).person?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do pedido')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Pedido nao encontrado.'));
          }
          final order = OrderModel.fromMap({'id': snapshot.data!.id, ...snapshot.data!.data()!});

          final isAvailable = order.status == OrderStatus.ready && order.deliveryPersonId == null;
          final isMine = order.deliveryPersonId == uid;
          final inRoute = isMine && order.status == OrderStatus.delivering;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.pharmacyName.isNotEmpty ? order.pharmacyName : order.pharmacyId,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Chip(label: Text('${order.status.emoji} ${order.status.label}')),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.person, label: 'Cliente', value: order.userName.isNotEmpty ? order.userName : '-'),
                FutureBuilder<String?>(
                  future: _loadUserPhone(order.userId),
                  builder: (context, snap) {
                    final phone = snap.data;
                    if (phone == null || phone.isEmpty) return const SizedBox.shrink();
                    return _InfoRow(icon: Icons.phone, label: 'Telefone', value: phone);
                  },
                ),
                _InfoRow(icon: Icons.location_on, label: 'Endereco', value: order.deliveryAddress),
                _InfoRow(icon: Icons.local_shipping, label: 'Tipo', value: order.isDelivery ? 'Entrega' : 'Retirada'),
                _InfoRow(icon: Icons.attach_money, label: 'Total', value: 'R\$ ${order.totalPrice.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Text('Itens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...order.items.map((item) => Card(
                      child: ListTile(
                        title: Text(item.productName),
                        subtitle: Text('Qtd: ${item.quantity}'),
                        trailing: Text('R\$ ${item.subtotal.toStringAsFixed(2)}'),
                      ),
                    )),
                const SizedBox(height: 24),
                if (isAvailable)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Aceitar entrega'),
                      onPressed: () async {
                        final ok = await ref.read(deliveryOrdersProvider.notifier).acceptOrder(order.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(ok ? 'Pedido aceito!' : 'Erro ao aceitar.')),
                          );
                        if (ok) Navigator.of(context).pop();
                      },
                    ),
                  ),
                if (inRoute)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Marcar como entregue'),
                      onPressed: _confirmDeliver,
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Abrir no Google Maps'),
                    onPressed: () => _openMaps(order.deliveryAddress),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

