import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/eco_app_bar.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/reward_item.dart';
import '../../../shared/models/waste_report.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard_admin/presentation/admin_screens.dart' show allReportsProvider;
import '../../reporting/data/appwrite_report_repository.dart';

final zonesProvider = FutureProvider<List<Zone>>((ref) {
  return ref.watch(zoneRepositoryProvider).list();
});

/// Position de l'utilisateur (null si refusée / indisponible).
final userPositionProvider = FutureProvider<LatLng?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 8)),
    );
    return LatLng(p.latitude, p.longitude);
  } catch (_) {
    return null;
  }
});

/// Carte réelle (OpenStreetMap) : points de collecte (zones), signalements
/// ouverts filtrés par type et distance, position de l'utilisateur.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _map = MapController();
  static const _dist = Distance();
  WasteCategory? _filter;
  double _km = 3;
  bool _showReports = true;

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(authProvider).user?.city ?? AppConstants.defaultCity;
    final origin = ref.watch(userPositionProvider).value ?? AppConstants.centerFor(city);
    final zones = ref.watch(zonesProvider).value ?? const <Zone>[];
    final reports = (ref.watch(allReportsProvider).value ?? const <WasteReport>[])
        .where((r) => r.status != ReportStatus.resolved && r.lat != 0 && r.lng != 0)
        .where((r) => _filter == null || r.category == _filter)
        .where((r) => _dist.as(LengthUnit.Kilometer, origin, LatLng(r.lat, r.lng)) <= _km)
        .toList();
    final nearZones = zones
        .map((z) => (z, _dist.as(LengthUnit.Kilometer, origin, LatLng(z.centerLat, z.centerLng))))
        .where((e) => e.$2 <= _km)
        .toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));

    return Scaffold(
      appBar: const EcoAppBar(title: 'Carte des points de collecte', subtitle: 'Ensemble pour un Cameroun plus propre'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(label: const Text('Tous'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                    ...WasteCategory.values.map(
                      (c) => ChoiceChip(label: Text(c.labelFr), selected: _filter == c, onSelected: (_) => setState(() => _filter = c)),
                    ),
                    FilterChip(
                      label: const Text('Signalements'),
                      avatar: const Icon(Icons.campaign_outlined, size: 16),
                      selected: _showReports,
                      onSelected: (v) => setState(() => _showReports = v),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Distance max.'),
                    Expanded(
                      child: Slider(
                        value: _km,
                        min: 1,
                        max: 15,
                        divisions: 14,
                        label: '${_km.round()} km',
                        onChanged: (v) => setState(() => _km = v),
                      ),
                    ),
                    Text('${_km.round()} km', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(initialCenter: origin, initialZoom: 12.8),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: AppConstants.osmUserAgent,
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: origin,
                          radius: _km * 1000,
                          useRadiusInMeter: true,
                          color: AppColors.primaryGreen.withValues(alpha: 0.06),
                          borderColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        for (final (z, _) in nearZones)
                          Marker(
                            point: LatLng(z.centerLat, z.centerLng),
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: Tooltip(
                              message: 'Point de collecte · ${z.district}',
                              child: const Icon(Icons.place, color: AppColors.primaryGreen, size: 34),
                            ),
                          ),
                        if (_showReports)
                          for (final r in reports)
                            Marker(
                              point: LatLng(r.lat, r.lng),
                              width: 30,
                              height: 30,
                              child: GestureDetector(
                                onTap: () => context.push('/report/${r.id}'),
                                child: Tooltip(
                                  message: '${r.category.labelFr} · ${r.urgency.labelFr}',
                                  child: Icon(Icons.warning_amber_rounded, color: _urgency(r.urgency), size: 26),
                                ),
                              ),
                            ),
                        Marker(
                          point: origin,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.institutionalBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'map_locate',
                        onPressed: () {
                          ref.invalidate(userPositionProvider);
                          _map.move(origin, 14);
                        },
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: nearZones.isEmpty
                ? Center(
                    child: Text(
                      zones.isEmpty ? 'Chargement des points de collecte…' : 'Aucun point de collecte à moins de ${_km.round()} km.',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    itemCount: nearZones.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final (z, km) = nearZones[i];
                      return Container(
                        width: 260,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.delete_outline, color: AppColors.primaryGreen),
                          title: Text('Point de collecte – ${z.district}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${_fmtKm(km)} · ${z.collectionFrequency.isEmpty ? city : z.collectionFrequency}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.near_me, color: AppColors.primaryGreen),
                            tooltip: 'Itinéraire',
                            onPressed: () => launchUrl(
                              Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${z.centerLat},${z.centerLng}'),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                          onTap: () => _map.move(LatLng(z.centerLat, z.centerLng), 15),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _fmtKm(double km) => km < 1 ? 'À ${(km * 1000).round()} m' : 'À ${km.toStringAsFixed(1)} km';

  Color _urgency(Urgency u) => switch (u) {
        Urgency.faible => AppColors.primaryGreen,
        Urgency.moyen => AppColors.earthOchre,
        Urgency.eleve => AppColors.warning,
        Urgency.critique => AppColors.danger,
      };
}
