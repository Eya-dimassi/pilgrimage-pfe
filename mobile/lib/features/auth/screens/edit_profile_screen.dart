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
  final List<String> _lienParenteOptions = [
    'Mere',
    'Pere',
    'Frere',
    'Soeur',
    'Epoux',
    'Epouse',
    'Enfant',
    'Autre',
  ];
  bool _isSubmitting = false;
  bool _initialized = false;
  bool _guideDisponible = true;
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
    _guideDisponible = user.disponibilite != 'INDISPONIBLE';
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
      helpText: 'edit_profile.birth_date_picker_help'.tr(),
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
            disponibilite: user.role == 'GUIDE'
                ? (_guideDisponible ? 'DISPONIBLE' : 'INDISPONIBLE')
                : null,
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

      showAuthSnackBar(context, 'edit_profile.success'.tr());
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
      showAuthSnackBar(context, 'edit_profile.generic_error'.tr());
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
              'edit_profile.title'.tr(),
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
              'edit_profile.subtitle'.tr(),
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
                message: 'edit_profile.first_name_required'.tr(),
              ),
              decoration:  InputDecoration(
                labelText: 'edit_profile.first_name'.tr(),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomController,
              textInputAction: TextInputAction.next,
              validator: (value) => AuthValidators.required(
                value,
                message: 'edit_profile.last_name_required'.tr(),
              ),
              decoration:  InputDecoration(
                labelText: 'edit_profile.last_name'.tr(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: AuthValidators.email,
              decoration:  InputDecoration(
                labelText: 'edit_profile.email'.tr(),
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
              decoration:  InputDecoration(
                labelText: 'edit_profile.phone'.tr(),
                hintText: 'edit_profile.phone_hint'.tr(),
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
                        child: Text(_relationLabel(option).tr()),
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
                decoration:  InputDecoration(
                  labelText: 'edit_profile.family_relationship'.tr(),
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
              ),
            ],
            if (isGuide) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialiteController,
                textInputAction: TextInputAction.done,
                decoration:  InputDecoration(
                  labelText: 'edit_profile.specialty'.tr(),
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                value: _guideDisponible,
                onChanged: (value) {
                  setState(() {
                    _guideDisponible = value;
                  });
                },
                // ignore: deprecated_member_use
                activeColor: AppColors.green,
                title:  Text(
                  'edit_profile.available'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                subtitle: Text(
                  _guideDisponible
                      ? 'edit_profile.available_subtitle'.tr()
                      : 'edit_profile.unavailable_subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
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
                  labelText: 'edit_profile.birth_date'.tr(),
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
                decoration:  InputDecoration(
                  labelText: 'edit_profile.nationality'.tr(),
                  prefixIcon: Icon(Icons.public_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroPasseportController,
                textInputAction: TextInputAction.next,
                decoration:  InputDecoration(
                  labelText: 'edit_profile.passport_number'.tr(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _photoUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration:  InputDecoration(
                  labelText: 'edit_profile.photo_url'.tr(),
                  hintText: 'edit_profile.photo_url_hint'.tr(),
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
                    : Text('edit_profile.save'.tr()),
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
  String _relationLabel(String value) {
    switch (value) {
      case 'Mere':
        return 'edit_profile.relationship_options.mother';
      case 'Pere':
        return 'edit_profile.relationship_options.father';
      case 'Frere':
        return 'edit_profile.relationship_options.brother';
      case 'Soeur':
        return 'edit_profile.relationship_options.sister';
      case 'Epoux':
        return 'edit_profile.relationship_options.husband';
      case 'Epouse':
        return 'edit_profile.relationship_options.wife';
      case 'Enfant':
        return 'edit_profile.relationship_options.child';
      default:
        return 'edit_profile.relationship_options.other';
    }
  }
}
