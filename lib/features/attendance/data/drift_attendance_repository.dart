import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/storage/app_database.dart';

class DriftAttendanceRepository implements AttendanceRepository {
  DriftAttendanceRepository(this._db);
  final AppDatabase _db;
  @override
  Future<AttendanceSession> getTodaySession() => _db.attendanceDao.getLatest();
  @override
  Stream<AttendanceSession> watchTodaySession() =>
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
      present ? AttendanceRecordStatus.present : AttendanceRecordStatus.absent,
      detectedAt: changedAt,
      rssi: existing.rssi,
    );
    return existing.copyWith(isPresent: present, detectedAt: changedAt);
  }

  @override
  Future<void> finalizeScan(String sessionId, Set<String> detectedStudentIds) =>
      _db.attendanceDao.completeScan(sessionId, detectedStudentIds);
}
