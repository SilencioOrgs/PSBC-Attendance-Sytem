import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../domain/models.dart';

final todaySessionProvider = StreamProvider<AttendanceSession>(
  (ref) => ref.watch(attendanceRepositoryProvider).watchTodaySession(),
);

final attendanceActionControllerProvider =
    NotifierProvider<AttendanceActionController, bool>(
      AttendanceActionController.new,
    );

class AttendanceActionController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<AttendanceSession> start(String classId) async {
    state = true;
    try {
      return await ref.read(attendanceRepositoryProvider).startSession(classId);
    } finally {
      state = false;
      ref.invalidate(attendanceHistoryProvider);
      ref.invalidate(todaySessionProvider);
    }
  }

  Future<void> complete(String sessionId) async {
    state = true;
    try {
      await ref.read(attendanceRepositoryProvider).completeSession(sessionId);
    } finally {
      state = false;
      ref.invalidate(attendanceHistoryProvider);
      ref.invalidate(attendanceRecordsProvider(sessionId));
    }
  }
}

final attendanceHistoryProvider = StreamProvider<List<AttendanceSession>>(
  (ref) => ref.watch(attendanceRepositoryProvider).watchSessions(),
);

final attendanceSessionByIdProvider =
    StreamProvider.family<AttendanceSession?, String>(
      (ref, sessionId) =>
          ref.watch(attendanceRepositoryProvider).watchSession(sessionId),
    );

final attendanceRosterProvider = StreamProvider.family<List<Student>, String>((
  ref,
  sessionId,
) {
  final sessions = ref.watch(attendanceRepositoryProvider);
  final classes = ref.watch(classRepositoryProvider);
  return sessions
      .watchSession(sessionId)
      .asyncExpand(
        (session) => session == null
            ? Stream.value(const <Student>[])
            : classes.watchStudents(session.classId),
      );
});

final attendanceRecordsProvider =
    AsyncNotifierProvider.family<
      AttendanceRecordsController,
      List<AttendanceRecord>,
      String
    >(AttendanceRecordsController.new);

class AttendanceRecordsController
    extends AsyncNotifier<List<AttendanceRecord>> {
  AttendanceRecordsController(this.sessionId);
  final String sessionId;

  @override
  Future<List<AttendanceRecord>> build() async {
    final repository = ref.read(attendanceRepositoryProvider);
    final initial = await repository.getRecords(sessionId);
    final subscription = repository
        .watchRecords(sessionId)
        .listen(
          (records) => state = AsyncData(records),
          onError: (Object error, StackTrace stackTrace) =>
              state = AsyncError(error, stackTrace),
        );
    ref.onDispose(subscription.cancel);
    return initial;
  }

  Future<void> toggleStudent(String studentId) async {
    await future;
    await ref
        .read(attendanceRepositoryProvider)
        .toggleStatus(sessionId, studentId);
  }
}

final myAttendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final students = ref.watch(studentRepositoryProvider);
  final attendance = ref.watch(attendanceRepositoryProvider);
  return students.watchCurrentStudent().asyncExpand(
    (student) => student == null
        ? Stream.value(const <AttendanceRecord>[])
        : attendance.watchStudentRecords(student.id),
  );
});

final myAttendanceEntriesProvider =
    StreamProvider<List<AttendanceHistoryEntry>>((ref) {
      final students = ref.watch(studentRepositoryProvider);
      final attendance = ref.watch(attendanceRepositoryProvider);
      final classes = ref.watch(classRepositoryProvider);
      return students.watchCurrentStudent().asyncExpand((student) {
        if (student == null) {
          return Stream.value(const <AttendanceHistoryEntry>[]);
        }
        return attendance.watchStudentRecords(student.id).asyncMap((
          records,
        ) async {
          final sessions = await attendance.getSessions();
          final sections = await classes.getClasses();
          final entries = <AttendanceHistoryEntry>[];
          for (final record in records) {
            final session = sessions
                .where((item) => item.id == record.sessionId)
                .firstOrNull;
            if (session == null) continue;
            final section = sections
                .where((item) => item.id == session.classId)
                .firstOrNull;
            if (section != null) {
              entries.add(
                AttendanceHistoryEntry(
                  record: record,
                  session: session,
                  section: section,
                ),
              );
            }
          }
          return entries;
        });
      });
    });

class AttendanceHistoryEntry {
  const AttendanceHistoryEntry({
    required this.record,
    required this.session,
    required this.section,
  });
  final AttendanceRecord record;
  final AttendanceSession session;
  final ClassSection section;
}
