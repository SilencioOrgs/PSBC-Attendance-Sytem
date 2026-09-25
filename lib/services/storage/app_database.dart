import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart' as domain;
import '../../domain/repositories.dart' as domain_repositories;

part 'app_database.g.dart';

Set<domain.Weekday> weekdaysFromMask(int mask) => {
  for (final day in domain.Weekday.values)
    if ((mask & (1 << day.index)) != 0) day,
};

int weekdayMask(Iterable<domain.Weekday> days) =>
    days.fold(0, (mask, day) => mask | (1 << day.index));

class SyncStatusConverter extends TypeConverter<domain.SyncStatus, String> {
  const SyncStatusConverter();
  @override
  domain.SyncStatus fromSql(String fromDb) =>
      domain.SyncStatus.values.byName(fromDb);
  @override
  String toSql(domain.SyncStatus value) => value.name;
}

class SessionStatusConverter
    extends TypeConverter<domain.AttendanceSessionStatus, String> {
  const SessionStatusConverter();
  @override
  domain.AttendanceSessionStatus fromSql(String fromDb) =>
      domain.AttendanceSessionStatus.values.byName(fromDb);
  @override
  String toSql(domain.AttendanceSessionStatus value) => value.name;
}

class RecordStatusConverter
    extends TypeConverter<domain.AttendanceRecordStatus, String> {
  const RecordStatusConverter();
  @override
  domain.AttendanceRecordStatus fromSql(String fromDb) => fromDb == 'unverified'
      ? domain.AttendanceRecordStatus.notDetected
      : domain.AttendanceRecordStatus.values.byName(fromDb);
  @override
  String toSql(domain.AttendanceRecordStatus value) => value.name;
}

abstract class SyncColumns extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
}

@DataClassName('TeacherRow')
class Teachers extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get name => text()();
  BoolColumn get isLocal => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StudentRow')
class Students extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get studentNumber => text().unique()();
  TextColumn get fullName => text()();
  BoolColumn get isCurrent => boolean().withDefault(const Constant(false))();
  TextColumn get declaredSectionCode => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex.sql(
  'CREATE UNIQUE INDEX class_offering_identity_unique '
  'ON class_sections (teacher_id, section_code, lower(subject))',
)
@DataClassName('ClassSectionRow')
class ClassSections extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  IntColumn get gradeLevel => integer()();
  TextColumn get sectionLabel => text()();
  TextColumn get sectionCode => text()();
  TextColumn get subject => text().withDefault(const Constant('General'))();
  TextColumn get room => text()();
  DateTimeColumn get scheduleStart => dateTime()();
  DateTimeColumn get scheduleEnd => dateTime()();
  IntColumn get scheduleDays => integer().withDefault(const Constant(0))();
  IntColumn get startMinutesOfDay =>
      integer().withDefault(const Constant(480))();
  IntColumn get endMinutesOfDay => integer().withDefault(const Constant(540))();
  TextColumn get bleBeaconId => text()();
  TextColumn get teacherId => text().references(Teachers, #id)();
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
  name: 'enrollments_student_class_unique',
  columns: {#studentId, #classSectionId},
  unique: true,
)
@DataClassName('EnrollmentRow')
class Enrollments extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get classSectionId => text().references(ClassSections, #id)();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttendanceSessionRow')
class AttendanceSessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get classSectionId => text().references(ClassSections, #id)();
  TextColumn get title =>
      text().withDefault(const Constant('Attendance session'))();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get scanDurationSeconds =>
      integer().withDefault(const Constant(0))();
  TextColumn get status => text().map(const SessionStatusConverter())();
  BoolColumn get manualOverride =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
  name: 'attendance_records_session_student_unique',
  columns: {#sessionId, #studentId},
  unique: true,
)
@DataClassName('AttendanceRecordRow')
class AttendanceRecords extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get sessionId => text().references(AttendanceSessions, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get status => text().map(const RecordStatusConverter())();
  IntColumn get rssi => integer().nullable()();
  DateTimeColumn get detectedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DeviceRow')
class Devices extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get studentId => text().unique().references(Students, #id)();
  TextColumn get bleUuid => text().unique()();
  TextColumn get deviceModel => text()();
  DateTimeColumn get registeredAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSettingsDataRow')
class AppSettingsRows extends Table {
  @override
  String get tableName => 'app_settings';

  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  TextColumn get singletonKey =>
      text().unique().withDefault(const Constant('settings'))();
  IntColumn get scanDurationSeconds => integer()();
  IntColumn get rssiThreshold => integer()();
  BoolColumn get soundEnabled => boolean()();
  BoolColumn get vibrationEnabled => boolean()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppSessionPreferencesRow')
class AppSessionPreferences extends Table {
  TextColumn get id => text()();
  TextColumn get lastActiveRole =>
      text().withDefault(const Constant('welcome'))();
  TextColumn get activeStudentId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Teachers,
    Students,
    ClassSections,
    Enrollments,
    AttendanceSessions,
    AttendanceRecords,
    Devices,
    AppSettingsRows,
    AppSessionPreferences,
  ],
  daos: [
    TeacherDao,
    StudentDao,
    ClassDao,
    EnrollmentDao,
    AttendanceDao,
    DeviceDao,
    SettingsDao,
    AppSessionDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'classattend'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(students, students.declaredSectionCode);
        await customStatement('''
          UPDATE students
          SET declared_section_code = (
            SELECT class_sections.section_code
            FROM enrollments
            INNER JOIN class_sections
              ON class_sections.id = enrollments.class_section_id
            WHERE enrollments.student_id = students.id
            LIMIT 1
          )
          WHERE declared_section_code IS NULL
        ''');
        await customStatement('''
          DELETE FROM enrollments
          WHERE class_section_id IN (
            SELECT id FROM class_sections
            WHERE subject = 'Awaiting teacher details'
          )
        ''');
        await customStatement('''
          DELETE FROM class_sections
          WHERE subject = 'Awaiting teacher details'
        ''');
        await customStatement('''
          DELETE FROM teachers
          WHERE name = 'Local enrollment metadata'
            AND NOT EXISTS (
              SELECT 1 FROM class_sections
              WHERE class_sections.teacher_id = teachers.id
            )
        ''');
      }
      if (from < 3) {
        await m.alterTable(
          TableMigration(
            classSections,
            newColumns: [
              classSections.scheduleDays,
              classSections.startMinutesOfDay,
              classSections.endMinutesOfDay,
            ],
          ),
        );
        await m.addColumn(teachers, teachers.isLocal);
        await m.addColumn(
          attendanceSessions,
          attendanceSessions.manualOverride,
        );
        await m.createTable(appSessionPreferences);
        for (final row in await select(classSections).get()) {
          await (update(
            classSections,
          )..where((t) => t.id.equals(row.id))).write(
            ClassSectionsCompanion(
              startMinutesOfDay: Value(
                row.scheduleStart.hour * 60 + row.scheduleStart.minute,
              ),
              endMinutesOfDay: Value(
                row.scheduleEnd.hour * 60 + row.scheduleEnd.minute,
              ),
            ),
          );
        }
      }
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}

@DriftAccessor(tables: [Teachers])
class TeacherDao extends DatabaseAccessor<AppDatabase> with _$TeacherDaoMixin {
  TeacherDao(super.db);
  Stream<TeacherRow> watchTeacher() =>
      (select(teachers)
            ..where((t) => t.isLocal.equals(true))
            ..limit(1))
          .watchSingle();
  Future<TeacherRow> getTeacher() =>
      (select(teachers)
            ..where((t) => t.isLocal.equals(true))
            ..limit(1))
          .getSingle();
  Future<TeacherRow?> getTeacherOrNull() =>
      (select(teachers)
            ..where((t) => t.isLocal.equals(true))
            ..limit(1))
          .getSingleOrNull();
  Future<void> save(TeachersCompanion row) =>
      into(teachers).insertOnConflictUpdate(row);
}

@DriftAccessor(tables: [Students, Enrollments, ClassSections, Devices])
class StudentDao extends DatabaseAccessor<AppDatabase> with _$StudentDaoMixin {
  StudentDao(super.db);
  JoinedSelectStatement _identityQuery({String? studentId}) {
    final query = select(
      students,
    ).join([leftOuterJoin(devices, devices.studentId.equalsExp(students.id))]);
    if (studentId != null) query.where(students.id.equals(studentId));
    return query;
  }

  domain.Student _mapIdentity(TypedResult row) {
    final student = row.readTable(students);
    final device = row.readTableOrNull(devices);
    return domain.Student(
      id: student.id,
      updatedAt: student.updatedAt,
      syncStatus: student.syncStatus,
      name: student.fullName,
      studentNumber: student.studentNumber,
      deviceRegistered: device != null,
    );
  }

  Stream<List<domain.Student>> watchAll() =>
      _identityQuery().watch().map((rows) => rows.map(_mapIdentity).toList());
  Future<List<domain.Student>> getAll() =>
      _identityQuery().get().then((rows) => rows.map(_mapIdentity).toList());
  Stream<domain.Student?> watchOne(String id) =>
      _identityQuery(studentId: id)
          .watch()
          .map((rows) => rows.isEmpty ? null : _mapIdentity(rows.first));
  Future<domain.Student?> getOne(String id) async {
    final rows = await _identityQuery(studentId: id).get();
    return rows.isEmpty ? null : _mapIdentity(rows.first);
  }

  Stream<domain.Student?> watchCurrent() =>
      (select(
        students,
      )..where((row) => row.isCurrent.equals(true))).watch().asyncMap(
        (rows) async => rows.isEmpty ? null : getOne(rows.first.id),
      );
  Future<domain.Student?> getCurrent() async {
    final row = await (select(
      students,
    )..where((student) => student.isCurrent.equals(true))).getSingleOrNull();
    return row == null ? null : getOne(row.id);
  }

  Future<domain.Student?> byNumber(String number) async {
    final row = await (select(
      students,
    )..where((t) => t.studentNumber.equals(number))).getSingleOrNull();
    return row == null ? null : getOne(row.id);
  }

  Future<void> insert(StudentsCompanion row) => into(students).insert(row);
  Future<void> upsert(StudentsCompanion row) =>
      into(students).insertOnConflictUpdate(row);
  Future<void> updateStudent(String id, StudentsCompanion values) async =>
      (update(students)..where((row) => row.id.equals(id))).write(values);
  Future<void> setAllNotCurrent() async =>
      (update(students)..where((t) => t.isCurrent.equals(true))).write(
        StudentsCompanion(isCurrent: const Value(false)),
      );
}

@DriftAccessor(
  tables: [
    ClassSections,
    Teachers,
    Enrollments,
    Students,
    Devices,
    AttendanceSessions,
    AttendanceRecords,
  ],
)
class ClassDao extends DatabaseAccessor<AppDatabase> with _$ClassDaoMixin {
  ClassDao(super.db);
  Stream<List<domain.ClassSection>> watchClasses() =>
      (_classCountQuery()..where(teachers.isLocal.equals(true))).watch().map((
        rows,
      ) {
        final grouped = <String, List<TypedResult>>{};
        for (final row in rows) {
          final section = row.readTable(classSections);
          grouped.putIfAbsent(section.id, () => []).add(row);
        }
        return grouped.values.map((group) {
          final section = group.first.readTable(classSections);
          final count = group
              .where((row) => row.readTableOrNull(enrollments) != null)
              .length;
          return _map(section, count);
        }).toList();
      });
  Future<List<domain.ClassSection>> getClasses() async {
    final rows =
        await (_classCountQuery()..where(teachers.isLocal.equals(true))).get();
    final grouped = <String, List<TypedResult>>{};
    for (final row in rows) {
      final offering = row.readTable(classSections);
      grouped.putIfAbsent(offering.id, () => []).add(row);
    }
    return grouped.values.map((group) {
      final offering = group.first.readTable(classSections);
      return _map(
        offering,
        group.where((row) => row.readTableOrNull(enrollments) != null).length,
      );
    }).toList();
  }

  Future<List<domain.ClassSection>> _withCounts(
    List<ClassSectionRow> rows,
  ) async => Future.wait(
    rows.map(
      (row) async => _map(
        row,
        await (select(enrollments)
              ..where((e) => e.classSectionId.equals(row.id)))
            .get()
            .then((e) => e.length),
      ),
    ),
  );
  domain.ClassSection _map(ClassSectionRow row, int count) {
    final code = 'GRADE${row.gradeLevel}-${row.sectionLabel}';
    return domain.ClassSection(
      id: row.id,
      updatedAt: row.updatedAt,
      syncStatus: row.syncStatus,
      name: 'Grade ${row.gradeLevel} - ${row.sectionLabel}',
      subject: row.subject,
      room: row.room,
      schedule: '${_time(row.scheduleStart)} - ${_time(row.scheduleEnd)}',
      studentCount: count,
      gradeLevel: row.gradeLevel,
      sectionLabel: row.sectionLabel,
      sectionCode: code,
      scheduleStart: row.scheduleStart,
      scheduleEnd: row.scheduleEnd,
      scheduleDays: weekdaysFromMask(row.scheduleDays),
      startMinutesOfDay: row.startMinutesOfDay,
      endMinutesOfDay: row.endMinutesOfDay,
      bleBeaconId: row.bleBeaconId,
      teacherId: row.teacherId,
    );
  }

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} ${value.hour < 12 ? 'AM' : 'PM'}';
  }

  Future<domain.ClassSection?> getClass(String id) async {
    final row = await (select(
      classSections,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final count = await (select(
      enrollments,
    )..where((t) => t.classSectionId.equals(id))).get();
    return _map(row, count.length);
  }

  Stream<domain.ClassSection?> watchClass(String id) {
    final query = _classCountQuery()..where(classSections.id.equals(id));
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final section = rows.first.readTable(classSections);
      final count = rows
          .where((row) => row.readTableOrNull(enrollments) != null)
          .length;
      return _map(section, count);
    });
  }

  JoinedSelectStatement _classCountQuery() => select(classSections).join([
    leftOuterJoin(
      enrollments,
      enrollments.classSectionId.equalsExp(classSections.id),
    ),
    innerJoin(teachers, teachers.id.equalsExp(classSections.teacherId)),
  ]);
  Future<domain.ClassSection?> getByCode(String code) async {
    final rows = await (select(
      classSections,
    )..where((t) => t.sectionCode.equals(code))).get();
    return rows.isEmpty ? null : getClass(rows.first.id);
  }

  Future<domain.ClassSection?> findOffering(
    String teacherId,
    String sectionCode,
    String subject,
  ) async {
    final row =
        await (select(classSections)..where(
              (t) =>
                  t.teacherId.equals(teacherId) &
                  t.sectionCode.equals(sectionCode) &
                  t.subject.lower().equals(subject.trim().toLowerCase()),
            ))
            .getSingleOrNull();
    return row == null ? null : getClass(row.id);
  }

  Future<List<domain.ClassSection>> getStudentOfferings(
    String studentId,
  ) async {
    final rows = await (select(classSections).join([
      innerJoin(
        enrollments,
        enrollments.classSectionId.equalsExp(classSections.id),
      ),
    ])..where(enrollments.studentId.equals(studentId))).get();
    final offerings = await _withCounts(
      rows.map((row) => row.readTable(classSections)).toList(),
    );
    offerings.sort(_offeringStartOrder);
    return offerings;
  }

  Stream<List<domain.ClassSection>> watchStudentOfferings(String studentId) =>
      (select(classSections).join([
        innerJoin(
          enrollments,
          enrollments.classSectionId.equalsExp(classSections.id),
        ),
      ])..where(enrollments.studentId.equals(studentId))).watch().asyncMap((
        rows,
      ) async {
        final offerings = await _withCounts(
          rows.map((row) => row.readTable(classSections)).toList(),
        );
        offerings.sort(_offeringStartOrder);
        return offerings;
      });

  int _offeringStartOrder(domain.ClassSection a, domain.ClassSection b) =>
      (a.startMinutesOfDay ?? 0).compareTo(b.startMinutesOfDay ?? 0);

  Stream<domain.ClassSection?> watchByCode(String code) {
    final query = _classCountQuery()
      ..where(classSections.sectionCode.equals(code));
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      return _map(
        rows.first.readTable(classSections),
        rows.where((row) => row.readTableOrNull(enrollments) != null).length,
      );
    });
  }

  Stream<List<domain.Student>> watchStudents(String classId) =>
      _roster(classId).watch().map(
        (rows) => rows.map((row) {
          final student = row.readTable(students);
          final device = row.readTableOrNull(devices);
          return domain.Student(
            id: student.id,
            updatedAt: student.updatedAt,
            syncStatus: student.syncStatus,
            name: student.fullName,
            studentNumber: student.studentNumber,
            deviceRegistered: device != null,
          );
        }).toList(),
      );
  Future<List<domain.Student>> getStudents(String classId) =>
      _roster(classId).get().then(
        (rows) => rows.map((row) {
          final student = row.readTable(students);
          final device = row.readTableOrNull(devices);
          return domain.Student(
            id: student.id,
            updatedAt: student.updatedAt,
            syncStatus: student.syncStatus,
            name: student.fullName,
            studentNumber: student.studentNumber,
            deviceRegistered: device != null,
          );
        }).toList(),
      );
  JoinedSelectStatement _roster(String classId) => select(students).join([
    innerJoin(enrollments, enrollments.studentId.equalsExp(students.id)),
    innerJoin(
      classSections,
      classSections.id.equalsExp(enrollments.classSectionId),
    ),
    leftOuterJoin(devices, devices.studentId.equalsExp(students.id)),
  ])..where(enrollments.classSectionId.equals(classId));
  Future<void> insert(ClassSectionsCompanion row) =>
      into(classSections).insert(row);
  Future<void> upsert(ClassSectionsCompanion row) =>
      into(classSections).insertOnConflictUpdate(row);
  Future<void> updateClass(String id, ClassSectionsCompanion values) async =>
      (update(classSections)..where((row) => row.id.equals(id))).write(values);
  Future<void> deleteClass(String id) async {
    await transaction(() async {
      final sessions = await (select(
        attendanceSessions,
      )..where((row) => row.classSectionId.equals(id))).get();
      for (final session in sessions) {
        await (delete(
          attendanceRecords,
        )..where((row) => row.sessionId.equals(session.id))).go();
      }
      await (delete(
        attendanceSessions,
      )..where((row) => row.classSectionId.equals(id))).go();
      await (delete(
        enrollments,
      )..where((row) => row.classSectionId.equals(id))).go();
      await (delete(classSections)..where((row) => row.id.equals(id))).go();
    });
  }
}

@DriftAccessor(tables: [Enrollments])
class EnrollmentDao extends DatabaseAccessor<AppDatabase>
    with _$EnrollmentDaoMixin {
  EnrollmentDao(super.db);
  Future<void> insert(EnrollmentsCompanion row) =>
      into(enrollments).insert(row);
  Future<bool> containsPair(String studentId, String classId) async =>
      await (select(enrollments)..where(
            (row) =>
                row.studentId.equals(studentId) &
                row.classSectionId.equals(classId),
          ))
          .getSingleOrNull() !=
      null;
  Future<void> upsert(EnrollmentsCompanion row) =>
      into(enrollments).insertOnConflictUpdate(row);
  Future<void> deletePair(String studentId, String classId) async =>
      (delete(enrollments)..where(
            (row) =>
                row.studentId.equals(studentId) &
                row.classSectionId.equals(classId),
          ))
          .go();
}

@DriftAccessor(tables: [AttendanceSessions, AttendanceRecords])
class AttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(super.db);
  domain.AttendanceSession _session(AttendanceSessionRow row) =>
      domain.AttendanceSession(
        id: row.id,
        updatedAt: row.updatedAt,
        syncStatus: row.syncStatus,
        classId: row.classSectionId,
        title: row.title,
        startedAt: row.startedAt,
        status: row.status,
        date: row.date,
        endedAt: row.endedAt,
        scanDurationSeconds: row.scanDurationSeconds,
        manualOverride: row.manualOverride,
      );
  domain.AttendanceRecord _record(AttendanceRecordRow row) =>
      domain.AttendanceRecord(
        id: row.id,
        updatedAt: row.updatedAt,
        syncStatus: row.syncStatus,
        sessionId: row.sessionId,
        studentId: row.studentId,
        isPresent:
            row.status == domain.AttendanceRecordStatus.present ||
            row.status == domain.AttendanceRecordStatus.manualPresent,
        detectedAt: row.detectedAt,
        rssi: row.rssi,
        recordStatus: row.status,
      );
  Future<domain.AttendanceSession?> getSession(String id) async {
    final row = await (select(
      attendanceSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _session(row);
  }

  Stream<domain.AttendanceSession?> watchSession(String id) =>
      (select(attendanceSessions)..where((t) => t.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _session(row));
  Future<List<domain.AttendanceSession>> getSessions() =>
      (select(attendanceSessions)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .get()
          .then((rows) => rows.map(_session).toList());
  Stream<List<domain.AttendanceSession>> watchSessions() =>
      (select(attendanceSessions)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch()
          .map((rows) => rows.map(_session).toList());
  Future<domain.AttendanceSession?> getLatest() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final rows =
        await (select(attendanceSessions)
              ..where(
                (row) =>
                    row.date.isBiggerOrEqualValue(start) &
                    row.date.isSmallerThanValue(end),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
            .get()
            .then((items) => items.map(_session).toList());
    return rows.isEmpty ? null : rows.first;
  }

  Stream<domain.AttendanceSession?> watchLatest() =>
      watchSessions().map((rows) {
        final now = DateTime.now();
        final today = rows.where(
          (row) =>
              row.startedAt.year == now.year &&
              row.startedAt.month == now.month &&
              row.startedAt.day == now.day,
        );
        return today.isEmpty ? null : today.first;
      });
  Future<List<domain.AttendanceRecord>> getRecords(String id) =>
      (select(attendanceRecords)..where((t) => t.sessionId.equals(id)))
          .get()
          .then((rows) => rows.map(_record).toList());
  Stream<List<domain.AttendanceRecord>> watchRecords(String id) =>
      (select(attendanceRecords)..where((t) => t.sessionId.equals(id)))
          .watch()
          .map((rows) => rows.map(_record).toList());
  Future<List<domain.AttendanceRecord>> getStudentRecords(String id) =>
      (select(attendanceRecords)..where((t) => t.studentId.equals(id)))
          .get()
          .then((rows) => rows.map(_record).toList());
  Stream<List<domain.AttendanceRecord>> watchStudentRecords(String id) =>
      (select(attendanceRecords)..where((t) => t.studentId.equals(id)))
          .watch()
          .map((rows) => rows.map(_record).toList());
  Future<void> insertSession(AttendanceSessionsCompanion row) =>
      into(attendanceSessions).insert(row);
  Future<void> insertRecord(AttendanceRecordsCompanion row) =>
      into(attendanceRecords).insert(row);
  Future<void> upsertSession(AttendanceSessionsCompanion row) =>
      into(attendanceSessions).insertOnConflictUpdate(row);
  Future<void> upsertRecord(AttendanceRecordsCompanion row) =>
      into(attendanceRecords).insertOnConflictUpdate(row);
  Future<void> startSession({
    required AttendanceSessionsCompanion session,
    required List<domain.Student> roster,
  }) async {
    await transaction(() async {
      await into(attendanceSessions).insert(session);
      final now = DateTime.now();
      for (final student in roster) {
        await into(attendanceRecords).insert(
          AttendanceRecordsCompanion.insert(
            id: newDatabaseId(),
            updatedAt: now,
            syncStatus: domain.SyncStatus.pendingCreate,
            sessionId: session.id.value,
            studentId: student.id,
            status: domain.AttendanceRecordStatus.notDetected,
          ),
        );
      }
    });
  }

  Future<void> markDetected(
    String sessionId,
    String studentId, {
    int? rssi,
  }) async {
    await transaction(() async {
      final record =
          await (select(attendanceRecords)..where(
                (row) =>
                    row.sessionId.equals(sessionId) &
                    row.studentId.equals(studentId),
              ))
              .getSingleOrNull();
      if (record == null ||
          record.status == domain.AttendanceRecordStatus.manualPresent ||
          record.status == domain.AttendanceRecordStatus.manualAbsent ||
          record.status == domain.AttendanceRecordStatus.absent) {
        return;
      }
      final now = DateTime.now();
      await (update(
        attendanceRecords,
      )..where((row) => row.id.equals(record.id))).write(
        AttendanceRecordsCompanion(
          status: const Value(domain.AttendanceRecordStatus.present),
          detectedAt: Value(now),
          rssi: Value(rssi),
          updatedAt: Value(now),
          syncStatus: const Value(domain.SyncStatus.pendingUpdate),
        ),
      );
    });
  }

  Future<void> finishScan(String id) async {
    await transaction(() async {
      final session = await (select(
        attendanceSessions,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (session == null ||
          session.status != domain.AttendanceSessionStatus.scanning) {
        return;
      }
      final now = DateTime.now();
      await (update(
        attendanceSessions,
      )..where((row) => row.id.equals(id))).write(
        AttendanceSessionsCompanion(
          status: const Value(domain.AttendanceSessionStatus.review),
          endedAt: Value(session.endedAt ?? now),
          updatedAt: Value(now),
          syncStatus: const Value(domain.SyncStatus.pendingUpdate),
        ),
      );
    });
  }

  Future<void> resumeScan(String id) async {
    final now = DateTime.now();
    final changed =
        await (update(attendanceSessions)..where(
              (row) =>
                  row.id.equals(id) &
                  row.status.equals(domain.AttendanceSessionStatus.review.name),
            ))
            .write(
              AttendanceSessionsCompanion(
                status: const Value(domain.AttendanceSessionStatus.scanning),
                endedAt: const Value(null),
                updatedAt: Value(now),
                syncStatus: const Value(domain.SyncStatus.pendingUpdate),
              ),
            );
    if (changed == 0) {
      throw const domain_repositories.NoActiveAttendanceSessionException();
    }
  }

  Future<void> cancelSession(String id) async {
    await transaction(() async {
      final session = await (select(
        attendanceSessions,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (session == null ||
          session.status != domain.AttendanceSessionStatus.scanning &&
              session.status != domain.AttendanceSessionStatus.review) {
        return;
      }
      final now = DateTime.now();
      await (update(
        attendanceSessions,
      )..where((row) => row.id.equals(id))).write(
        AttendanceSessionsCompanion(
          status: const Value(domain.AttendanceSessionStatus.cancelled),
          endedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value(domain.SyncStatus.pendingUpdate),
        ),
      );
    });
  }

  Future<void> completeSession(String id) async {
    await transaction(() async {
      final session = await (select(
        attendanceSessions,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (session == null ||
          session.status != domain.AttendanceSessionStatus.review) {
        throw StateError('This attendance session is not open for review.');
      }
      final rows = await (select(
        attendanceRecords,
      )..where((row) => row.sessionId.equals(id))).get();
      final now = DateTime.now();
      for (final row in rows.where(
        (row) => row.status == domain.AttendanceRecordStatus.notDetected,
      )) {
        await (update(
          attendanceRecords,
        )..where((item) => item.id.equals(row.id))).write(
          AttendanceRecordsCompanion(
            status: const Value(domain.AttendanceRecordStatus.absent),
            updatedAt: Value(now),
            syncStatus: const Value(domain.SyncStatus.pendingUpdate),
          ),
        );
      }
      await (update(
        attendanceSessions,
      )..where((row) => row.id.equals(id))).write(
        AttendanceSessionsCompanion(
          status: const Value(domain.AttendanceSessionStatus.completed),
          endedAt: Value(session.endedAt ?? now),
          updatedAt: Value(now),
          syncStatus: const Value(domain.SyncStatus.pendingUpdate),
        ),
      );
    });
  }

  Future<void> updateRecord(
    String sessionId,
    String studentId,
    domain.AttendanceRecordStatus status, {
    DateTime? detectedAt,
    int? rssi,
  }) async =>
      (update(attendanceRecords)..where(
            (t) =>
                t.sessionId.equals(sessionId) & t.studentId.equals(studentId),
          ))
          .write(
            AttendanceRecordsCompanion(
              status: Value(status),
              detectedAt: Value(detectedAt),
              rssi: Value(rssi),
              updatedAt: Value(DateTime.now()),
              syncStatus: const Value(domain.SyncStatus.pendingUpdate),
            ),
          );
}

@DriftAccessor(tables: [Devices])
class DeviceDao extends DatabaseAccessor<AppDatabase> with _$DeviceDaoMixin {
  DeviceDao(super.db);
  domain.Device _map(DeviceRow row) => domain.Device(
    id: row.id,
    updatedAt: row.updatedAt,
    syncStatus: row.syncStatus,
    name: row.deviceModel,
    deviceModel: row.deviceModel,
    bleUuid: row.bleUuid,
    ownerStudentId: row.studentId,
    registeredAt: row.registeredAt,
  );
  Future<List<domain.Device>> getAll() =>
      select(devices).get().then((rows) => rows.map(_map).toList());
  Stream<List<domain.Device>> watchAll() =>
      select(devices).watch().map((rows) => rows.map(_map).toList());
  Future<domain.Device?> getStudent(String id) async {
    final row = await (select(
      devices,
    )..where((t) => t.studentId.equals(id))).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Stream<domain.Device?> watchStudent(String id) =>
      (select(devices)..where((t) => t.studentId.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _map(row));
  Future<void> insert(DevicesCompanion row) => into(devices).insert(row);
  Future<void> upsert(DevicesCompanion row) =>
      into(devices).insertOnConflictUpdate(row);
  Future<void> updateStudentBleUuid(String studentId, String bleUuid) async =>
      (update(devices)..where((row) => row.studentId.equals(studentId))).write(
        DevicesCompanion(
          bleUuid: Value(bleUuid),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(domain.SyncStatus.pendingUpdate),
        ),
      );
  Future<void> deleteStudentDevice(String studentId) async =>
      (delete(devices)..where((row) => row.studentId.equals(studentId))).go();
}

@DriftAccessor(tables: [AppSettingsRows])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);
  domain.AppSettings _map(AppSettingsDataRow row) => domain.AppSettings(
    id: row.id,
    updatedAt: row.updatedAt,
    syncStatus: row.syncStatus,
    soundEnabled: row.soundEnabled,
    vibrationEnabled: row.vibrationEnabled,
    scanDurationSeconds: row.scanDurationSeconds,
    rssiThreshold: row.rssiThreshold,
  );
  Future<domain.AppSettings?> getSettings() async {
    final row = await select(appSettingsRows).getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Stream<domain.AppSettings?> watchSettings() =>
      select(appSettingsRows)
          .watchSingleOrNull()
          .map((row) => row == null ? null : _map(row));
  Future<void> save(AppSettingsRowsCompanion row) =>
      into(appSettingsRows).insertOnConflictUpdate(row);
}

@DriftAccessor(tables: [AppSessionPreferences])
class AppSessionDao extends DatabaseAccessor<AppDatabase>
    with _$AppSessionDaoMixin {
  AppSessionDao(super.db);

  Future<AppSessionPreferencesRow?> getPreferences() =>
      select(appSessionPreferences).getSingleOrNull();

  Future<void> savePreferences({
    required String lastActiveRole,
    String? activeStudentId,
  }) => into(appSessionPreferences).insertOnConflictUpdate(
    AppSessionPreferencesCompanion.insert(
      id: 'application',
      lastActiveRole: Value(lastActiveRole),
      activeStudentId: Value(activeStudentId),
      updatedAt: DateTime.now(),
    ),
  );
}

String newDatabaseId() => const Uuid().v4();
