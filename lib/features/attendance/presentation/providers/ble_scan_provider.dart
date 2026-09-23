import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';
import '../../../classes/presentation/providers/class_provider.dart';
import 'attendance_provider.dart';

final bleScanControllerProvider =
    NotifierProvider<BleScanController, BleScanState>(BleScanController.new);

class BleScanState {
  const BleScanState({
    this.progress = 0,
    this.discoveredDevices = const [],
    this.isScanning = false,
    this.isComplete = false,
    this.sessionId,
    this.error,
  });

  final double progress;
  final List<Device> discoveredDevices;
  final bool isScanning;
  final bool isComplete;
  final String? sessionId;
  final String? error;

  BleScanState copyWith({
    double? progress,
    List<Device>? discoveredDevices,
    bool? isScanning,
    bool? isComplete,
    String? sessionId,
    String? error,
  }) => BleScanState(
    progress: progress ?? this.progress,
    discoveredDevices: discoveredDevices ?? this.discoveredDevices,
    isScanning: isScanning ?? this.isScanning,
    isComplete: isComplete ?? this.isComplete,
    sessionId: sessionId ?? this.sessionId,
    error: error,
  );
}

/// Owns BLE scan side effects and finalizes attendance through its repository.
class BleScanController extends Notifier<BleScanState> {
  StreamSubscription<BleScanUpdate>? _subscription;
  bool _finishing = false;
  final Set<String> _persistedDetections = {};

  @override
  BleScanState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const BleScanState();
  }

  Future<void> start(String sessionId) async {
    if (state.isScanning || _finishing) return;
    final session = await ref.read(
      attendanceSessionByIdProvider(sessionId).future,
    );
    if (session == null) {
      state = state.copyWith(error: 'This attendance session is unavailable.');
      return;
    }
    final roster = await ref.read(classRosterProvider(session.classId).future);
    if (roster.isEmpty) {
      state = BleScanState(
        sessionId: sessionId,
        error: 'Add students before scanning attendance.',
      );
      return;
    }
    final devices = await ref.read(deviceRepositoryProvider).getDevices();
    final settings = await ref.read(settingsRepositoryProvider).getSettings();
    _persistedDetections.clear();
    state = BleScanState(isScanning: true, sessionId: sessionId);
    final service = ref.read(bleServiceProvider);
    try {
      _subscription = service
          .scan(
            roster,
            registeredDevices: devices,
            timeout: Duration(seconds: settings.scanDurationSeconds),
          )
          .listen(
            (update) async {
              state = state.copyWith(
                progress: update.progress,
                discoveredDevices: update.discoveredDevices,
              );
              for (final device in update.discoveredDevices) {
                final id = device.ownerStudentId;
                if (id != null && _persistedDetections.add(id)) {
                  await ref
                      .read(attendanceRepositoryProvider)
                      .markDetected(sessionId, id);
                }
              }
              if (update.isComplete) await stopForReview();
            },
            onError: (Object error, StackTrace stackTrace) {
              state = state.copyWith(isScanning: false, error: _message(error));
            },
            onDone: () {
              if (state.isScanning) state = state.copyWith(isScanning: false);
            },
          );
    } catch (error) {
      state = state.copyWith(isScanning: false, error: _message(error));
    }
  }

  Future<void> stopForReview() async {
    final sessionId = state.sessionId;
    if (sessionId == null || _finishing) return;
    if (!state.isScanning) {
      state = state.copyWith(isComplete: true);
      return;
    }
    _finishing = true;
    await ref.read(bleServiceProvider).stopScan();
    await _subscription?.cancel();
    state = state.copyWith(isScanning: false, isComplete: true);
    _finishing = false;
  }

  String _message(Object error) {
    if (error is RepositoryException) return error.message;
    final text = error.toString();
    if (text.contains('permission')) {
      return 'Bluetooth permission is required for attendance scanning.';
    }
    if (text.contains('off')) {
      return 'Bluetooth is off. Turn on Bluetooth and try again.';
    }
    return 'We could not start Bluetooth scanning. Check Bluetooth and try again.';
  }
}
