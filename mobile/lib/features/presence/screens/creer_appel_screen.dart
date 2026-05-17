import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/presence_provider.dart';
import 'appel_presence_screen.dart';

class CreerAppelScreen extends ConsumerStatefulWidget {
  final String groupeId;
  final String groupeNom;

  const CreerAppelScreen({
    super.key,
    required this.groupeId,
    required this.groupeNom,
  });

  @override
  ConsumerState<CreerAppelScreen> createState() => _CreerAppelScreenState();
}

class _CreerAppelScreenState extends ConsumerState<CreerAppelScreen> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('presence.create.title'.tr()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.how_to_reg_rounded,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'presence.create.heading'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'presence.create.group_label'.tr(
                  namedArgs: {'group': widget.groupeNom},
                ),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'presence.create.description'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCreating ? null : _creerAppel,
                  icon: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline),
                  label: Text(
                    _isCreating
                        ? 'presence.create.creating'.tr()
                        : 'presence.create.action'.tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _creerAppel() async {
    setState(() => _isCreating = true);

    try {
      final repository = ref.read(presenceRepositoryProvider);
      final result = await repository.creerAppel(widget.groupeId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppelPresenceScreen(
              appelId: result['appel']['id'] as String,
              groupeNom: widget.groupeNom,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'presence.error.with_message'.tr(namedArgs: {'error': '$e'}),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
