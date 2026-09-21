import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/app/app_target.dart';
import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/enums.dart';
import '../../auth/data/appwrite_auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((_) => PackageInfo.fromPlatform());

/// Paramètres : profil, organisation, notifications, langue, connexion
/// Appwrite et déconnexion. `embedded` = affiché dans une coque back-office.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embedded = false, this.title = 'Paramètres'});

  final bool embedded;
  final String title;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _district;
  late String _city;
  late bool _notifications;
  late String _language;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(authProvider).user;
    _name = TextEditingController(text: u?.name ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _district = TextEditingController(text: u?.district ?? '');
    _city = AppConstants.cities.contains(u?.city) ? u!.city : AppConstants.cities.first;
    _notifications = u?.notificationsEnabled ?? true;
    _language = u?.language ?? 'fr';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _district.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final u = ref.read(authProvider).user;
    if (u == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).saveProfile(u.copyWith(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            district: _district.text.trim(),
            city: _city,
            notificationsEnabled: _notifications,
            language: _language,
          ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres enregistrés.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec : $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePin(BuildContext context, String phone) async {
    final old = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget pin(TextEditingController c, String label) => TextField(
                controller: c,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                decoration: InputDecoration(labelText: label, hintText: '••••••'),
              );
          return AlertDialog(
            title: const Text('Nouveau code à 6 chiffres'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  pin(old, 'Code actuel'),
                  const SizedBox(height: 12),
                  pin(next, 'Nouveau code'),
                  const SizedBox(height: 12),
                  pin(confirm, 'Confirmer le nouveau code'),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              FilledButton(
                onPressed: () async {
                  if (next.text.length != 6) {
                    setLocal(() => error = 'Le nouveau code doit contenir 6 chiffres.');
                    return;
                  }
                  if (next.text != confirm.text) {
                    setLocal(() => error = 'Les deux codes ne correspondent pas.');
                    return;
                  }
                  try {
                    await ref.read(authRepositoryProvider).changePin(phone: phone, oldPin: old.text, newPin: next.text);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    setLocal(() => error = e.toString());
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code à 6 chiffres mis à jour.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final target = ref.watch(appTargetProvider);
    final info = ref.watch(packageInfoProvider).value;

    final body = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Section(
          title: 'Profil',
          icon: Icons.person_outline,
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: AppColors.paleGreen, child: Icon(Icons.person, color: AppColors.primaryGreen, size: 30)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(user?.role.labelFr ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        if (user?.email.isNotEmpty ?? false) Text(user!.email, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Chip(label: Text('${user?.points ?? 0} pts'), backgroundColor: AppColors.paleOchre, side: BorderSide.none),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet')),
              const SizedBox(height: 12),
              TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone (Mobile Money)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _city,
                      items: [for (final c in AppConstants.cities) DropdownMenuItem(value: c, child: Text(c))],
                      onChanged: (v) => setState(() => _city = v ?? _city),
                      decoration: const InputDecoration(labelText: 'Ville'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _district, decoration: const InputDecoration(labelText: 'Quartier'))),
                ],
              ),
            ],
          ),
        ),
        _Section(
          title: 'Organisation',
          icon: Icons.business_outlined,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AssetImageBox(asset: AppAssets.cameroonFlag, height: 24, width: 34, radius: 4),
                title: Text(user?.role == UserRole.operator ? 'Entreprise de collecte' : 'Mairie de ${user?.city ?? AppConstants.defaultCity}'),
                subtitle: Text('Profil ${user?.role.labelFr ?? ''} · cible ${target.label}'),
              ),
              if (user != null && target.hasBackOffice)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final role in [UserRole.admin, UserRole.operator])
                        ChoiceChip(
                          label: Text(role.labelFr),
                          selected: user.role == role,
                          onSelected: (_) async {
                            await ref.read(authProvider.notifier).saveProfile(user.copyWith(role: role));
                            if (context.mounted) context.go(target.homeFor(role));
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _Section(
          title: 'Notifications et langue',
          icon: Icons.notifications_outlined,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                subtitle: const Text('Alertes de zone, collectes, points et campagnes'),
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              Row(
                children: [
                  const Expanded(child: Text('Langue')),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'fr', label: Text('Français')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {_language},
                    onSelectionChanged: (s) => setState(() => _language = s.first),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (user != null && user.email.isEmpty && user.phone.isNotEmpty)
          _Section(
            title: 'Sécurité',
            icon: Icons.lock_outline,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Changer mon code à 6 chiffres'),
              subtitle: Text('Compte téléphone ${user.phone} — aucun SMS n’est envoyé.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changePin(context, user.phone),
            ),
          ),
        _Section(
          title: 'Connexion Appwrite',
          icon: Icons.cloud_outlined,
          child: Column(
            children: [
              _KV('Endpoint', AppwriteConfig.endpoint),
              _KV('Projet', AppwriteConfig.projectId),
              _KV('Base de données', AppwriteConfig.databaseId),
              _KV('Version', info == null ? '—' : '${info.version} (${info.buildNumber})'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: const Text('Enregistrer'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/welcome');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          BackOfficeHeader(
            title: widget.title,
            subtitle: 'Compte, organisation, notifications et connexion',
            organisation: user?.role == UserRole.operator ? null : 'Mairie de ${user?.city ?? AppConstants.defaultCity}',
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFF4F6F5),
              child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: body)),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: body)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v);
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(k, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
          Expanded(child: SelectableText(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          IconButton(
            tooltip: 'Copier',
            iconSize: 16,
            onPressed: () => Clipboard.setData(ClipboardData(text: v)),
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
    );
  }
}
