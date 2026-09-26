import 'package:drift/drift.dart';

import '../../../domain/attendance_access_invitation.dart';
import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../core/utils/iterable_extensions.dart';
import '../../../services/storage/app_database.dart';

class DriftAttendanceAccessRepository implements AttendanceAccessRepository {
  DriftAttendanceAccessRepository(this._db);
  final AppDatabase _db;

  AttendanceAccessGrant _map(AttendanceAccessGrantRow row) =>
      AttendanceAccessGrant(
        invitationId: row.invitationId,
        sourceTeacherId: row.sourceTeacherId,
        sourceOfferingId: row.sourceOfferingId,
        localOfferingId: row.localOfferingId,
        subject: row.subject,
        sectionCode: row.sectionCode,
        payload: row.payload,
        grantedAt: row.grantedAt,
      );

  @override
  Future<bool> hasAnyAccess() async =>
      (await _db.attendanceAccessDao.getAll()).isNotEmpty;

  @override
  Stream<List<AttendanceAccessGrant>> watchGrants() => _db.attendanceAccessDao
      .watchAll()
      .map((rows) => rows.map(_map).toList(growable: false));

  @override
  Future<AttendanceAccessGrant?> findForOffering(String localOfferingId) async {
    final row = await _db.attendanceAccessDao.byLocalOffering(localOfferingId);
    return row == null ? null : _map(row);
  }

  @override
  Future<AttendanceAccessGrant?> findForSourceOffering(
    String teacherId,
    String sourceOfferingId,
  ) async {
    final row = await _db.attendanceAccessDao.bySourceOffering(
      teacherId,
      sourceOfferingId,
    );
    return row == null ? null : _map(row);
  }

  @override
  Stream<List<Student>> watchRoster(String localOfferingId) =>
      _db.attendanceAccessDao.watchAll().asyncMap((rows) async {
        final row = rows
            .where((grant) => grant.localOfferingId == localOfferingId)
            .firstOrNull;
        return row == null ? const <Student>[] : _roster(row);
      });

  @override
  Future<List<Student>> getRoster(String localOfferingId) async {
    final row = await _db.attendanceAccessDao.byLocalOffering(localOfferingId);
    return row == null ? const [] : _roster(row);
  }

  List<Student> _roster(AttendanceAccessGrantRow row) {
    final invitation = AttendanceAccessInvitation.decode(row.payload);
    return invitation.roster
        .map(
          (source) => Student(
            id: _studentId(row.localOfferingId, source.id),
            updatedAt: row.grantedAt,
            syncStatus: SyncStatus.synced,
            name: source.name,
            studentNumber: source.studentNumber,
            deviceRegistered: source.bleUuid != null,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Device>> getDevices(String localOfferingId) async {
    final row = await _db.attendanceAccessDao.byLocalOffering(localOfferingId);
    if (row == null) return const [];
    final invitation = AttendanceAccessInvitation.decode(row.payload);
    return [
      for (final source in invitation.roster)
        if (source.bleUuid case final uuid?)
          Device(
            id: 'attendance-device-${_studentId(row.localOfferingId, source.id)}',
            updatedAt: row.grantedAt,
            syncStatus: SyncStatus.synced,
            name: source.deviceName ?? 'Registered student device',
            bleUuid: uuid,
            ownerStudentId: _studentId(row.localOfferingId, source.id),
            registeredAt: row.grantedAt,
          ),
    ];
  }

  @override
  Future<AttendanceAccessImportResult> importInvitation(
    AttendanceAccessInvitation invitation,
  ) async {
    final duplicate = await _db.attendanceAccessDao.bySourceOffering(
      invitation.teacherId,
      invitation.offering.id,
    );
    if (duplicate != null) {
      return AttendanceAccessImportResult(
        grant: _map(duplicate),
        invitation: AttendanceAccessInvitation.decode(duplicate.payload),
        alreadyExists: true,
      );
    }
    final reusedId = await _db.attendanceAccessDao.byInvitationId(
      invitation.invitationId,
    );
    if (reusedId != null) {
      throw const FormatException('This attendance QR identifier is invalid.');
    }

    final now = DateTime.now();
    late AttendanceAccessGrantRow saved;
    await _db.transaction(() async {
      var teacher = await (_db.select(
        _db.teachers,
      )..where((row) => row.id.equals(invitation.teacherId))).getSingleOrNull();
      if (teacher == null) {
        await _db.teacherDao.save(
          TeachersCompanion.insert(
            id: invitation.teacherId,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: invitation.teacherName,
            isLocal: const Value(false),
          ),
        );
      } else if (teacher.name != invitation.teacherName) {
        throw const FormatException('The attendance teacher details conflict.');
      }

      final existingClass = await _db.classDao.getClass(invitation.offering.id);
      var localOfferingId = invitation.offering.id;
      if (existingClass != null &&
          (existingClass.teacherId != invitation.teacherId ||
              existingClass.subject != invitation.offering.subject)) {
        localOfferingId = 'attendance-${invitation.invitationId}';
      }
      final sameOffering = await _db.classDao.findOffering(
        invitation.teacherId,
        invitation.offering.sectionCode,
        invitation.offering.subject,
      );
      if (sameOffering != null) localOfferingId = sameOffering.id;
      if (await _db.classDao.getClass(localOfferingId) == null) {
        final offering = invitation.offering;
        final date = DateTime(2000, 1, 1);
        await _db.classDao.insert(
          ClassSectionsCompanion.insert(
            id: localOfferingId,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            gradeLevel: offering.gradeLevel,
            sectionLabel: offering.sectionLabel,
            sectionCode: offering.sectionCode,
            subject: Value(offering.subject),
            room: offering.room,
            scheduleStart: date.add(
              Duration(minutes: offering.startMinutesOfDay),
            ),
            scheduleEnd: date.add(Duration(minutes: offering.endMinutesOfDay)),
            scheduleDays: Value(weekdayMask(offering.scheduleDays)),
            startMinutesOfDay: Value(offering.startMinutesOfDay),
            endMinutesOfDay: Value(offering.endMinutesOfDay),
            bleBeaconId: '',
            teacherId: invitation.teacherId,
          ),
        );
      }

      for (var index = 0; index < invitation.roster.length; index++) {
        final source = invitation.roster[index];
        final id = _studentId(localOfferingId, source.id);
        final existingStudent = await _db.studentDao.getOne(id);
        if (existingStudent == null) {
          await _db.studentDao.insert(
            StudentsCompanion.insert(
              id: id,
              updatedAt: now,
              syncStatus: SyncStatus.synced,
              studentNumber: 'OFFICER-${invitation.invitationId}-$index',
              fullName: source.name,
              isCurrent: const Value(false),
            ),
          );
        }
      }

      await _db.attendanceAccessDao.insert(
        AttendanceAccessGrantsCompanion.insert(
          invitationId: invitation.invitationId,
          sourceTeacherId: invitation.teacherId,
          sourceOfferingId: invitation.offering.id,
          localOfferingId: localOfferingId,
          subject: invitation.offering.subject,
          sectionCode: invitation.offering.sectionCode,
          payload: invitation.encode(),
          grantedAt: now,
        ),
      );
      saved = (await _db.attendanceAccessDao.byInvitationId(
        invitation.invitationId,
      ))!;
    });
    return AttendanceAccessImportResult(
      grant: _map(saved),
      invitation: invitation,
      alreadyExists: false,
    );
  }
}

String _studentId(String localOfferingId, String sourceStudentId) =>
    'attendance:$localOfferingId:$sourceStudentId';
