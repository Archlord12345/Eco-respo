import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/eco_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/collection_request.dart';
import '../../../shared/models/enums.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reporting/data/appwrite_report_repository.dart';

class CollectionRequestScreen extends ConsumerStatefulWidget {
  const CollectionRequestScreen({super.key});

  @override
  ConsumerState<CollectionRequestScreen> createState() => _CollectionRequestScreenState();
}

class _CollectionRequestScreenState extends ConsumerState<CollectionRequestScreen> {
  WasteCategory _type = WasteCategory.menager;
  VolumeSize _vol = VolumeSize.petit;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _slot = '08:00 - 12:00';
  bool _recurring = false;
  String _pay = 'mtn';
  bool _loading = false;
  final _address = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Tarif indicatif en FCFA selon le volume (planche 2).
  int get _amount => switch (_vol) {
        VolumeSize.petit => 1500,
        VolumeSize.moyen => 2500,
        VolumeSize.grand => 4000,
        VolumeSize.tresGrand => 6000,
      };

  Future<LatLng> _locate(String city) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return AppConstants.centerFor(city);
      }
      final p = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 8));
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return AppConstants.centerFor(city);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EcoAppBar(subtitle: 'Ensemble pour un Cameroun plus propre'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Demande de collecte à domicile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const Text('Simplifiez-vous la vie ! Nous venons collecter vos déchets à domicile, selon vos disponibilités.'),
          const SizedBox(height: 16),
          _step('1. Type de déchet'),
          Wrap(
            spacing: 8,
            children: WasteCategory.values
                .map((c) => ChoiceChip(
                      selected: _type == c,
                      label: Text(c.labelFr),
                      onSelected: (_) => setState(() => _type = c),
                    ))
                .toList(),
          ),
          _step('2. Estimation du volume'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: VolumeSize.values
                .map((v) => SizedBox(
                      width: 150,
                      child: ChoiceChip(
                        selected: _vol == v,
                        label: Text(v.labelFr),
                        onSelected: (_) => setState(() => _vol = v),
                      ),
                    ))
                .toList(),
          ),
          _step('3. Date et heure de collecte'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                      initialDate: _date,
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  icon: const Icon(Icons.event),
                  label: Text(DateFormat('EEEE d MMMM y', 'fr').format(_date)),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _slot,
                items: const [
                  DropdownMenuItem(value: '08:00 - 12:00', child: Text('08:00 - 12:00')),
                  DropdownMenuItem(value: '12:00 - 16:00', child: Text('12:00 - 16:00')),
                  DropdownMenuItem(value: '16:00 - 19:00', child: Text('16:00 - 19:00')),
                ],
                onChanged: (v) => setState(() => _slot = v ?? _slot),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Demande récurrente'),
            subtitle: const Text('Recevez une collecte régulière (hebdomadaire ou mensuelle)'),
            value: _recurring,
            onChanged: (v) => setState(() => _recurring = v),
          ),
          _step('4. Adresse et consignes'),
          TextField(
            controller: _address,
            decoration: InputDecoration(
              hintText: ref.watch(authProvider).user?.district.isNotEmpty == true
                  ? '${ref.watch(authProvider).user!.district}, ${ref.watch(authProvider).user!.city}'
                  : 'Quartier, rue, repère…',
              prefixIcon: const Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Consignes pour le collecteur (portail, étage, horaires…)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          _step('5. Paiement Mobile Money'),
          Row(
            children: [
              _payCard(AppAssets.mtnMomo, 'mtn'),
              _payCard(AppAssets.orangeMoney, 'orange'),
              _payCard(AppAssets.afriland, 'afriland'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text('Paiement sécurisé et instantané', style: TextStyle(fontSize: 12, color: AppColors.textDark)),
              ),
              Text(
                'Montant : ${NumberFormat.decimalPattern('fr').format(_amount)} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Expanded(child: Text('Vous contribuez à une ville plus propre et un environnement plus sain.')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Confirmer la demande',
            loading: _loading,
            onPressed: () async {
              final user = ref.read(authProvider).user;
              if (user == null) return;
              setState(() => _loading = true);
              try {
                final pos = await _locate(user.city);
                final startHour = int.tryParse(_slot.split(':').first) ?? 8;
                final created = await ref.read(requestRepositoryProvider).create(
                      CollectionRequest(
                        id: '',
                        authorId: user.id,
                        wasteType: _type,
                        estimatedVolume: _vol,
                        scheduledAt: DateTime(_date.year, _date.month, _date.day, startHour),
                        status: RequestStatus.pending,
                        isRecurring: _recurring,
                        paymentProvider: _pay,
                        timeSlot: _slot,
                        amountPaid: _amount,
                        address: _address.text.trim().isNotEmpty
                            ? _address.text.trim()
                            : [user.district, user.city].where((e) => e.isNotEmpty).join(', '),
                        city: user.city,
                        lat: pos.latitude,
                        lng: pos.longitude,
                        notes: _notes.text.trim(),
                      ),
                    );
                await ref.read(paymentServiceProvider).startCheckout(
                      provider: _pay,
                      amountXaf: _amount,
                      requestId: created.id,
                    );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demande envoyée — recherche d’un collecteur en cours')),
                );
                context.push('/collect/${created.id}');
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Envoi impossible : $e')));
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _step(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _payCard(String asset, String id) {
    final on = _pay == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _pay = id),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: on ? AppColors.primaryGreen : const Color(0xFFE0E0E0), width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: AssetImageBox(asset: asset, height: 36, width: double.infinity, fit: BoxFit.contain, radius: 6),
        ),
      ),
    );
  }
}
