import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _Slide(
                    image: AppAssets.onboarding1,
                    title: 'Éco-Responsable',
                    subtitle: 'Plateforme citoyenne de gestion des déchets • Cameroun',
                    headline: 'Faites de chaque citoyen un acteur de la propreté urbaine',
                  ),
                  _Slide(
                    image: AppAssets.onboarding2,
                    title: 'Signalez',
                    subtitle: 'Décharges sauvages',
                    headline: 'Photographiez un dépôt, géolocalisez-le, suivez sa résolution.',
                  ),
                  _Slide(
                    image: AppAssets.onboarding3,
                    title: 'Gagnez des points',
                    subtitle: 'Tri incitatif',
                    headline: 'Chaque geste compte : points, badges et récompenses Mobile Money.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  width: _index == i ? 18 : 8,
                  height: 8,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _index == i ? AppColors.primaryGreen : AppColors.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: PrimaryButton(
                label: _index < 2 ? 'Continuer' : 'Commencer',
                icon: Icons.arrow_forward,
                onPressed: () {
                  if (_index < 2) {
                    _page.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  } else {
                    context.go('/register');
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton(
                onPressed: () => context.go('/register?login=1'),
                child: const Text('J’ai déjà un compte — Se connecter'),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.headline,
  });

  final String image;
  final String title;
  final String subtitle;
  final String headline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          AssetImageBox(asset: AppAssets.logo, height: 72, width: 72, radius: 36),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryGreen,
            ),
          ),
          Text(
            subtitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, letterSpacing: 0.6, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AssetImageBox(asset: image, width: double.infinity, fit: BoxFit.cover, radius: 28),
                Positioned(
                  right: 12,
                  top: 12,
                  child: AssetImageBox(asset: AppAssets.cameroonFlag, height: 24, width: 36, radius: 4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
