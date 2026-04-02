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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _specialiteController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController();
  final _numeroPasseportController = TextEditingController();
  final _photoUrlController = TextEditingController();
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

  bool _isSubmitting = false;
  bool _initialized = false;
  String _selectedLienParente = 'Autre';
  DateTime? _selectedDateNaissance;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _specialiteController.dispose();
    _dateNaissanceController.dispose();
    _nationaliteController.dispose();
    _numeroPasseportController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _hydrateForm() {
    if (_initialized) {
      return;
    }

    final user = ref.read(authProvider).valueOrNull?.user;
    if (user == null) {
      return;
    }

    _nomController.text = user.nom;
    _prenomController.text = user.prenom;
    _emailController.text = user.email;
    _telephoneController.text = user.telephone ?? '';
    _specialiteController.text = user.specialite ?? '';
    _nationaliteController.text = user.nationalite ?? '';
    _numeroPasseportController.text = user.numeroPasseport ?? '';
    _photoUrlController.text = user.photoUrl ?? '';
    _selectedDateNaissance = user.dateNaissance;
    _dateNaissanceController.text = _formatDate(user.dateNaissance);
    if (user.lienParente != null &&
        _lienParenteOptions.contains(user.lienParente)) {
      _selectedLienParente = user.lienParente!;
    }
    _initialized = true;
  }

  Future<void> _pickDateNaissance() async {
    final initialDate = _selectedDateNaissance ?? DateTime(1990, 1, 1);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Date de naissance',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDateNaissance = pickedDate;
      _dateNaissanceController.text = _formatDate(pickedDate);
    });
  }

  Future<void> _submit() async {
    final user = ref.read(authProvider).valueOrNull?.user;
    if (user == null) {
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authProvider.notifier).updateProfile(
            nom: _nomController.text,
            prenom: _prenomController.text,
            email: _emailController.text,
            telephone: _telephoneController.text,
            lienParente: user.role == 'FAMILLE' ? _selectedLienParente : null,
            specialite:
                user.role == 'GUIDE' ? _specialiteController.text : null,
            dateNaissance:
                user.role == 'PELERIN' ? _selectedDateNaissance : null,
            nationalite:
                user.role == 'PELERIN' ? _nationaliteController.text : null,
            numeroPasseport: user.role == 'PELERIN'
                ? _numeroPasseportController.text
                : null,
            photoUrl: user.role == 'PELERIN' ? _photoUrlController.text : null,
          );

      if (!mounted) {
        return;
      }

      showAuthSnackBar(context, 'Profil mis a jour avec succes');
      context.go(_profilePathForRole(user.role));
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
    final session = ref.watch(authProvider).valueOrNull;
    final user = session?.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    _hydrateForm();
    final isFamily = user.role == 'FAMILLE';
    final isGuide = user.role == 'GUIDE';
    final isPelerin = user.role == 'PELERIN';

    return AuthShell(
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Modifier le profil',
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
            const Text(
              'Mettez a jour vos informations personnelles. Les changements seront visibles immediatement dans votre espace.',
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
                message: 'Veuillez entrer votre prenom',
              ),
              decoration: const InputDecoration(
                labelText: 'Prenom',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomController,
              textInputAction: TextInputAction.next,
              validator: (value) => AuthValidators.required(
                value,
                message: 'Veuillez entrer votre nom',
              ),
              decoration: const InputDecoration(
                labelText: 'Nom',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              textInputAction: isFamily || isGuide || isPelerin
                  ? TextInputAction.next
                  : TextInputAction.done,
              validator: AuthValidators.internationalPhone,
              decoration: const InputDecoration(
                labelText: 'Telephone',
                hintText: '+33 6 12 34 56 78',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            if (isFamily) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedLienParente,
                items: _lienParenteOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
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
                decoration: const InputDecoration(
                  labelText: 'Lien de parente',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
              ),
            ],
            if (isGuide) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialiteController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Specialite',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
              ),
            ],
            if (isPelerin) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateNaissanceController,
                readOnly: true,
                onTap: _pickDateNaissance,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Date de naissance',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: IconButton(
                    onPressed: _pickDateNaissance,
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationaliteController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nationalite',
                  prefixIcon: Icon(Icons.public_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroPasseportController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Numero de passeport',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _photoUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Photo URL',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.text,
                  disabledBackgroundColor:
                      AppColors.gold.withValues(alpha: 0.4),
                  disabledForegroundColor:
                      AppColors.text.withValues(alpha: 0.75),
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
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  String _profilePathForRole(String role) {
    switch (role) {
      case 'GUIDE':
        return '/guide-home?tab=profile';
      case 'FAMILLE':
        return '/famille-home?tab=profile';
      case 'PELERIN':
      default:
        return '/home?tab=profile';
    }
  }
}
