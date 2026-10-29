import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _vehicleType;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final person = ref.read(deliveryAuthProvider).person;
      if (person != null) {
        _nameController.text = person.name;
        _phoneController.text = person.phone;
        _vehicleType = person.vehicleType;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(deliveryAuthProvider.notifier).updateProfile(
          name: _nameController.text,
          phone: _phoneController.text,
          vehicleType: _vehicleType,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Perfil atualizado!' : 'Erro ao atualizar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = ref.watch(deliveryAuthProvider).person;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: person == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: person.email,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _vehicleType,
                      decoration: const InputDecoration(labelText: 'Modalidade'),
                      items: const [
                        DropdownMenuItem(value: 'moto', child: Text('Moto')),
                        DropdownMenuItem(value: 'bicicleta', child: Text('Bicicleta')),
                        DropdownMenuItem(value: 'carro', child: Text('Carro')),
                      ],
                      onChanged: (v) => setState(() => _vehicleType = v),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Salvar'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair'),
                      onPressed: () => ref.read(deliveryAuthProvider.notifier).logout(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
