// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  static const Duration _scanDebounceWindow = Duration(seconds: 2);
  bool _isSaving = false;
  bool _isScanningQr = false;
  DateTime? _lastScanAt;
  String? _lastScanCode;
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
          tooltip: 'actions.back'.tr(),
        ),
        title: Text('presence.title'.tr()),
        actions: [
          if (appelAsync.hasValue && appelAsync.value!.appel.statut == 'EN_COURS')
            IconButton(
              icon: _isScanningQr
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded),
              onPressed: _isScanningQr ? null : () => _scannerQr(context),
              tooltip: 'Scanner QR',
            ),
          if (appelAsync.hasValue && appelAsync.value!.appel.statut == 'EN_COURS')
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _cloturerAppel(context),
              tooltip: 'presence.close_call.tooltip'.tr(),
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
              label: Text(
                'presence.save_changes'.tr(
                  namedArgs: {'count': '${localKeys.length}'},
                ),
              ),
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
              ? Center(
                  child: Text('presence.guide.empty_group'.tr()),
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
              'presence.error.title'.tr(),
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
              label: Text('actions.retry'.tr()),
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
        title: Text(
          'presence.guide.note_title'.tr(
            namedArgs: {'name': confirmation.pelerin.nomComplet},
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'presence.note_hint'.tr(),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('actions.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('actions.save'.tr()),
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
      SnackBar(
        content: Text('presence.guide.all_present_success'.tr()),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _reinitialiserAbsents(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('presence.guide.reset_absent_title'.tr()),
        content: Text(
          'presence.guide.reset_absent_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('actions.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('presence.guide.reset_absent_action'.tr()),
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
            content: Text(
              'presence.guide.reset_absent_success'.tr(
                namedArgs: {'count': '$updated'},
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('presence.error.with_message'.tr(namedArgs: {'error': '$e'})),
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
        SnackBar(content: Text('presence.error.data_unavailable'.tr())),
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
        SnackBar(content: Text('presence.guide.no_valid_changes'.tr())),
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
          SnackBar(
            content: Text('presence.guide.save_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('presence.error.with_message'.tr(namedArgs: {'error': '$e'})),
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
        title: Text('presence.close_call.title'.tr()),
        content: Text(
          'presence.close_call.message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('actions.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('presence.close_call.action'.tr()),
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
          SnackBar(
            content: Text('presence.close_call.success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('presence.error.with_message'.tr(namedArgs: {'error': '$e'})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _scannerQr(BuildContext context) async {
    final appelData = ref.read(appelPresenceProvider(widget.appelId)).value;
    if (appelData == null || appelData.appel.statut != 'EN_COURS') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'appel doit être en cours pour scanner.')),
      );
      return;
    }

    final codeUnique = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const _QrScannerScreen(),
      ),
    );

    if (!mounted || codeUnique == null || codeUnique.trim().isEmpty) {
      return;
    }

    final normalizedCode = codeUnique.trim().toUpperCase();
    final now = DateTime.now();
    if (_lastScanCode == normalizedCode &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < _scanDebounceWindow) {
      return;
    }
    _lastScanCode = normalizedCode;
    _lastScanAt = now;

    setState(() => _isScanningQr = true);
    try {
      final repository = ref.read(presenceRepositoryProvider);
      final result = await repository.scanPresenceByQr(
        appelId: widget.appelId,
        codeUnique: codeUnique.trim(),
      );

      ref.invalidate(appelPresenceProvider(widget.appelId));
      _clearLocalChanges();

      if (!mounted) return;
      final message = result['message']?.toString().trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message?.isNotEmpty == true ? message! : 'Présence confirmée par scan QR.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanningQr = false);
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

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    String? code;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        code = raw;
        break;
      }
    }

    if (code == null) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Placez le code QR du pèlerin dans le cadre.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
