import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';
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
  });

  final double progress;
  final List<Device> discoveredDevices;
  final bool isScanning;
  final bool isComplete;
  final String? sessionId;

  BleScanState copyWith({
    double? progress,
    List<Device>? discoveredDevices,
    bool? isScanning,
    bool? isComplete,
    String? sessionId,
  }) => BleScanState(
    progress: progress ?? this.progress,
    discoveredDevices: discoveredDevices ?? this.discoveredDevices,
    isScanning: isScanning ?? this.isScanning,
    isComplete: isComplete ?? this.isComplete,
    sessionId: sessionId ?? this.sessionId,
  );
}

/// Owns BLE scan side effects and finalizes attendance through its repository.
class BleScanController extends Notifier<BleScanState> {
  StreamSubscription<BleScanUpdate>? _subscription;
  bool _finalizing = false;

  @override
  BleScanState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const BleScanState();
  }

  Future<void> start(String sessionId) async {
    if (state.isScanning || _finalizing) return;
    final session = await ref.read(
      attendanceSessionByIdProvider(sessionId).future,
    );
    if (session == null) return;
    final roster = await ref.read(classRosterProvider(session.classId).future);
    state = BleScanState(isScanning: true, sessionId: sessionId);
    final service = ref.read(bleServiceProvider);
    _subscription = service
        .scan(roster)
        .listen(
          (update) {
            state = state.copyWith(
              progress: update.progress,
              discoveredDevices: update.discoveredDevices,
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            state = state.copyWith(isScanning: false);
          },
          onDone: () => unawaited(_finalize(sessionId)),
        );
  }

  Future<void> stopAndFinalize() async {
    final sessionId = state.sessionId;
    if (sessionId == null || _finalizing) return;
    await ref.read(bleServiceProvider).stopScan();
    await _subscription?.cancel();
    await _finalize(sessionId);
  }

  Future<void> _finalize(String sessionId) async {
    if (_finalizing) return;
    _finalizing = true;
    await ref.read(bleServiceProvider).stopScan();
    final detectedStudentIds = state.discoveredDevices
        .map((device) => device.ownerStudentId)
        .whereType<String>()
        .toSet();
    await ref
        .read(attendanceRepositoryProvider)
        .finalizeScan(sessionId, detectedStudentIds);
    ref.invalidate(attendanceRecordsProvider(sessionId));
    state = state.copyWith(isScanning: false, isComplete: true);
    _finalizing = false;
  }
}
