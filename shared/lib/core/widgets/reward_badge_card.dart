import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/colors.dart';

class RewardBadgeCard extends StatelessWidget {
  const RewardBadgeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.asset,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final String asset;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.primaryGreen : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        children: [
          Image.asset(asset, package: AppAssets.package, height: 48, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}

/// Image d'asset qui s'adapte à son cadre.
///
/// - Photos ([AppAssets.isPhoto]) : `BoxFit.cover`, bords arrondis.
/// - Illustrations et icônes (fond transparent, marge intégrée) :
///   `BoxFit.contain`, jamais rognées ; [padding] / [background] optionnels.
/// [fit] force un comportement ; [alignment] pilote le recadrage.
/// Le décodage est borné à la taille du cadre (économie mémoire).
class AssetImageBox extends StatelessWidget {
  const AssetImageBox({
    super.key,
    required this.asset,
    this.height,
    this.width,
    this.fit,
    this.radius = 16,
    this.alignment = Alignment.center,
    this.background,
    this.padding,
  });

  final String asset;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final double radius;
  final Alignment alignment;
  final Color? background;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final photo = AppAssets.isPhoto(asset);
    final effectiveFit = fit ?? (photo ? BoxFit.cover : BoxFit.contain);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final h = (height ?? 0).isFinite ? (height ?? 0) : 0.0;
    final w = (width ?? 0).isFinite ? (width ?? 0) : 0.0;
    final side = math.max(h, w);
    final cacheSide = side > 0 ? (side * dpr).ceil() : null;

    Widget image = Image.asset(
      asset,
      package: AppAssets.package,
      height: height,
      width: width,
      fit: effectiveFit,
      alignment: alignment,
      cacheWidth: effectiveFit == BoxFit.contain ? cacheSide : null,
      cacheHeight: effectiveFit == BoxFit.cover ? cacheSide : null,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Container(
        height: height,
        width: width,
        color: AppColors.paleGreen,
        alignment: Alignment.center,
        child: Image.asset(AppAssets.logo, package: AppAssets.package, height: 40, fit: BoxFit.contain),
      ),
    );

    if (effectiveFit == BoxFit.contain) {
      image = Container(
        height: height,
        width: width,
        color: background ?? (photo ? null : Colors.transparent),
        padding: padding ?? EdgeInsets.zero,
        alignment: alignment,
        child: image,
      );
    }

    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}
