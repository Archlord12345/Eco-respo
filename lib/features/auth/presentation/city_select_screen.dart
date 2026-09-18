import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../shared/models/enums.dart';
import 'auth_controller.dart';

class CitySelectScreen extends ConsumerStatefulWidget {
  const CitySelectScreen({super.key});

  @override
  ConsumerState<CitySelectScreen> createState() => _CitySelectScreenState();
}

class _CitySelectScreenState extends ConsumerState<CitySelectScreen> {
  final _name = TextEditingController();
  String _city = 'Yaoundé';
  String _district = 'Bastos';
  UserRole _role = UserRole.citizen;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Votre quartier')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            initialValue: _city,
            items: const [
              DropdownMenuItem(value: 'Yaoundé', child: Text('Yaoundé')),
              DropdownMenuItem(value: 'Douala', child: Text('Douala')),
              DropdownMenuItem(value: 'Bafoussam', child: Text('Bafoussam')),
            ],
            onChanged: (v) => setState(() => _city = v ?? _city),
            decoration: const InputDecoration(labelText: 'Ville'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            initialValue: _district,
            items: const [
              DropdownMenuItem(value: 'Bastos', child: Text('Bastos')),
              DropdownMenuItem(value: 'Mfoundi', child: Text('Mfoundi')),
              DropdownMenuItem(value: 'Nlongkak', child: Text('Nlongkak')),
              DropdownMenuItem(value: 'Centre', child: Text('Centre')),
            ],
            onChanged: (v) => setState(() => _district = v ?? _district),
            decoration: const InputDecoration(labelText: 'Quartier'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            initialValue: _role,
            items: const [
              DropdownMenuItem(value: UserRole.citizen, child: Text('Citoyen')),
              DropdownMenuItem(value: UserRole.collector, child: Text('Collecteur')),
              DropdownMenuItem(value: UserRole.admin, child: Text('Administrateur municipal')),
            ],
            onChanged: (v) => setState(() => _role = v ?? _role),
            decoration: const InputDecoration(labelText: 'Profil'),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Entrer dans l’application',
            onPressed: () async {
              if (user == null) return;
              await ref.read(authProvider.notifier).saveProfile(
                    user.copyWith(
                      name: _name.text.isEmpty ? 'Citoyen' : _name.text,
                      city: _city,
                      district: _district,
                      role: _role,
                    ),
                  );
              if (!context.mounted) return;
              switch (_role) {
                case UserRole.admin:
                  context.go('/admin');
                case UserRole.collector:
                  context.go('/collector');
                case UserRole.citizen:
                  context.go('/home');
              }
            },
          ),
        ],
      ),
    );
  }
}
