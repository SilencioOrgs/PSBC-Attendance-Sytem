import 'package:drift/drift.dart';

import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/storage/app_database.dart';

class DriftAttendanceRepository implements AttendanceRepository {
  DriftAttendanceRepository(this._db);
  final AppDatabase _db;
  @override
  Future<AttendanceSession> startSession(String classId) async {
    final section = await _db.classDao.getClass(classId);
    if (section == null) throw const ClassSectionNotFoundException();
    final roster = await _db.classDao.getStudents(classId);
    if (roster.isEmpty) throw const EmptyClassRosterException();
    final now = DateTime.now();
    final id = newDatabaseId();
    final session = AttendanceSessionsCompanion.insert(
      id: id,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      classSectionId: classId,
      title: Value(section.name),
      date: DateTime(now.year, now.month, now.day),
      startedAt: now,
      status: AttendanceSessionStatus.scanning,
    );
    await _db.attendanceDao.startSession(session: session, roster: roster);
    final created = await _db.attendanceDao.getSession(id);
    if (created == null) {
      throw StateError('The attendance session was not created.');
    }
    return created;
  }

  @override
  Future<AttendanceSession?> getTodaySession() => _db.attendanceDao.getLatest();
  @override
  Stream<AttendanceSession?> watchTodaySession() =>
      _db.attendanceDao.watchLatest();
  @override
  Future<List<AttendanceSession>> getSessions() =>
      _db.attendanceDao.getSessions();
  @override
  Stream<List<AttendanceSession>> watchSessions() =>
      _db.attendanceDao.watchSessions();
  @override
  Future<AttendanceSession?> getSession(String sessionId) =>
      _db.attendanceDao.getSession(sessionId);
  @override
  Stream<AttendanceSession?> watchSession(String sessionId) =>
      _db.attendanceDao.watchSession(sessionId);
  @override
  Future<List<AttendanceRecord>> getRecords(String sessionId) =>
      _db.attendanceDao.getRecords(sessionId);
  @override
  Stream<List<AttendanceRecord>> watchRecords(String sessionId) =>
      _db.attendanceDao.watchRecords(sessionId);
  @override
  Future<List<AttendanceRecord>> getStudentRecords(String studentId) =>
      _db.attendanceDao.getStudentRecords(studentId);
  @override
  Stream<List<AttendanceRecord>> watchStudentRecords(String studentId) =>
      _db.attendanceDao.watchStudentRecords(studentId);

  @override
  Future<AttendanceRecord> toggleStatus(
    String sessionId,
    String studentId,
  ) async {
    final existing = (await _db.attendanceDao.getRecords(sessionId))
        .where((record) => record.studentId == studentId)
        .firstOrNull;
    if (existing == null) throw StateError('Attendance record was not found.');
    final present = !existing.isPresent;
    final changedAt = present ? DateTime.now() : null;
    await _db.attendanceDao.updateRecord(
      sessionId,
      studentId,
      present
          ? AttendanceRecordStatus.manualPresent
          : AttendanceRecordStatus.manualAbsent,
      detectedAt: changedAt,
      rssi: existing.rssi,
    );
    return existing.copyWith(isPresent: present, detectedAt: changedAt);
  }

  @override
  Future<void> markDetected(String sessionId, String studentId, {int? rssi}) =>
      _db.attendanceDao.markDetected(sessionId, studentId, rssi: rssi);

  @override
  Future<void> finishScan(String sessionId) =>
      _db.attendanceDao.finishScan(sessionId);

  @override
  Future<void> cancelSession(String sessionId) =>
      _db.attendanceDao.cancelSession(sessionId);

  @override
  Future<void> completeSession(String sessionId) =>
      _db.attendanceDao.completeSession(sessionId);
}
