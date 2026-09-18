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
          Image.asset(asset, height: 48, fit: BoxFit.contain),
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

class AssetImageBox extends StatelessWidget {
  const AssetImageBox({
    super.key,
    required this.asset,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.radius = 16,
  });

  final String asset;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, _, _) => Container(
          height: height,
          width: width,
          color: const Color(0xFFE8F5E9),
          alignment: Alignment.center,
          child: Image.asset(AppAssets.logo, height: 40),
        ),
      ),
    );
  }
}
