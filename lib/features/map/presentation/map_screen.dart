import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/eco_app_bar.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/reward_item.dart';
import '../../reporting/data/appwrite_report_repository.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  WasteCategory? _filter;
  double _km = 3;

  @override
  Widget build(BuildContext context) {
    final zones = ref.watch(zonesProvider);
    return Scaffold(
      appBar: const EcoAppBar(title: 'Carte des points de collecte', subtitle: 'Ensemble pour un Cameroun plus propre'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trouvez facilement les points de collecte près de chez vous et contribuez au tri sélectif.'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tous'),
                      selected: _filter == null,
                      onSelected: (_) => setState(() => _filter = null),
                    ),
                    ...WasteCategory.values.map(
                      (c) => ChoiceChip(
                        label: Text(c.labelFr),
                        selected: _filter == c,
                        onSelected: (_) => setState(() => _filter = c),
                      ),
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
                        max: 10,
                        divisions: 9,
                        label: '${_km.round()} km',
                        onChanged: (v) => setState(() => _km = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: const MapOptions(initialCenter: AppConstants.yaounde, initialZoom: 12.4),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.eco.kf',
                ),
                zones.when(
                  data: (list) => MarkerLayer(
                    markers: list
                        .map(
                          (z) => Marker(
                            point: LatLng(z.centerLat, z.centerLng),
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.place, color: AppColors.primaryGreen, size: 32),
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const MarkerLayer(markers: []),
                  error: (_, _) => const MarkerLayer(markers: []),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.primaryGreen),
              title: Text('Bac public – Bastos'),
              subtitle: Text('À 350 m • 5 min à pied'),
              trailing: Icon(Icons.near_me, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}

final zonesProvider = FutureProvider<List<Zone>>((ref) {
  return ref.watch(zoneRepositoryProvider).list();
});
