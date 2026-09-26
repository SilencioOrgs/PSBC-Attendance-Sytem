import 'package:drift/drift.dart';

import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../domain/subject_invitation.dart';
import '../../../services/storage/app_database.dart';

class DriftEnrollmentRepository implements EnrollmentRepository {
  DriftEnrollmentRepository(
    this._database, {
    Future<bool> Function(String studentId)? canEnroll,
  }) : _canEnroll = canEnroll ?? _allowEnrollment;
  final AppDatabase _database;
  final Future<bool> Function(String studentId) _canEnroll;

  static Future<bool> _allowEnrollment(String studentId) async => true;

  @override
  Future<int> addFromInvitation({
    required String studentId,
    required SubjectInvitation invitation,
    required Set<String> selectedOfferingIds,
  }) async {
    if (!await _canEnroll(studentId)) {
      throw const PermissionDeniedException();
    }
    if (await _database.studentDao.getOne(studentId) == null) {
      throw StateError('The student profile is no longer available.');
    }
    if (selectedOfferingIds.isEmpty ||
        !invitation.offerings
            .map((offering) => offering.id)
            .toSet()
            .containsAll(selectedOfferingIds)) {
      throw const FormatException('Select one or more valid subjects.');
    }
    var added = 0;
    final now = DateTime.now();
    await _database.transaction(() async {
      final existingTeacher = await (_database.select(
        _database.teachers,
      )..where((row) => row.id.equals(invitation.teacherId))).getSingleOrNull();
      if (existingTeacher == null) {
        await _database.teacherDao.save(
          TeachersCompanion.insert(
            id: invitation.teacherId,
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: invitation.teacherName,
            isLocal: const Value(false),
          ),
        );
      } else if (existingTeacher.name != invitation.teacherName) {
        throw const FormatException(
          'The teacher details in this invitation do not match.',
        );
      }
      for (final offering in invitation.offerings.where(
        (item) => selectedOfferingIds.contains(item.id),
      )) {
        final existingOffering = await _database.classDao.getClass(offering.id);
        if (existingOffering == null) {
          await _database.classDao.insert(
            ClassSectionsCompanion.insert(
              id: offering.id,
              updatedAt: now,
              syncStatus: SyncStatus.synced,
              gradeLevel: offering.gradeLevel,
              sectionLabel: offering.sectionLabel,
              sectionCode: offering.sectionCode,
              subject: Value(offering.subject),
              room: offering.room,
              scheduleStart: DateTime(
                2000,
                1,
                1,
                offering.startMinutesOfDay ~/ 60,
                offering.startMinutesOfDay % 60,
              ),
              scheduleEnd: DateTime(
                2000,
                1,
                1,
                offering.endMinutesOfDay ~/ 60,
                offering.endMinutesOfDay % 60,
              ),
              scheduleDays: Value(weekdayMask(offering.scheduleDays)),
              startMinutesOfDay: Value(offering.startMinutesOfDay),
              endMinutesOfDay: Value(offering.endMinutesOfDay),
              bleBeaconId: '',
              teacherId: invitation.teacherId,
            ),
          );
        } else if (existingOffering.teacherId != invitation.teacherId) {
          throw const FormatException(
            'A subject identifier in this invitation conflicts with saved data.',
          );
        } else {
          await _database.classDao.updateClass(
            offering.id,
            ClassSectionsCompanion(
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.synced),
              gradeLevel: Value(offering.gradeLevel),
              sectionLabel: Value(offering.sectionLabel),
              sectionCode: Value(offering.sectionCode),
              subject: Value(offering.subject),
              room: Value(offering.room),
              scheduleStart: Value(
                DateTime(
                  2000,
                  1,
                  1,
                  offering.startMinutesOfDay ~/ 60,
                  offering.startMinutesOfDay % 60,
                ),
              ),
              scheduleEnd: Value(
                DateTime(
                  2000,
                  1,
                  1,
                  offering.endMinutesOfDay ~/ 60,
                  offering.endMinutesOfDay % 60,
                ),
              ),
              scheduleDays: Value(weekdayMask(offering.scheduleDays)),
              startMinutesOfDay: Value(offering.startMinutesOfDay),
              endMinutesOfDay: Value(offering.endMinutesOfDay),
            ),
          );
        }
        if (await _database.enrollmentDao.containsPair(
          studentId,
          offering.id,
        )) {
          continue;
        }
        await _database.enrollmentDao.insert(
          EnrollmentsCompanion.insert(
            id: newDatabaseId(),
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            studentId: studentId,
            classSectionId: offering.id,
          ),
        );
        added++;
      }
    });
    return added;
  }
}
