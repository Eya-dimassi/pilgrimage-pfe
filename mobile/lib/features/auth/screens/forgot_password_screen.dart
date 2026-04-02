import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/auth_exception.dart';
import '../domain/auth_validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_feedback.dart';
import '../widgets/auth_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await ref
          .read(authProvider.notifier)
          .forgotPassword(_emailController.text);
      if (!mounted) {
        return;
      }
      showAuthSnackBar(context, message);
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      showAuthSnackBar(context, error.message);
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
    return AuthShell(
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Mot de passe oublie',
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le lien de reinitialisation sera envoye a l adresse associee a votre espace SmartHajj.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.email,
            onFieldSubmitted: (_) {
              if (!_isSubmitting) {
                _submit();
              }
            },
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'nom@test.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.background,
                      ),
                    )
                  : const Text('Envoyer les instructions'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
