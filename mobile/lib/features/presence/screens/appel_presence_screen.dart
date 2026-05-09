// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/appel_presence.dart';
import '../domain/models/confirmation_presence.dart';
import '../providers/presence_provider.dart';
import '../widgets/confirmation_card.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/stats_header.dart';

class AppelPresenceScreen extends ConsumerStatefulWidget {
  final String appelId;
  final String groupeNom;

  const AppelPresenceScreen({
    super.key,
    required this.appelId,
    required this.groupeNom,
  });

  @override
  ConsumerState<AppelPresenceScreen> createState() =>
      _AppelPresenceScreenState();
}

class _AppelPresenceScreenState extends ConsumerState<AppelPresenceScreen> {
  bool _isSaving = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(appelPresenceProvider(widget.appelId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appelAsync = ref.watch(appelPresenceProvider(widget.appelId));
    final localStatuts = ref.watch(localStatutsProvider);
    final localNotes = ref.watch(localNotesProvider);
    final localKeys = {...localStatuts.keys, ...localNotes.keys};
    final hasPendingChanges = localKeys.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _retourDansApp,
          tooltip: 'Retour',
        ),
        title: const Text('Appel de presence'),
        actions: [
          if (appelAsync.hasValue && appelAsync.value!.appel.statut == 'EN_COURS')
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _cloturerAppel(context),
              tooltip: 'Cloturer l\'appel',
            ),
        ],
      ),
      body: appelAsync.when(
        data: (data) => _buildContent(context, data, localStatuts, localNotes),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, error),
      ),
      floatingActionButton: appelAsync.hasValue &&
              appelAsync.value!.appel.statut == 'EN_COURS' &&
              hasPendingChanges
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : () => _sauvegarderPresences(context),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text('Enregistrer (${localKeys.length})'),
            )
          : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppelPresenceData data,
    Map<String, String> localStatuts,
    Map<String, String?> localNotes,
  ) {
    return Column(
      children: [
        StatsHeader(stats: data.stats),
        if (data.appel.statut == 'EN_COURS')
          QuickActionsBar(
            onMarquerTousPresents: () => _marquerTousPresents(context),
            onRelancerAbsents: () => _reinitialiserAbsents(context),
          ),
        Expanded(
          child: data.appel.confirmations.isEmpty
              ? const Center(
                  child: Text('Aucun pelerin dans ce groupe'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: data.appel.confirmations.length,
                  itemBuilder: (context, index) {
                    final confirmation = data.appel.confirmations[index];
                    final statut =
                        localStatuts[confirmation.id] ?? confirmation.statut;
                    final note =
                        localNotes[confirmation.id] ?? confirmation.note;
                    final hasLocalChanges =
                        localStatuts.containsKey(confirmation.id) ||
                            localNotes.containsKey(confirmation.id);

                    return ConfirmationCard(
                      confirmation: confirmation,
                      currentStatut: statut,
                      currentNote: note,
                      hasLocalChanges: hasLocalChanges,
                      onStatutChanged: (newStatut) =>
                          _changerStatut(confirmation.id, newStatut),
                      onNotePressed: () => _ajouterNote(context, confirmation),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(appelPresenceProvider(widget.appelId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _changerStatut(String confirmationId, String statut) {
    ref.read(localStatutsProvider.notifier).update((state) {
      return {...state, confirmationId: statut};
    });
  }

  Future<void> _ajouterNote(
    BuildContext context,
    ConfirmationPresence confirmation,
  ) async {
    final localNotes = ref.read(localNotesProvider);
    final controller = TextEditingController(
      text: localNotes[confirmation.id] ?? confirmation.note ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note - ${confirmation.pelerin.nomComplet}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: Retard 10 min, Malade...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(localNotesProvider.notifier).update((state) {
        final note = result.trim();
        return {...state, confirmation.id: note.isEmpty ? null : note};
      });
    }
  }

  void _marquerTousPresents(BuildContext context) {
    final data = ref.read(appelPresenceProvider(widget.appelId)).value;
    if (data == null) return;

    ref.read(localStatutsProvider.notifier).update((state) {
      final newState = {...state};
      for (final confirmation in data.appel.confirmations) {
        final current = state[confirmation.id] ?? confirmation.statut;
        if (current != 'PRESENT') {
          newState[confirmation.id] = 'PRESENT';
        }
      }
      return newState;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tous les pelerins marques comme PRESENT'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reinitialiserAbsents(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relancer les absents'),
        content: const Text(
          'Les pelerins ABSENT seront remis EN_ATTENTE et recevront une notification de rappel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Relancer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repository = ref.read(presenceRepositoryProvider);
      final result = await repository.reinitialiserAbsents(widget.appelId);
      ref.invalidate(appelPresenceProvider(widget.appelId));
      _clearLocalChanges();

      if (mounted) {
        final updated = result['updated'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$updated absent(s) reinitialise(s) et notifie(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sauvegarderPresences(BuildContext context) async {
    final localStatuts = ref.read(localStatutsProvider);
    final localNotes = ref.read(localNotesProvider);
    final data = ref.read(appelPresenceProvider(widget.appelId)).value;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donnees indisponibles, reessayez.')),
      );
      return;
    }

    final modifications = _buildConfirmationUpdates(
      data: data,
      localStatuts: localStatuts,
      localNotes: localNotes,
    );

    if (modifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune modification valide a enregistrer')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(presenceRepositoryProvider);
      await repository.marquerPresenceBulk(
        appelId: widget.appelId,
        confirmations: modifications,
      );

      ref.invalidate(appelPresenceProvider(widget.appelId));
      _clearLocalChanges();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presences enregistrees avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<Map<String, dynamic>> _buildConfirmationUpdates({
    required AppelPresenceData data,
    required Map<String, String> localStatuts,
    required Map<String, String?> localNotes,
  }) {
    const allowedStatuts = {'PRESENT', 'ABSENT', 'EXCUSE'};
    final byId = <String, ConfirmationPresence>{
      for (final confirmation in data.appel.confirmations)
        confirmation.id: confirmation,
    };
    final keys = {...localStatuts.keys, ...localNotes.keys};
    final updates = <Map<String, dynamic>>[];

    for (final id in keys) {
      final original = byId[id];
      if (original == null) continue;

      final statut = localStatuts[id] ?? original.statut;
      if (!allowedStatuts.contains(statut)) {
        continue;
      }

      final update = <String, dynamic>{
        'confirmationId': id,
        'statut': statut,
      };
      if (localNotes.containsKey(id) && localNotes[id] != null) {
        update['note'] = localNotes[id];
      }
      updates.add(update);
    }

    return updates;
  }

  Future<void> _cloturerAppel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cloturer l\'appel'),
        content: const Text(
          'Etes-vous sur de vouloir cloturer cet appel de presence ?\n\n'
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cloturer'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final repository = ref.read(presenceRepositoryProvider);
      await repository.cloturerAppel(widget.appelId);
      ref.invalidate(appelPresenceProvider(widget.appelId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appel cloture avec succes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearLocalChanges() {
    ref.read(localStatutsProvider.notifier).state = {};
    ref.read(localNotesProvider.notifier).state = {};
  }

  void _retourDansApp() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }

    final role = ref.read(authProvider).valueOrNull?.user.role;
    switch (role) {
      case 'GUIDE':
        context.go('/guide-home');
        break;
      case 'FAMILLE':
        context.go('/famille-home');
        break;
      case 'PELERIN':
      default:
        context.go('/home');
        break;
    }
  }
}
