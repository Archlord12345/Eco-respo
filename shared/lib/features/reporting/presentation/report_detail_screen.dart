import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/appwrite/appwrite_config.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/mini_map.dart';
import '../../../core/widgets/reward_badge_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../shared/models/collector.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/waste_report.dart';
import '../data/appwrite_report_repository.dart';

final reportByIdProvider = FutureProvider.family<WasteReport, String>((ref, id) {
  return ref.watch(reportRepositoryProvider).getById(id);
});

final collectorByIdProvider = FutureProvider.family<Collector?, String>((ref, id) {
  return ref.watch(collectorRepositoryProvider).byId(id);
});

/// Photo d'un fichier Storage avec repli sur une illustration locale.
class StoragePhoto extends StatelessWidget {
  const StoragePhoto({
    super.key,
    required this.bucketId,
    required this.fileId,
    required this.fallback,
    this.height = 200,
    this.radius = 20,
  });

  final String bucketId;
  final String? fileId;
  final String fallback;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (fileId == null || fileId!.isEmpty) {
      return AssetImageBox(asset: fallback, height: height, width: double.infinity, radius: radius);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        AppwriteConfig.fileViewUrl(bucketId, fileId!),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                height: height,
                color: AppColors.paleGreen,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
        errorBuilder: (_, _, _) =>
            AssetImageBox(asset: fallback, height: height, width: double.infinity, radius: radius),
      ),
    );
  }
}

/// Détail d'un signalement (planche 7, écran 1) : photo, catégorie, urgence,
/// localisation, chronologie du statut et opérateur affecté.
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportByIdProvider(reportId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du signalement'),
        actions: [
          report.maybeWhen(
            data: (r) => IconButton(
              tooltip: 'Ouvrir dans la carte',
              onPressed: () => _openExternalMap(r.lat, r.lng),
              icon: const Icon(Icons.open_in_new),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Signalement introuvable : $e')),
        data: (r) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Stack(
                  children: [
                    StoragePhoto(
                      bucketId: AppwriteConfig.reportPhotosBucket,
                      fileId: r.photoFileId,
                      fallback: AppAssets.reportDetailPhoto,
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Chip(
                        avatar: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: Text(r.photoFileId == null ? 'Sans photo' : 'Photo jointe'),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_title(r), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text(r.reference, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _InfoTile(label: 'Catégorie', value: r.category.labelFr, icon: Icons.delete_outline)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        label: 'Urgence',
                        value: r.urgency.labelFr,
                        icon: Icons.priority_high,
                        color: _urgencyColor(r.urgency),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoTile(
                  label: 'Localisation',
                  value: r.address.isEmpty ? r.city : '${r.address}, ${r.city}',
                  hint: '${r.lat.toStringAsFixed(4)}° N, ${r.lng.toStringAsFixed(4)}° E',
                  icon: Icons.place_outlined,
                  onTap: () => context.go('/map'),
                ),
                const SizedBox(height: 12),
                if (r.lat != 0 && r.lng != 0)
                  MiniMap(
                    pins: [MapPin(LatLng(r.lat, r.lng), color: AppColors.danger)],
                    zoom: 15,
                    height: 160,
                    interactive: false,
                    overlay: Positioned(
                      right: 10,
                      bottom: 10,
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.go('/map'),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text('Voir sur la carte'),
                      ),
                    ),
                  ),
                if (r.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(r.description, style: const TextStyle(color: AppColors.textDark)),
                ],
                const SizedBox(height: 20),
                const Text('Suivi du statut', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _Timeline(report: r),
                const SizedBox(height: 20),
                const Text('Informations de l’opérateur', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (r.assignedOperatorId == null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_bottom, color: AppColors.earthOchre),
                        SizedBox(width: 10),
                        Expanded(child: Text('En attente d’affectation par la municipalité.')),
                      ],
                    ),
                  )
                else
                  ref.watch(collectorByIdProvider(r.assignedOperatorId!)).when(
                        data: (c) => _OperatorCard(
                          name: c == null
                              ? 'Opérateur ${r.assignedOperatorId}'
                              : (c.company.isNotEmpty ? c.company : c.displayName),
                          phone: c?.phone ?? '',
                          interventions: c?.interventionsCount ?? 0,
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => _OperatorCard(name: 'Opérateur ${r.assignedOperatorId}', phone: '', interventions: 0),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(WasteReport r) => switch (r.category) {
        WasteCategory.menager => 'Dépôt sauvage d’ordures',
        WasteCategory.plastique => 'Déchets plastiques',
        WasteCategory.electronique => 'Déchets électroniques',
        WasteCategory.encombrant => 'Encombrants abandonnés',
      };

  Color _urgencyColor(Urgency u) => switch (u) {
        Urgency.faible => AppColors.primaryGreen,
        Urgency.moyen => AppColors.earthOchre,
        Urgency.eleve => AppColors.warning,
        Urgency.critique => AppColors.danger,
      };

  Future<void> _openExternalMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (color ?? AppColors.primaryGreen).withValues(alpha: .12),
                child: Icon(icon, size: 18, color: color ?? AppColors.primaryGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    if (hint != null) Text(hint!, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.report});
  final WasteReport report;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM y, HH:mm', 'fr');
    final steps = [
      (ReportStatus.reported, 'Signalé', fmt.format(report.createdAt), 'Votre signalement a été enregistré.'),
      (
        ReportStatus.inProgress,
        'Pris en charge',
        report.status.index >= ReportStatus.inProgress.index && report.updatedAt != null
            ? fmt.format(report.updatedAt!)
            : 'À venir',
        'L’opérateur est notifié et se déplace.'
      ),
      (
        ReportStatus.resolved,
        'Résolu',
        report.resolvedAt != null ? fmt.format(report.resolvedAt!) : 'À venir',
        'Le site sera nettoyé et clôturé.'
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(
              done: report.status.index >= steps[i].$1.index,
              current: report.status == steps[i].$1,
              title: steps[i].$2,
              date: steps[i].$3,
              body: steps[i].$4,
              last: i == steps.length - 1,
            ),
          Align(alignment: Alignment.centerRight, child: StatusBadge(status: report.status)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.done,
    required this.current,
    required this.title,
    required this.date,
    required this.body,
    required this.last,
  });

  final bool done;
  final bool current;
  final String title;
  final String date;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.primaryGreen : AppColors.outline;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 22),
            if (!last) Container(width: 2, height: 36, color: color),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: current ? FontWeight.w700 : FontWeight.w600)),
                Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OperatorCard extends StatelessWidget {
  const _OperatorCard({required this.name, required this.phone, required this.interventions});
  final String name;
  final String phone;
  final int interventions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const AssetImageBox(asset: AppAssets.logo, height: 44, width: 44, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  'Opérateur de collecte agréé · $interventions intervention(s)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton.filledTonal(
              onPressed: () => launchUrl(Uri.parse('tel:$phone')),
              icon: const Icon(Icons.call_outlined),
            ),
        ],
      ),
    );
  }
}
