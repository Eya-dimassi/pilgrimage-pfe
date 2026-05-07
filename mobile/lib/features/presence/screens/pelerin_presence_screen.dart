// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/models/pelerin_presence_call.dart';
import '../providers/presence_provider.dart';

class PelerinPresenceScreen extends ConsumerStatefulWidget {
  const PelerinPresenceScreen({
    super.key,
    this.appelId,
  });

  final String? appelId;

  @override
  ConsumerState<PelerinPresenceScreen> createState() =>
      _PelerinPresenceScreenState();
}

class _PelerinPresenceScreenState extends ConsumerState<PelerinPresenceScreen> {
  bool _isConfirming = false;
  final _noteController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCall = widget.appelId == null
        ? ref.watch(pelerinPresenceActiveProvider)
        : ref.watch(pelerinPresenceByIdProvider(widget.appelId!));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _retourDansApp,
          tooltip: 'Retour',
        ),
        title: const Text('Appel de presence'),
      ),
      body: asyncCall.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _refresh,
                  child: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun appel de presence en cours.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _buildContent(context, data);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PelerinPresenceCall call) {
    final theme = Theme.of(context);
    final canConfirm = call.canConfirm && !_isConfirming;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.appel.groupe.nom,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Guide: ${call.appel.guide.fullName}'),
                const SizedBox(height: 4),
                Text('Statut appel: ${call.appel.statut}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre statut: ${call.confirmation.statut}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optionnelle)',
                    hintText: 'Ex: Je suis a l\'entree du bus',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canConfirm
                        ? () => _confirmerPresence(context, call)
                        : null,
                    icon: _isConfirming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      call.confirmation.isPresent
                          ? 'Deja confirme'
                          : 'Je suis present',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmerPresence(
    BuildContext context,
    PelerinPresenceCall call,
  ) async {
    setState(() => _isConfirming = true);
    try {
      final repository = ref.read(presenceRepositoryProvider);
      await repository.confirmerPresencePelerin(
        confirmationId: call.confirmation.id,
        note: _noteController.text.trim(),
      );

      _refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presence confirmee'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  void _refresh() {
    ref.invalidate(pelerinPresenceActiveProvider);
    if (widget.appelId != null) {
      ref.invalidate(pelerinPresenceByIdProvider(widget.appelId!));
    }
  }

  void _retourDansApp() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }
}
