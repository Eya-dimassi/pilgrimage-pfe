import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/notification_feed_refresh_service.dart';
import '../../auth/domain/auth_exception.dart';
import '../../notifications/providers/mobile_notifications_provider.dart';
import '../data/sos_repository.dart';
import '../domain/sos_alert.dart';

final sosControllerProvider =
    AsyncNotifierProvider<SosController, SosAlert?>(SosController.new);

class SosController extends AsyncNotifier<SosAlert?> {
  @override
  Future<SosAlert?> build() async {
    ref.watch(notificationFeedRefreshProvider);
    final repository = ref.read(sosRepositoryProvider);
    return repository.fetchMyActiveSos();
  }

  Future<SosAlert> triggerSos({String? message}) async {
    final currentAlert = state.valueOrNull;
    if (currentAlert?.isActive == true) {
      return currentAlert!;
    }

    final previousState = state;
    state = const AsyncLoading();

    try {
      await _ensureLocationReady();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );

      final repository = ref.read(sosRepositoryProvider);
      final alert = await repository.triggerSos(
        latitude: position.latitude,
        longitude: position.longitude,
        message: message,
      );

      state = AsyncData(alert);
      NotificationFeedRefreshService.instance.bump();
      ref.invalidate(mobileNotificationsProvider);
      return alert;
    } catch (error) {
      state = previousState;
      if (error is AuthException) rethrow;
      throw AuthException(error.toString());
    }
  }

  Future<void> refreshCurrent() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(sosRepositoryProvider);
      return repository.fetchMyActiveSos();
    });
  }

  Future<void> _ensureLocationReady() async {
    final permissionStatus = await Permission.locationWhenInUse.request();
    if (!permissionStatus.isGranted) {
      throw const AuthException(
        'Autorisez la localisation pour envoyer une alerte SOS',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const AuthException(
        'Activez la localisation de votre telephone pour envoyer une alerte SOS',
      );
    }

    LocationPermission geolocatorPermission =
        await Geolocator.checkPermission();
    if (geolocatorPermission == LocationPermission.denied) {
      geolocatorPermission = await Geolocator.requestPermission();
    }

    if (geolocatorPermission == LocationPermission.denied ||
        geolocatorPermission == LocationPermission.deniedForever) {
      throw const AuthException(
        'La permission de localisation est necessaire pour envoyer une alerte SOS',
      );
    }
  }
}
