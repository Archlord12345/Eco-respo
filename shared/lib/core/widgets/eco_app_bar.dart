import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/presentation/notifications_screen.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/reward_badge_card.dart';

class EcoAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const EcoAppBar({
    super.key,
    this.title = 'Éco-Responsable',
    this.subtitle,
    this.showBack = false,
    this.city,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final String? city;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return AppBar(
      automaticallyImplyLeading: showBack,
      titleSpacing: 12,
      title: Row(
        children: [
          AssetImageBox(asset: AppAssets.logoWhite, height: 32, width: 32, radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          if (city != null)
            Row(
              children: [
                const Icon(Icons.place, size: 14),
                Text(city!, style: const TextStyle(fontSize: 12)),
                const Icon(Icons.expand_more, size: 16),
              ],
            ),
          Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: AppAssets.image(AppAssets.avatarPlaceholder),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: const TextStyle(color: AppColors.primaryGreen)),
          ),
      ],
    );
  }
}
