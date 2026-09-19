import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
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
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 8 || (_registering && _name.text.trim().isEmpty)) {
      return;
    }
    final notifier = ref.read(authProvider.notifier);
    final ok = _registering
        ? await notifier.registerEmail(email, password, _name.text.trim())
        : await notifier.loginEmail(email, password);
    if (!mounted || !ok) return;
    context.go('/home');
  }

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _registering ? 'Inscription' : 'Connexion',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _registering
                          ? 'Créez votre compte Éco-Responsable.'
                          : 'Retrouvez votre espace citoyen.',
                    ),
                  ],
                ),
              ),
              AssetImageBox(asset: AppAssets.logo, height: 72, width: 72, radius: 16),
            ],
          ),
          const SizedBox(height: 28),
          if (_registering) ...[
            const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Ex. Sandrine Tchoua',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text('Adresse email', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'vous@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: '8 caractères minimum',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
            ),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(auth.error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _registering ? 'Créer mon compte' : 'Se connecter',
            icon: _registering ? Icons.arrow_forward : Icons.login,
            loading: auth.loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: auth.loading ? null : () => setState(() => _registering = !_registering),
              child: Text(_registering ? 'J’ai déjà un compte' : 'Créer un nouveau compte'),
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
    );
  }
}
