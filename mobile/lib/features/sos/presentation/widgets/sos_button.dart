import 'dart:async';

import 'package:flutter/material.dart';

class SosHoldButton extends StatefulWidget {
  const SosHoldButton({
    super.key,
    required this.onTriggered,
    this.enabled = true,
    this.loading = false,
  });

  final Future<void> Function() onTriggered;
  final bool enabled;
  final bool loading;

  @override
  State<SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<SosHoldButton> {
  static const _holdDuration = Duration(seconds: 3);
  static const _tick = Duration(milliseconds: 100);

  Timer? _timer;
  double _progress = 0;
  bool _fired = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startHold() {
    if (!widget.enabled || widget.loading || _timer != null) return;

    _fired = false;
    _timer = Timer.periodic(_tick, (timer) async {
      final next = (_progress + (_tick.inMilliseconds / _holdDuration.inMilliseconds))
          .clamp(0.0, 1.0);

      if (mounted) {
        setState(() {
          _progress = next;
        });
      }

      if (next >= 1 && !_fired) {
        _fired = true;
        timer.cancel();
        _timer = null;
        await widget.onTriggered();
        if (mounted) {
          setState(() {
            _progress = 0;
          });
        }
      }
    });
  }

  void _cancelHold() {
    _timer?.cancel();
    _timer = null;
    if (!_fired && mounted && _progress != 0) {
      setState(() {
        _progress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.loading;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => _startHold(),
      onTapUp: disabled ? null : (_) => _cancelHold(),
      onTapCancel: disabled ? null : _cancelHold,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: disabled ? 0.65 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            children: [
              const Text(
                'Maintenez 3 secondes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Une alerte SOS sera envoyee avec votre position.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.25,
                  color: Color(0xFFFDECEC),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.loading) ...[
                const SizedBox(height: 8),
                const Icon(
                  Icons.sync_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: widget.loading ? null : _progress,
                  backgroundColor: const Color(0x40FFFFFF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
