import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';
import 'attendance_provider.dart';

enum AttendanceWorkflowState {
  idle,
  preparing,
  scanning,
  paused,
  review,
  finalizing,
  completed,
  cancelled,
  error,
}

class AttendanceWorkflow {
  const AttendanceWorkflow({
    this.state = AttendanceWorkflowState.idle,
    this.progress = 0,
    this.discoveredDevices = const [],
    this.unknownDeviceCount = 0,
    this.sessionId,
    this.error,
  });

  final AttendanceWorkflowState state;
  final double progress;
  final List<Device> discoveredDevices;
  final int unknownDeviceCount;
  final String? sessionId;
  final String? error;

  bool get isScanning => state == AttendanceWorkflowState.scanning;
  bool get isComplete =>
      state == AttendanceWorkflowState.review ||
      state == AttendanceWorkflowState.completed ||
      state == AttendanceWorkflowState.cancelled;
}

final attendanceControllerProvider =
    NotifierProvider<AttendanceController, AttendanceWorkflow>(
      AttendanceController.new,
    );

/// Owns the complete attendance session, scan, review, and finalization flow.
class AttendanceController extends Notifier<AttendanceWorkflow> {
  StreamSubscription<BleScanUpdate>? _subscription;
  final Set<String> _persistedDetections = {};
  bool _finishing = false;

  @override
  AttendanceWorkflow build() {
    ref.onDispose(() => _subscription?.cancel());
    return const AttendanceWorkflow();
  }

  Future<AttendanceSession> prepareSession(String classId) async {
    state = const AttendanceWorkflow(state: AttendanceWorkflowState.preparing);
    try {
      final session = await ref
          .read(attendanceRepositoryProvider)
          .startSession(classId);
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.idle,
        sessionId: session.id,
      );
      _refreshSessionLists(session.id);
      return session;
    } catch (error) {
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.error,
        error: _message(error),
      );
      rethrow;
    }
  }

  Future<void> start(String sessionId) async {
    if (state.isScanning || _finishing) return;
    state = AttendanceWorkflow(
      state: AttendanceWorkflowState.preparing,
      sessionId: sessionId,
    );
    try {
      final session = await ref
          .read(attendanceRepositoryProvider)
          .getSession(sessionId);
      if (session == null) {
        throw const NoActiveAttendanceSessionException();
      }
      if (session.status == AttendanceSessionStatus.scanning &&
          session.endedAt != null) {
        await ref.read(attendanceRepositoryProvider).finishScan(sessionId);
        state = AttendanceWorkflow(
          state: AttendanceWorkflowState.review,
          sessionId: sessionId,
        );
        return;
      }
      final isReviewSession = session.status == AttendanceSessionStatus.review;
      if (!isReviewSession &&
          session.status != AttendanceSessionStatus.scanning) {
        throw StateError('This attendance session is not open for scanning.');
      }
      final roster = await ref
          .read(classRepositoryProvider)
          .getStudents(session.classId);
      if (roster.isEmpty) {
        throw const EmptyClassRosterException();
      }
      final devices = await ref.read(deviceRepositoryProvider).getDevices();
      final settings = await ref.read(settingsRepositoryProvider).getSettings();
      if (isReviewSession) {
        await ref.read(attendanceRepositoryProvider).resumeScan(sessionId);
      }
      _persistedDetections.clear();
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.scanning,
        sessionId: sessionId,
      );
      _subscription = ref
          .read(bleServiceProvider)
          .scan(
            roster,
            registeredDevices: devices,
            timeout: Duration(seconds: settings.scanDurationSeconds),
          )
          .listen(
            (update) => unawaited(_onScanUpdate(sessionId, update)),
            onError: (Object error, StackTrace stackTrace) {
              state = AttendanceWorkflow(
                state: AttendanceWorkflowState.error,
                sessionId: sessionId,
                progress: state.progress,
                discoveredDevices: state.discoveredDevices,
                unknownDeviceCount: state.unknownDeviceCount,
                error: _message(error),
              );
            },
          );
    } catch (error) {
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.error,
        sessionId: sessionId,
        error: _message(error),
      );
    }
  }

  Future<void> _onScanUpdate(String sessionId, BleScanUpdate update) async {
    if (state.sessionId != sessionId ||
        state.state == AttendanceWorkflowState.cancelled) {
      return;
    }
    state = AttendanceWorkflow(
      state: state.state,
      sessionId: sessionId,
      progress: update.progress,
      discoveredDevices: update.discoveredDevices,
      unknownDeviceCount: update.unknownDeviceCount,
      error: state.error,
    );
    for (final device in update.discoveredDevices) {
      final studentId = device.ownerStudentId;
      if (studentId == null || !_persistedDetections.add(studentId)) continue;
      try {
        await ref
            .read(attendanceRepositoryProvider)
            .markDetected(sessionId, studentId, rssi: device.rssi);
      } catch (error) {
        state = AttendanceWorkflow(
          state: AttendanceWorkflowState.error,
          sessionId: sessionId,
          progress: update.progress,
          discoveredDevices: update.discoveredDevices,
          unknownDeviceCount: update.unknownDeviceCount,
          error: _message(error),
        );
        return;
      }
    }
    if (update.isComplete) await stopForReview();
  }

  Future<void> stopForReview() async {
    final sessionId = state.sessionId;
    if (sessionId == null || _finishing) return;
    if (state.state == AttendanceWorkflowState.review) return;
    final scanError = state.error;
    _finishing = true;
    try {
      await ref.read(bleServiceProvider).stopScan();
      await _subscription?.cancel();
      _subscription = null;
      await ref.read(attendanceRepositoryProvider).finishScan(sessionId);
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.review,
        sessionId: sessionId,
        progress: state.progress,
        discoveredDevices: state.discoveredDevices,
        unknownDeviceCount: state.unknownDeviceCount,
        error: scanError,
      );
    } catch (error) {
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.error,
        sessionId: sessionId,
        error: _message(error),
      );
      rethrow;
    } finally {
      _finishing = false;
    }
  }

  Future<void> finalize(String sessionId) async {
    final session = await ref
        .read(attendanceRepositoryProvider)
        .getSession(sessionId);
    if (session?.status != AttendanceSessionStatus.review) {
      throw StateError('Attendance must be reviewed before it is finalized.');
    }
    state = AttendanceWorkflow(
      state: AttendanceWorkflowState.finalizing,
      sessionId: sessionId,
    );
    try {
      await ref.read(attendanceRepositoryProvider).completeSession(sessionId);
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.completed,
        sessionId: sessionId,
      );
      _refreshSessionLists(sessionId);
      ref.invalidate(attendanceRecordsProvider(sessionId));
    } catch (error) {
      state = AttendanceWorkflow(
        state: AttendanceWorkflowState.review,
        sessionId: sessionId,
        error: _message(error),
      );
      rethrow;
    }
  }

  Future<void> cancel(String sessionId) async {
    await ref.read(bleServiceProvider).stopScan();
    await _subscription?.cancel();
    _subscription = null;
    await ref.read(attendanceRepositoryProvider).cancelSession(sessionId);
    state = AttendanceWorkflow(
      state: AttendanceWorkflowState.cancelled,
      sessionId: sessionId,
    );
    _refreshSessionLists(sessionId);
  }

  String _message(Object error) {
    if (error is RepositoryException) return error.message;
    final text = error.toString().toLowerCase();
    if (text.contains('permission')) {
      return 'Bluetooth permission is required for attendance scanning.';
    }
    if (text.contains('off')) {
      return 'Bluetooth is off. Turn on Bluetooth and try again.';
    }
    if (text.contains('unsupported')) {
      return 'Bluetooth Low Energy is unavailable on this device.';
    }
    return 'We could not start Bluetooth scanning. Check Bluetooth and try again.';
  }

  void _refreshSessionLists(String sessionId) {
    ref.invalidate(attendanceHistoryProvider);
    ref.invalidate(todaySessionProvider);
    ref.invalidate(attendanceSessionByIdProvider(sessionId));
  }
}
