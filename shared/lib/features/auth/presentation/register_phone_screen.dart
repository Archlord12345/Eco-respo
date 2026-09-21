import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app/app_target.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/reward_badge_card.dart';
import 'auth_controller.dart';

enum _Step { phone, pin }

/// Inscription / connexion par numéro de téléphone (planche 1, écran 2).
///
/// Aucun SMS n'est envoyé : l'utilisateur crée lui-même son code de connexion
/// à 6 chiffres à l'inscription, puis le ressaisit pour se connecter.
class RegisterPhoneScreen extends ConsumerStatefulWidget {
  const RegisterPhoneScreen({super.key, this.login = false});

  /// `true` : mode connexion (numéro + code existant).
  final bool login;

  @override
  ConsumerState<RegisterPhoneScreen> createState() => _RegisterPhoneScreenState();
}

class _RegisterPhoneScreenState extends ConsumerState<RegisterPhoneScreen> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _pinConfirm = TextEditingController();
  late bool _login = widget.login;
  _Step _step = _Step.phone;
  bool _obscure = true;
  String? _localError;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');
  String get _fullPhone => '${AppConstants.phonePrefix}$_digits';

  void _next() {
    if (_digits.length != 9) {
      setState(() => _localError = 'Saisissez les 9 chiffres de votre numéro.');
      return;
    }
    if (!_login && _name.text.trim().isEmpty) {
      setState(() => _localError = 'Indiquez votre nom.');
      return;
    }
    setState(() {
      _localError = null;
      _step = _Step.pin;
    });
  }

  Future<void> _submit() async {
    final pin = _pin.text;
    if (pin.length != 6) {
      setState(() => _localError = 'Le code doit contenir 6 chiffres.');
      return;
    }
    if (!_login && _pinConfirm.text != pin) {
      setState(() => _localError = 'Les deux codes ne correspondent pas.');
      return;
    }
    if (!_login && RegExp(r'^(\d)\1{5}$').hasMatch(pin)) {
      setState(() => _localError = 'Choisissez un code moins évident (pas 6 fois le même chiffre).');
      return;
    }
    setState(() => _localError = null);
    final notifier = ref.read(authProvider.notifier);
    final ok = _login
        ? await notifier.loginPhone(_fullPhone, pin)
        : await notifier.registerPhone(_fullPhone, pin, name: _name.text.trim());
    if (!mounted || !ok) return;
    if (_login) {
      final role = ref.read(authProvider).user!.role;
      context.go(ref.read(appTargetProvider).homeFor(role));
    } else {
      context.go('/city');
    }
  }

  void _back() {
    ref.read(authProvider.notifier).clearError();
    if (_step == _Step.pin) {
      setState(() {
        _step = _Step.phone;
        _localError = null;
        _pin.clear();
        _pinConfirm.clear();
      });
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final error = _localError ?? auth.error;
    final pinStep = _step == _Step.pin;
    final title = pinStep
        ? (_login ? 'Votre code' : 'Créez votre code')
        : (_login ? 'Connexion' : 'Inscription');
    final subtitle = pinStep
        ? (_login
            ? 'Saisissez le code à 6 chiffres du compte $_fullPhone.'
            : 'Choisissez un code secret à 6 chiffres. Il vous servira à vous connecter — mémorisez-le bien.')
        : (_login ? 'Retrouvez votre espace avec votre numéro.' : 'Créez votre compte avec votre numéro de téléphone.');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textBlack,
        elevation: 0,
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(subtitle),
                      ],
                    ),
                  ),
                  const AssetImageBox(asset: AppAssets.logo, height: 72, width: 72, radius: 16),
                ],
              ),
              const SizedBox(height: 20),
              const Center(child: AssetImageBox(asset: AppAssets.otpPhone, height: 150, width: 190)),
              const SizedBox(height: 20),
              _StepIndicator(step: pinStep ? 1 : 0),
              const SizedBox(height: 20),
              if (!pinStep) ...[
                if (!_login) ...[
                  const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Ex. Sandrine Tchoua', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Numéro de téléphone', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  autofocus: _login,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  onSubmitted: (_) => _next(),
                  decoration: InputDecoration(
                    hintText: '6 XX XX XX XX',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          AssetImageBox(asset: AppAssets.cameroonFlag, height: 16, width: 22, radius: 3),
                          SizedBox(width: 6),
                          Text(AppConstants.phonePrefix, style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
              ] else ...[
                Text(_login ? 'Code à 6 chiffres' : 'Votre code à 6 chiffres', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _PinField(
                  controller: _pin,
                  obscure: _obscure,
                  autofocus: true,
                  onToggle: () => setState(() => _obscure = !_obscure),
                  onSubmitted: _login ? _submit : null,
                ),
                if (!_login) ...[
                  const SizedBox(height: 16),
                  const Text('Confirmez le code', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _PinField(controller: _pinConfirm, obscure: _obscure, onSubmitted: _submit),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.paleGreen, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, color: AppColors.primaryGreen, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ce code n’est jamais envoyé par SMS ni partagé. Ne le communiquez à personne.',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                  child: Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: pinStep ? (_login ? 'Se connecter' : 'Créer mon compte') : 'Continuer',
                icon: pinStep ? (_login ? Icons.login : Icons.check) : Icons.arrow_forward,
                loading: auth.loading,
                onPressed: pinStep ? _submit : _next,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: auth.loading
                      ? null
                      : () => setState(() {
                            _login = !_login;
                            _step = _Step.phone;
                            _localError = null;
                            ref.read(authProvider.notifier).clearError();
                          }),
                  child: Text(_login ? 'Créer un nouveau compte' : 'J’ai déjà un compte'),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: auth.loading
                      ? null
                      : () {
                          ref.read(authProvider.notifier).clearError();
                          context.go('/login');
                        },
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text('Continuer avec un email'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'En continuant, vous acceptez nos Conditions d’utilisation et notre Politique de confidentialité.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.obscure,
    this.autofocus = false,
    this.onToggle,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool autofocus;
  final VoidCallback? onToggle;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: obscure,
      obscuringCharacter: '●',
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      style: const TextStyle(fontSize: 26, letterSpacing: 12, fontWeight: FontWeight.w700),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        hintText: '••••••',
        counterText: '',
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                onPressed: onToggle,
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    Widget dot(int i, String label) => Expanded(
          child: Column(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.primaryGreen : AppColors.outline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 11, color: i <= step ? AppColors.primaryGreen : AppColors.textMuted)),
            ],
          ),
        );
    return Row(children: [dot(0, 'Numéro'), const SizedBox(width: 8), dot(1, 'Code à 6 chiffres')]);
  }
}
