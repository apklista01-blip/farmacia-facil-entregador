import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_person_model.dart';

class DeliveryAuthState {
  final DeliveryPersonModel? person;
  final bool isLoading;
  final String? errorMessage;

  const DeliveryAuthState({
    this.person,
    this.isLoading = true,
    this.errorMessage,
  });

  bool get isLoggedIn => person != null;

  DeliveryAuthState copyWith({
    DeliveryPersonModel? person,
    bool clearPerson = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeliveryAuthState(
      person: clearPerson ? null : (person ?? this.person),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DeliveryAuthNotifier extends Notifier<DeliveryAuthState> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _ignoreNextAuthChange = false;

  @override
  DeliveryAuthState build() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    return const DeliveryAuthState(isLoading: true);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (_ignoreNextAuthChange) {
      _ignoreNextAuthChange = false;
      return;
    }
    if (firebaseUser == null) {
      state = const DeliveryAuthState(isLoading: false);
      return;
    }
    await _verifyDeliveryPerson(firebaseUser);
  }

  Future<void> _verifyDeliveryPerson(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('delivery_persons')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final person = DeliveryPersonModel.fromMap({
          'id': firebaseUser.uid,
          ...doc.data()!,
        });
        if (!person.isActive) {
          await _auth.signOut();
          state = const DeliveryAuthState(
            isLoading: false,
            errorMessage: 'Sua conta esta desativada. Contate o admin.',
          );
          return;
        }
        state = DeliveryAuthState(person: person, isLoading: false);
      } else {
        await _auth.signOut();
        state = const DeliveryAuthState(
          isLoading: false,
          errorMessage: 'Acesso negado: nao e entregador cadastrado.',
        );
      }
    } catch (e) {
      await _auth.signOut();
      state = DeliveryAuthState(isLoading: false, errorMessage: 'Erro: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    if (email.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Preencha e-mail e senha');
      return false;
    }
    try {
      _ignoreNextAuthChange = true;
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _verifyDeliveryPerson(credential.user!);
      return state.isLoggedIn;
    } on FirebaseAuthException catch (e) {
      _ignoreNextAuthChange = false;
      state = state.copyWith(isLoading: false, errorMessage: _translateError(e.code));
      return false;
    } catch (e) {
      _ignoreNextAuthChange = false;
      state = state.copyWith(isLoading: false, errorMessage: 'Erro ao fazer login.');
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String vehicleType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, errorMessage: 'Preencha todos os campos');
      return false;
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final uid = credential.user!.uid;
      final person = DeliveryPersonModel(
        id: uid,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        vehicleType: vehicleType,
        isActive: true,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('delivery_persons').doc(uid).set(person.toMap());
      state = DeliveryAuthState(person: person, isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _translateError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Erro ao cadastrar: $e');
      return false;
    }
  }
  Future<bool> updateProfile({required String name, required String phone, String? vehicleType}) async {
    final person = state.person;
    if (person == null) return false;
    try {
      final updates = <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
      };
      if (vehicleType != null) updates['vehicleType'] = vehicleType;
      await _firestore.collection('delivery_persons').doc(person.id).update(updates);
      state = DeliveryAuthState(
        person: DeliveryPersonModel(
          id: person.id,
          name: name.trim(),
          email: person.email,
          phone: phone.trim(),
          vehicleType: vehicleType ?? person.vehicleType,
          isActive: person.isActive,
          createdAt: person.createdAt,
        ),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Erro ao atualizar: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const DeliveryAuthState(isLoading: false);
  }

  String _translateError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail invalido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde.';
      case 'network-request-failed':
        return 'Sem conexao com a internet.';
      default:
        return 'Erro de autenticacao ($code).';
    }
  }
}

final deliveryAuthProvider =
    NotifierProvider<DeliveryAuthNotifier, DeliveryAuthState>(
  DeliveryAuthNotifier.new,
);

