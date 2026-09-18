import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = List.generate(6, (_) => TextEditingController());
  Duration _left = const Duration(minutes: 2, seconds: 34);

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_left.inSeconds > 0) _left -= const Duration(seconds: 1);
      });
      return _left.inSeconds > 0;
    });
  }

  String get _e164 => '${AppConstants.countryCode}${_phone.text.replaceAll(' ', '')}';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textBlack,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/welcome'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inscription', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Entrez votre numéro de téléphone pour créer votre compte.'),
                  ],
                ),
              ),
              AssetImageBox(asset: AppAssets.otpPhone, height: 72, width: 72, radius: 16),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Numéro de téléphone (Cameroun)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AssetImageBox(asset: AppAssets.cameroonFlag, height: 18, width: 28, radius: 3),
                    const SizedBox(width: 6),
                    const Text('+237'),
                    const Icon(Icons.expand_more, size: 16),
                  ],
                ),
              ),
              hintText: '6 93 45 67 89',
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Recevoir le code OTP',
            loading: auth.loading,
            onPressed: () => ref.read(authProvider.notifier).sendOtp(_e164),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OU')),
                Expanded(child: Divider()),
              ],
            ),
          ),
          const Text('Code OTP', style: TextStyle(fontWeight: FontWeight.w600)),
          const Text('Entrez le code à 6 chiffres reçu par SMS'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 48,
                child: TextField(
                  controller: _otp[i],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              );
            }),
          ),
          Row(
            children: [
              Text(
                'Code valable encore ${_left.inMinutes.toString().padLeft(2, '0')}:${(_left.inSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).sendOtp(_e164),
                child: const Text('Renvoyer'),
              ),
            ],
          ),
          if (auth.error != null)
            Text(auth.error!, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Valider',
            loading: auth.loading,
            onPressed: () async {
              final code = _otp.map((c) => c.text).join();
              final ok = await ref.read(authProvider.notifier).verify(code);
                if (!context.mounted) return;
                if (ok) context.go('/city');
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'En continuant, vous acceptez nos Conditions d’utilisation et notre Politique de confidentialité.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
