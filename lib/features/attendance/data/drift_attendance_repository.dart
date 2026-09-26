import 'package:drift/drift.dart';

import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../domain/attendance_window_policy.dart';
import '../../../domain/attendance_access_invitation.dart';
import '../../../services/storage/app_database.dart';

class DriftAttendanceRepository implements AttendanceRepository {
  DriftAttendanceRepository(
    this._db, {
    DateTime Function()? clock,
    this._windowPolicy = const AttendanceWindowPolicy(),
    Future<bool> Function(String offeringId)? canAccessOffering,
  }) : _clock = clock ?? DateTime.now,
       _canAccessOffering = canAccessOffering ?? _denyAccess;
  final AppDatabase _db;
  final DateTime Function() _clock;
  final Future<bool> Function(String offeringId) _canAccessOffering;
  final AttendanceWindowPolicy _windowPolicy;

  static Future<bool> _denyAccess(String offeringId) async => false;

  Future<void> _assertAccess(String offeringId) async {
    if (!await _canAccessOffering(offeringId)) {
      throw const AttendancePermissionDeniedException();
    }
  }

  Future<void> _assertSessionAccess(String sessionId) async {
    final session = await _db.attendanceDao.getSession(sessionId);
    if (session == null) throw const NoActiveAttendanceSessionException();
    await _assertAccess(session.classOfferingId);
  }

  @override
  Future<AttendanceSession> startSession(
    String classId, {
    bool manualOverride = false,
  }) async {
    await _assertAccess(classId);
    final activeSession = (await _db.attendanceDao.getSessions())
        .where(
          (session) =>
              session.status == AttendanceSessionStatus.scanning ||
              session.status == AttendanceSessionStatus.review,
        )
        .firstOrNull;
    if (activeSession != null) {
      throw ActiveAttendanceSessionException(activeSession.id);
    }
    final section = await _db.classDao.getClass(classId);
    if (section == null) throw const ClassSectionNotFoundException();
    final now = _clock();
    final window = _windowPolicy.evaluate(section, now);
    if (!window.isScheduled && !manualOverride) {
      throw AttendanceWindowException(window.status);
    }
    final accessGrant = await _db.attendanceAccessDao.byLocalOffering(classId);
    final roster = accessGrant == null
        ? await _db.classDao.getStudents(classId)
        : AttendanceAccessInvitation.decode(accessGrant.payload).roster
              .map(
                (student) => Student(
                  id: _accessStudentId(classId, student.id),
                  updatedAt: accessGrant.grantedAt,
                  syncStatus: SyncStatus.synced,
                  name: student.name,
                  studentNumber: student.studentNumber,
                  deviceRegistered: student.bleUuid != null,
                ),
              )
              .toList(growable: false);
    if (roster.isEmpty) throw const EmptyClassRosterException();
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
      manualOverride: Value(manualOverride),
    );
    await _db.attendanceDao.startSession(session: session, roster: roster);
    final created = await _db.attendanceDao.getSession(id);
    if (created == null) {
      throw StateError('The attendance session was not created.');
    }
    return created;
  }

  @override
  Future<AttendanceSession?> getTodaySession() async {
    final session = await _db.attendanceDao.getLatest();
    if (session == null || !await _canAccessOffering(session.classOfferingId)) {
      return null;
    }
    return session;
  }

  @override
  Stream<AttendanceSession?> watchTodaySession() =>
      _db.attendanceDao.watchLatest().asyncMap((session) async {
        if (session == null ||
            !await _canAccessOffering(session.classOfferingId)) {
          return null;
        }
        return session;
      });
  @override
  Future<List<AttendanceSession>> getSessions() async => [
    for (final session in await _db.attendanceDao.getSessions())
      if (await _canAccessOffering(session.classOfferingId)) session,
  ];
  @override
  Stream<List<AttendanceSession>> watchSessions() =>
      _db.attendanceDao.watchSessions().asyncMap(
        (sessions) async => [
          for (final session in sessions)
            if (await _canAccessOffering(session.classOfferingId)) session,
        ],
      );
  @override
  Future<AttendanceSession?> getSession(String sessionId) async {
    final session = await _db.attendanceDao.getSession(sessionId);
    if (session == null || !await _canAccessOffering(session.classOfferingId)) {
      return null;
    }
    return session;
  }

  @override
  Stream<AttendanceSession?> watchSession(String sessionId) =>
      _db.attendanceDao.watchSession(sessionId).asyncMap((session) async {
        if (session == null ||
            !await _canAccessOffering(session.classOfferingId)) {
          return null;
        }
        return session;
      });
  @override
  Future<List<AttendanceRecord>> getRecords(String sessionId) async {
    await _assertSessionAccess(sessionId);
    return _db.attendanceDao.getRecords(sessionId);
  }

  @override
  Stream<List<AttendanceRecord>> watchRecords(String sessionId) =>
      _db.attendanceDao.watchRecords(sessionId).asyncMap((records) async {
        await _assertSessionAccess(sessionId);
        return records;
      });
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
    await _assertSessionAccess(sessionId);
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
  Future<void> markDetected(
    String sessionId,
    String studentId, {
    int? rssi,
  }) async {
    await _assertSessionAccess(sessionId);
    await _db.attendanceDao.markDetected(sessionId, studentId, rssi: rssi);
  }

  @override
  Future<void> finishScan(String sessionId) async {
    await _assertSessionAccess(sessionId);
    await _db.attendanceDao.finishScan(sessionId);
  }

  @override
  Future<void> resumeScan(String sessionId) async {
    await _assertSessionAccess(sessionId);
    await _db.attendanceDao.resumeScan(sessionId);
  }

  @override
  Future<void> cancelSession(String sessionId) async {
    await _assertSessionAccess(sessionId);
    await _db.attendanceDao.cancelSession(sessionId);
  }

  @override
  Future<void> completeSession(String sessionId) async {
    await _assertSessionAccess(sessionId);
    await _db.attendanceDao.completeSession(sessionId);
  }
}

String _accessStudentId(String localOfferingId, String sourceStudentId) =>
    'attendance:$localOfferingId:$sourceStudentId';
