import 'package:drift/drift.dart';

import '../../../domain/attendance_access_invitation.dart';
import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../core/utils/iterable_extensions.dart';
import '../../../services/storage/app_database.dart';

class DriftAttendanceAccessRepository implements AttendanceAccessRepository {
  DriftAttendanceAccessRepository(this._db);
  final AppDatabase _db;

  AttendanceAccessGrant _map(
    AttendanceAccessGrantRow row,
    AttendanceAccessOfferingRow offering,
  ) => AttendanceAccessGrant(
    invitationId: row.invitationId,
    sourceTeacherId: row.sourceTeacherId,
    sourceOfferingId: offering.sourceOfferingId,
    localOfferingId: offering.localOfferingId,
    subject: offering.subject,
    sectionCode: offering.sectionCode,
    payload: row.payload,
    grantedAt: row.grantedAt,
  );

  @override
  Future<bool> hasAnyAccess() async =>
      (await _db.attendanceAccessDao.getAllOfferings()).isNotEmpty;

  @override
  Stream<List<AttendanceAccessGrant>> watchGrants() => _db.attendanceAccessDao
      .watchAllOfferings()
      .map((rows) => rows.map((entry) => _map(entry.$1, entry.$2)).toList());

  @override
  Future<AttendanceAccessGrant?> findForOffering(String localOfferingId) async {
    final entry = await _db.attendanceAccessDao.offeringByLocal(
      localOfferingId,
    );
    return entry == null ? null : _map(entry.$1, entry.$2);
  }

  @override
  Future<AttendanceAccessGrant?> findForSourceOffering(
    String teacherId,
    String sourceOfferingId,
  ) async {
    final entry = await _db.attendanceAccessDao.offeringBySource(
      teacherId,
      sourceOfferingId,
    );
    return entry == null ? null : _map(entry.$1, entry.$2);
  }

  @override
  Stream<List<Student>> watchRoster(String localOfferingId) =>
      _db.attendanceAccessDao.watchAllOfferings().map((rows) {
        final entry = rows
            .where((item) => item.$2.localOfferingId == localOfferingId)
            .firstOrNull;
        return entry == null ? const <Student>[] : _roster(entry.$1, entry.$2);
      });

  @override
  Future<List<Student>> getRoster(String localOfferingId) async {
    final entry = await _db.attendanceAccessDao.offeringByLocal(
      localOfferingId,
    );
    return entry == null ? const [] : _roster(entry.$1, entry.$2);
  }

  List<Student> _roster(
    AttendanceAccessGrantRow row,
    AttendanceAccessOfferingRow offeringRow,
  ) {
    final invitation = AttendanceAccessInvitation.decode(row.payload);
    final offering = invitation.offerings
        .where((item) => item.offering.id == offeringRow.sourceOfferingId)
        .firstOrNull;
    if (offering == null) return const [];
    final rosterIds = offering.rosterStudentIds.toSet();
    return invitation.roster
        .where((source) => rosterIds.contains(source.id))
        .map(
          (source) => Student(
            id: attendanceAccessStudentId(source.id),
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
    final entry = await _db.attendanceAccessDao.offeringByLocal(
      localOfferingId,
    );
    if (entry == null) return const [];
    final invitation = AttendanceAccessInvitation.decode(entry.$1.payload);
    final offering = invitation.offerings
        .where((item) => item.offering.id == entry.$2.sourceOfferingId)
        .firstOrNull;
    if (offering == null) return const [];
    final rosterIds = offering.rosterStudentIds.toSet();
    return [
      for (final source in invitation.roster)
        if (rosterIds.contains(source.id))
          if (source.bleUuid case final uuid?)
            Device(
              id: 'attendance-device-${attendanceAccessStudentId(source.id)}',
              updatedAt: entry.$1.grantedAt,
              syncStatus: SyncStatus.synced,
              name: source.deviceName ?? 'Registered student device',
              bleUuid: uuid,
              ownerStudentId: attendanceAccessStudentId(source.id),
              registeredAt: entry.$1.grantedAt,
            ),
    ];
  }

  @override
  Future<AttendanceAccessImportResult> importInvitation(
    AttendanceAccessInvitation invitation,
  ) async {
    final validated = AttendanceAccessInvitation.decode(invitation.encode());
    final sameId = await _db.attendanceAccessDao.byInvitationId(
      validated.invitationId,
    );
    if (sameId != null) {
      final savedInvitation = AttendanceAccessInvitation.decode(sameId.payload);
      if (savedInvitation.encode() != validated.encode()) {
        throw const FormatException(
          'This attendance QR identifier is invalid.',
        );
      }
      final existing = await _db.attendanceAccessDao.getAllOfferings();
      final match = existing
          .where((entry) => entry.$1.invitationId == validated.invitationId)
          .firstOrNull;
      if (match == null) {
        throw const FormatException(
          'This attendance QR identifier is invalid.',
        );
      }
      return AttendanceAccessImportResult(
        grant: _map(match.$1, match.$2),
        invitation: savedInvitation,
        alreadyExists: true,
      );
    }

    final existingBySource =
        <String, (AttendanceAccessGrantRow, AttendanceAccessOfferingRow)>{};
    for (final offering in validated.offerings) {
      final existing = await _db.attendanceAccessDao.offeringBySource(
        validated.teacherId,
        offering.offering.id,
      );
      if (existing != null) existingBySource[offering.offering.id] = existing;
    }
    if (existingBySource.length == validated.offerings.length) {
      final existing = existingBySource.values.first;
      return AttendanceAccessImportResult(
        grant: _map(existing.$1, existing.$2),
        invitation: validated,
        alreadyExists: true,
      );
    }

    final now = DateTime.now();
    late AttendanceAccessGrantRow saved;
    late AttendanceAccessOfferingRow firstSavedOffering;
    await _db.transaction(() async {
      final teacher = await (_db.select(
        _db.teachers,
      )..where((row) => row.id.equals(validated.teacherId))).getSingleOrNull();
      if (teacher == null) {
        await _db.teacherDao.save(
          TeachersCompanion.insert(
            id: validated.teacherId,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: validated.teacherName,
            isLocal: const Value(false),
          ),
        );
      } else if (teacher.name != validated.teacherName) {
        throw const FormatException('The attendance teacher details conflict.');
      }

      final localOfferingIds = <String, String>{};
      for (final accessOffering in validated.offerings) {
        final offering = accessOffering.offering;
        final existingAccess = existingBySource[offering.id];
        if (existingAccess != null) {
          localOfferingIds[offering.id] = existingAccess.$2.localOfferingId;
          continue;
        }
        final existingClass = await _db.classDao.getClass(offering.id);
        var localId = offering.id;
        if (existingClass != null &&
            (existingClass.teacherId != validated.teacherId ||
                existingClass.subject != offering.subject)) {
          localId = 'attendance-${validated.invitationId}-${offering.id}';
        }
        final sameOffering = await _db.classDao.findOffering(
          validated.teacherId,
          offering.sectionCode,
          offering.subject,
        );
        if (sameOffering != null) localId = sameOffering.id;
        localOfferingIds[offering.id] = localId;
        if (await _db.classDao.getClass(localId) != null) continue;

        final date = DateTime(2000, 1, 1);
        await _db.classDao.insert(
          ClassSectionsCompanion.insert(
            id: localId,
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
            teacherId: validated.teacherId,
          ),
        );
      }

      final parentAccessOffering = validated.offerings.firstWhere(
        (item) => !existingBySource.containsKey(item.offering.id),
      );
      final firstOffering = parentAccessOffering.offering;
      final firstLocalId = localOfferingIds[firstOffering.id]!;
      await _db.attendanceAccessDao.insert(
        AttendanceAccessGrantsCompanion.insert(
          invitationId: validated.invitationId,
          sourceTeacherId: validated.teacherId,
          sourceOfferingId: firstOffering.id,
          localOfferingId: firstLocalId,
          subject: firstOffering.subject,
          sectionCode: firstOffering.sectionCode,
          payload: validated.encode(),
          grantedAt: now,
        ),
      );
      saved = (await _db.attendanceAccessDao.byInvitationId(
        validated.invitationId,
      ))!;

      for (final accessOffering in validated.offerings) {
        if (existingBySource.containsKey(accessOffering.offering.id)) continue;
        final offering = accessOffering.offering;
        await _db.attendanceAccessDao.insertOffering(
          AttendanceAccessOfferingsCompanion.insert(
            invitationId: validated.invitationId,
            sourceOfferingId: offering.id,
            localOfferingId: localOfferingIds[offering.id]!,
            subject: offering.subject,
            sectionCode: offering.sectionCode,
          ),
        );
      }
      final firstLinked = await _db.attendanceAccessDao.offeringBySource(
        validated.teacherId,
        firstOffering.id,
      );
      firstSavedOffering = firstLinked!.$2;
    });

    return AttendanceAccessImportResult(
      grant: _map(saved, firstSavedOffering),
      invitation: validated,
      alreadyExists: false,
    );
  }
}
