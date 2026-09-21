import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app/app_target.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/enums.dart';
import 'auth_controller.dart';

/// Complément de profil après inscription : nom, ville, quartier et rôle.
class CitySelectScreen extends ConsumerStatefulWidget {
  const CitySelectScreen({super.key});

  @override
  ConsumerState<CitySelectScreen> createState() => _CitySelectScreenState();
}

class _CitySelectScreenState extends ConsumerState<CitySelectScreen> {
  late final TextEditingController _name;
  late final TextEditingController _district;
  late String _city;
  late UserRole _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name == 'Citoyen' ? '' : user?.name ?? '');
    _district = TextEditingController(text: user?.district ?? '');
    _city = AppConstants.cities.contains(user?.city) ? user!.city : AppConstants.cities.first;
    _role = user?.role ?? UserRole.citizen;
  }

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).saveProfile(
            user.copyWith(
              name: _name.text.trim().isEmpty ? 'Citoyen' : _name.text.trim(),
              city: _city,
              district: _district.text.trim(),
              role: _role,
            ),
          );
      if (!mounted) return;
      context.go(ref.read(appTargetProvider).homeFor(_role));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement impossible : $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(appTargetProvider);
    final roles = [
      if (target.hasCitizenSpace) UserRole.citizen,
      if (target.hasCollectorSpace) UserRole.collector,
      if (target.hasBackOffice) UserRole.operator,
      if (target.hasBackOffice) UserRole.admin,
    ];
    if (!roles.contains(_role)) _role = roles.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Votre profil')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const AssetImageBox(asset: AppAssets.iconCity, height: 64, width: 64, radius: 16),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Dites-nous où vous êtes pour adapter les zones de collecte et les alertes de votre quartier.',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _city,
                items: [for (final c in AppConstants.cities) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _city = v ?? _city),
                decoration: const InputDecoration(labelText: 'Ville', prefixIcon: Icon(Icons.location_city_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _district,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Quartier',
                  hintText: 'Ex. Bastos, Bonabéri, Mvan…',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Je suis…', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              RadioGroup<UserRole>(
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v ?? _role),
                child: Column(
                  children: [
                    for (final role in roles)
                      RadioListTile<UserRole>(
                        value: role,
                        title: Text(role.labelFr),
                        subtitle: Text(_roleHint(role)),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Entrer dans l’application',
                icon: Icons.arrow_forward,
                loading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleHint(UserRole role) => switch (role) {
        UserRole.citizen => 'Signaler, demander une collecte, gagner des points',
        UserRole.collector => 'Recevoir des demandes et réaliser les tournées',
        UserRole.operator => 'Dispatcher les demandes et gérer la flotte',
        UserRole.admin => 'Piloter les signalements et les zones de la commune',
      };
}
