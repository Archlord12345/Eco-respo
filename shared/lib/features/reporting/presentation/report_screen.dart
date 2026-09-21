import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/eco_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/waste_report.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reporting/data/appwrite_report_repository.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  Uint8List? _photo;
  LatLng _pos = AppConstants.yaounde;
  WasteCategory _cat = WasteCategory.menager;
  Urgency _urg = Urgency.moyen;
  bool _loading = false;
  String? _error;

  Future<void> _pickPhoto() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
      if (x != null) {
        _photo = await x.readAsBytes();
        setState(() {});
      }
    } else {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return;
      final bytes = await files.first.readAsBytes();
      setState(() => _photo = bytes);
    }
  }

  Future<void> _geo() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final p = await Geolocator.getCurrentPosition();
      setState(() => _pos = LatLng(p.latitude, p.longitude));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _geo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EcoAppBar(subtitle: 'Ensemble pour un Cameroun plus propre'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Signaler une décharge sauvage', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const Text('Aidez-nous à garder votre environnement propre en signalant les décharges sauvages près de vous.'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _photo == null
                    ? const AssetImageBox(asset: AppAssets.dumpPhoto, height: 180, width: double.infinity)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_photo!, height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Ajouter une photo', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Text('Position de la décharge', style: TextStyle(fontWeight: FontWeight.w700)),
          const Text('Vous pouvez ajuster le marqueur sur la carte.'),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _pos,
                  initialZoom: 14,
                  onTap: (_, p) => setState(() => _pos = p),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.eco.kf',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: _pos,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.place, color: AppColors.primaryGreen, size: 36),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.place, color: AppColors.primaryGreen, size: 16),
              SizedBox(width: 4),
              Text('Quartier Bastos, Yaoundé, Cameroun'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Catégorie de déchet', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: WasteCategory.values.map((c) {
              final on = _cat == c;
              return ChoiceChip(
                selected: on,
                label: Text(c.labelFr),
                onSelected: (_) => setState(() => _cat = c),
                selectedColor: AppColors.lightGreen,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Niveau d’urgence', style: TextStyle(fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            children: Urgency.values.map((u) {
              final on = _urg == u;
              final color = switch (u) {
                Urgency.faible => AppColors.lightGreen,
                Urgency.moyen => AppColors.earthOchre,
                Urgency.eleve => AppColors.warning,
                Urgency.critique => AppColors.reported,
              };
              return ChoiceChip(
                selected: on,
                label: Text(u.labelFr),
                selectedColor: color,
                onSelected: (_) => setState(() => _urg = u),
              );
            }).toList(),
          ),
          if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Signaler',
            icon: Icons.send,
            loading: _loading,
            onPressed: () async {
              final user = ref.read(authProvider).user;
              if (user == null) return;
              setState(() {
                _loading = true;
                _error = null;
              });
              try {
                String? fileId;
                if (_photo != null) {
                  fileId = await ref.read(storageUploaderProvider).uploadReportPhoto(
                        filename: 'report.jpg',
                        bytes: _photo!,
                      );
                }
                await ref.read(reportRepositoryProvider).create(
                      WasteReport(
                        id: '',
                        authorId: user.id,
                        photoFileId: fileId,
                        lat: _pos.latitude,
                        lng: _pos.longitude,
                        category: _cat,
                        urgency: _urg,
                        status: ReportStatus.reported,
                        createdAt: DateTime.now(),
                        address: '${user.district}, ${user.city}',
                        city: user.city,
                      ),
                    );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signalement envoyé')),
                  );
              } catch (e) {
                setState(() => _error = e.toString());
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
