import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_constants.dart';
import '../theme/colors.dart';

/// Point affiché sur une [MiniMap] : position, couleur, étiquette optionnelle.
class MapPin {
  const MapPin(this.point, {this.color = AppColors.primaryGreen, this.label, this.icon = Icons.location_on});
  final LatLng point;
  final Color color;
  final String? label;
  final IconData icon;
}

/// Carte OpenStreetMap compacte, arrondie, avec repères numérotés ou colorés
/// et tracé optionnel. Utilisée dans les détails, tournées et tableaux de bord.
class MiniMap extends StatelessWidget {
  const MiniMap({
    super.key,
    required this.pins,
    this.center,
    this.zoom = 13,
    this.height = 180,
    this.radius = 16,
    this.polyline = false,
    this.interactive = true,
    this.overlay,
  });

  final List<MapPin> pins;
  final LatLng? center;
  final double zoom;
  final double height;
  final double radius;
  final bool polyline;
  final bool interactive;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final effectiveCenter = center ?? (pins.isNotEmpty ? pins.first.point : AppConstants.yaounde);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: effectiveCenter,
                initialZoom: zoom,
                interactionOptions: InteractionOptions(
                  flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: AppConstants.osmUserAgent,
                ),
                if (polyline && pins.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: pins.map((p) => p.point).toList(),
                        color: AppColors.primaryGreen,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final pin in pins)
                      Marker(
                        point: pin.point,
                        width: 36,
                        height: 36,
                        alignment: Alignment.topCenter,
                        child: pin.label == null
                            ? Icon(pin.icon, color: pin.color, size: 32)
                            : Container(
                                decoration: BoxDecoration(
                                  color: pin.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  pin.label!,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                      ),
                  ],
                ),
              ],
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}
