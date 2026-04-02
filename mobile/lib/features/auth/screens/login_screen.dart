import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      showAuthSnackBar(context, error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      showAuthSnackBar(context, 'Une erreur est survenue');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading =
        _isSubmitting || (authState.isLoading && authState.valueOrNull == null);

    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Center(child: _LoginLogoSeal()),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Acces securise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Connexion',
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Accedez a votre espace mobile avec les identifiants qui vous ont ete communiques.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.email,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'nom@test.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (value) => AuthValidators.required(
              value,
              message: 'Veuillez entrer votre mot de passe',
            ),
            onFieldSubmitted: (_) {
              if (!isLoading) {
                _login();
              }
            },
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: 'Votre mot de passe',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed:
                  isLoading ? null : () => context.push('/forgot-password'),
              child: const Text('Mot de passe oublie ?'),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.text,
                disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.4),
                disabledForegroundColor: AppColors.text.withValues(alpha: 0.75),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.text,
                      ),
                    )
                  : const Text('Se connecter'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: isLoading ? null : () => context.push('/family-signup'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                backgroundColor: AppColors.goldSoft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.family_restroom_outlined, size: 18),
              label: const Text('Creer un compte famille'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _LoginLogoSeal extends StatelessWidget {
  const _LoginLogoSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.goldSoft,
            Color(0xFFF4E2A4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FB8962E),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.text,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.mosque_rounded,
                size: 30,
                color: AppColors.goldBright,
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.goldBright,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
