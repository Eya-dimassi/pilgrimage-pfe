import 'package:easy_localization/easy_localization.dart';
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

class FamilySignupScreen extends ConsumerStatefulWidget {
  const FamilySignupScreen({super.key});

  @override
  ConsumerState<FamilySignupScreen> createState() => _FamilySignupScreenState();
}

class _FamilySignupScreenState extends ConsumerState<FamilySignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _lienParenteOptions = const [
    'Pere',
    'Mere',
    'Frere',
    'Soeur',
    'Epoux',
    'Epouse',
    'Enfant',
    'Autre',
  ];

  String _selectedLienParente = 'Soeur';
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
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
      final message = await ref.read(authProvider.notifier).familySignup(
            nom: _nomController.text,
            prenom: _prenomController.text,
            email: _emailController.text,
            password: _passwordController.text,
            codeUnique: _codeController.text,
            telephone: _telephoneController.text,
            lienParente: _selectedLienParente,
          );

      if (!mounted) {
        return;
      }

      showAuthSnackBar(context, message);
      context.go('/login');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('family_signup.generic_error'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    showAuthSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      leading: IconButton(
        onPressed: () => context.go('/login'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text(
            'family_signup.title'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 24,
              height: 1.14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            'family_signup.subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _prenomController,
            textInputAction: TextInputAction.next,
            validator: (value) => AuthValidators.required(
              value,
              message: 'family_signup.validation.first_name_required'.tr(),
            ),
            decoration: InputDecoration(
              labelText: 'family_signup.first_name'.tr(),
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nomController,
            textInputAction: TextInputAction.next,
            validator: (value) => AuthValidators.required(
              value,
              message: 'family_signup.validation.last_name_required'.tr(),
            ),
            decoration: InputDecoration(
              labelText: 'family_signup.last_name'.tr(),
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.email,
            decoration: InputDecoration(
              labelText: 'family_signup.email'.tr(),
              hintText: 'family_signup.email_hint'.tr(),
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telephoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.internationalPhone,
            decoration: InputDecoration(
              labelText: 'family_signup.phone'.tr(),
              hintText: 'family_signup.phone_hint'.tr(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedLienParente,
            items: _lienParenteOptions
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(_relationshipLabel(option).tr()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedLienParente = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'family_signup.relationship'.tr(),
              prefixIcon: Icon(Icons.family_restroom_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _codeController,
            textInputAction: TextInputAction.next,
            validator: (value) => AuthValidators.required(
              value,
              message: 'family_signup.validation.pilgrim_code_required'.tr(),
            ),
            decoration: InputDecoration(
              labelText: 'family_signup.pilgrim_code'.tr(),
              hintText: 'family_signup.pilgrim_code_hint'.tr(),
              prefixIcon: Icon(Icons.qr_code_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: AuthValidators.password,
            onFieldSubmitted: (_) {
              if (!_isSubmitting) {
                _submit();
              }
            },
            decoration: InputDecoration(
              labelText: 'family_signup.password'.tr(),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.text,
                disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.4),
                disabledForegroundColor: AppColors.text.withValues(alpha: 0.75),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.text,
                      ),
                    )
                  :Text('family_signup.submit'.tr()),
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _relationshipLabel(String value) {
    switch (value) {
      case 'Pere':
        return 'family_signup.relationship_options.father';
      case 'Mere':
        return 'family_signup.relationship_options.mother';
      case 'Frere':
        return 'family_signup.relationship_options.brother';
      case 'Soeur':
        return 'family_signup.relationship_options.sister';
      case 'Epoux':
        return 'family_signup.relationship_options.husband';
      case 'Epouse':
        return 'family_signup.relationship_options.wife';
      case 'Enfant':
        return 'family_signup.relationship_options.child';
      default:
        return 'family_signup.relationship_options.other';
    }
  }
}
