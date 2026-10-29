import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class DeliveryOrdersState {
  final List<OrderModel> available;
  final List<OrderModel> mine;
  final bool isLoading;
  final String? errorMessage;

  const DeliveryOrdersState({
    this.available = const [],
    this.mine = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  DeliveryOrdersState copyWith({
    List<OrderModel>? available,
    List<OrderModel>? mine,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeliveryOrdersState(
      available: available ?? this.available,
      mine: mine ?? this.mine,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DeliveryOrdersNotifier extends Notifier<DeliveryOrdersState> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _availableSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mineSub;

  String? get _uid => _auth.currentUser?.uid;

  @override
  DeliveryOrdersState build() {
    _startListeners();
    ref.onDispose(() {
      _availableSub?.cancel();
      _mineSub?.cancel();
    });
    return const DeliveryOrdersState(isLoading: true);
  }

  void _startListeners() {
    _availableSub = _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.ready.name)
        .snapshots()
        .listen((snap) {
      final available = snap.docs
          .where((d) => d.data()['deliveryPersonId'] == null)
          .map((d) => OrderModel.fromMap({'id': d.id, ...d.data()}))
          .toList();
      state = state.copyWith(available: available, isLoading: false, clearError: true);
    }, onError: (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erro ao carregar disponiveis: $e');
    });

    final uid = _uid;
    if (uid != null) {
      _mineSub = _firestore
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: uid)
          .snapshots()
          .listen((snap) {
        final mine = snap.docs
            .map((d) => OrderModel.fromMap({'id': d.id, ...d.data()}))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(mine: mine, isLoading: false, clearError: true);
      }, onError: (e) {
        state = state.copyWith(isLoading: false, errorMessage: 'Erro ao carregar meus pedidos: $e');
      });
    }
  }
  Future<bool> acceptOrder(String orderId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'deliveryPersonId': uid,
        'status': OrderStatus.delivering.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao aceitar pedido: $e');
      return false;
    }
  }

  Future<bool> markDelivered(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.delivered.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao marcar entregue: $e');
      return false;
    }
  }
}

final deliveryOrdersProvider =
    NotifierProvider<DeliveryOrdersNotifier, DeliveryOrdersState>(
  DeliveryOrdersNotifier.new,
);

