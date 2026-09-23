import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart' as domain;

part 'app_database.g.dart';

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
  domain.AttendanceRecordStatus fromSql(String fromDb) =>
      domain.AttendanceRecordStatus.values.byName(fromDb);
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
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClassSectionRow')
class ClassSections extends Table {
  TextColumn get id => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().map(const SyncStatusConverter())();
  IntColumn get gradeLevel => integer()();
  TextColumn get sectionLabel => text()();
  TextColumn get sectionCode => text().unique()();
  TextColumn get subject => text().withDefault(const Constant('General'))();
  TextColumn get room => text()();
  DateTimeColumn get scheduleStart => dateTime()();
  DateTimeColumn get scheduleEnd => dateTime()();
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
  ],
  daos: [
    TeacherDao,
    StudentDao,
    ClassDao,
    EnrollmentDao,
    AttendanceDao,
    DeviceDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'classattend'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Add one additive migration block per future schema version.
    },
    beforeOpen: (details) async => customStatement('PRAGMA foreign_keys = ON'),
  );
}

@DriftAccessor(tables: [Teachers])
class TeacherDao extends DatabaseAccessor<AppDatabase> with _$TeacherDaoMixin {
  TeacherDao(super.db);
  Stream<TeacherRow> watchTeacher() =>
      (select(teachers)..limit(1)).watchSingle();
  Future<TeacherRow> getTeacher() => (select(teachers)..limit(1)).getSingle();
  Future<TeacherRow?> getTeacherOrNull() =>
      (select(teachers)..limit(1)).getSingleOrNull();
  Future<void> save(TeachersCompanion row) =>
      into(teachers).insertOnConflictUpdate(row);
}

@DriftAccessor(tables: [Students, Enrollments, ClassSections, Devices])
class StudentDao extends DatabaseAccessor<AppDatabase> with _$StudentDaoMixin {
  StudentDao(super.db);
  Selectable<TypedResult> _joined({
    String? studentId,
    bool currentOnly = false,
  }) {
    final query = select(students).join([
      innerJoin(enrollments, enrollments.studentId.equalsExp(students.id)),
      innerJoin(
        classSections,
        classSections.id.equalsExp(enrollments.classSectionId),
      ),
      leftOuterJoin(devices, devices.studentId.equalsExp(students.id)),
    ]);
    if (studentId != null) query.where(students.id.equals(studentId));
    if (currentOnly) query.where(students.isCurrent.equals(true));
    return query;
  }

  domain.Student _map(TypedResult row) {
    final student = row.readTable(students);
    final section = row.readTable(classSections);
    final device = row.readTableOrNull(devices);
    return domain.Student(
      id: student.id,
      updatedAt: student.updatedAt,
      syncStatus: student.syncStatus,
      name: student.fullName,
      studentNumber: student.studentNumber,
      classId: section.id,
      gradeLevel: 'Grade ${section.gradeLevel}',
      deviceRegistered: device != null,
    );
  }

  Stream<List<domain.Student>> watchAll() =>
      _joined().watch().map((rows) => rows.map(_map).toList());
  Future<List<domain.Student>> getAll() =>
      _joined().get().then((rows) => rows.map(_map).toList());
  Stream<domain.Student?> watchOne(String id) =>
      _joined(studentId: id)
          .watch()
          .map((rows) => rows.isEmpty ? null : _map(rows.first));
  Future<domain.Student?> getOne(String id) async {
    final rows = await _joined(studentId: id).get();
    return rows.isEmpty ? null : _map(rows.first);
  }

  Stream<domain.Student?> watchCurrent() =>
      _joined(currentOnly: true)
          .watch()
          .map((rows) => rows.isEmpty ? null : _map(rows.first));
  Future<domain.Student?> getCurrent() async {
    final rows = await _joined(currentOnly: true).get();
    return rows.isEmpty ? null : _map(rows.first);
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
      _classCountQuery().watch().map((rows) {
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
  Future<List<domain.ClassSection>> getClasses() =>
      select(classSections).get().then(_withCounts);
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
  ]);
  Future<domain.ClassSection?> getByCode(String code) async {
    final row = await (select(
      classSections,
    )..where((t) => t.sectionCode.equals(code))).getSingleOrNull();
    return row == null ? null : getClass(row.id);
  }

  Stream<List<domain.Student>> watchStudents(String classId) =>
      _roster(classId).watch().map(
        (rows) => rows.map((row) {
          final student = row.readTable(students);
          final section = row.readTable(classSections);
          final device = row.readTableOrNull(devices);
          return domain.Student(
            id: student.id,
            updatedAt: student.updatedAt,
            syncStatus: student.syncStatus,
            name: student.fullName,
            studentNumber: student.studentNumber,
            classId: classId,
            gradeLevel: 'Grade ${section.gradeLevel}',
            deviceRegistered: device != null,
          );
        }).toList(),
      );
  Future<List<domain.Student>> getStudents(String classId) =>
      _roster(classId).get().then(
        (rows) => rows.map((row) {
          final student = row.readTable(students);
          final section = row.readTable(classSections);
          final device = row.readTableOrNull(devices);
          return domain.Student(
            id: student.id,
            updatedAt: student.updatedAt,
            syncStatus: student.syncStatus,
            name: student.fullName,
            studentNumber: student.studentNumber,
            classId: classId,
            gradeLevel: 'Grade ${section.gradeLevel}',
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
        status: row.status == domain.AttendanceSessionStatus.scanning
            ? 'Scanning'
            : 'Completed',
        date: row.date,
        endedAt: row.endedAt,
        scanDurationSeconds: row.scanDurationSeconds,
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
  Future<domain.AttendanceSession> getLatest() async {
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
    if (rows.isEmpty) throw StateError('No attendance session is available.');
    return rows.first;
  }

  Stream<domain.AttendanceSession> watchLatest() => watchSessions().map((rows) {
    final now = DateTime.now();
    final today = rows.where(
      (row) =>
          row.startedAt.year == now.year &&
          row.startedAt.month == now.month &&
          row.startedAt.day == now.day,
    );
    if (today.isEmpty) throw StateError('No attendance session is available.');
    return today.first;
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
            status: domain.AttendanceRecordStatus.unverified,
          ),
        );
      }
    });
  }

  Future<void> markDetected(String sessionId, String studentId, {int? rssi}) =>
      updateRecord(
        sessionId,
        studentId,
        domain.AttendanceRecordStatus.present,
        detectedAt: DateTime.now(),
        rssi: rssi,
      );
  Future<void> completeSession(String id) async {
    await transaction(() async {
      final rows = await (select(
        attendanceRecords,
      )..where((row) => row.sessionId.equals(id))).get();
      final now = DateTime.now();
      for (final row in rows.where(
        (row) => row.status == domain.AttendanceRecordStatus.unverified,
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
          endedAt: Value(now),
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
  Future<void> completeScan(String id, Set<String> detected) async {
    await transaction(() async {
      final rows = await (select(
        attendanceRecords,
      )..where((t) => t.sessionId.equals(id))).get();
      for (final row in rows) {
        final present = detected.contains(row.studentId);
        await (update(
          attendanceRecords,
        )..where((t) => t.id.equals(row.id))).write(
          AttendanceRecordsCompanion(
            status: Value(
              present
                  ? domain.AttendanceRecordStatus.present
                  : domain.AttendanceRecordStatus.absent,
            ),
            detectedAt: Value(present ? DateTime.now() : null),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value(domain.SyncStatus.pendingUpdate),
          ),
        );
      }
      await (update(attendanceSessions)..where((t) => t.id.equals(id))).write(
        AttendanceSessionsCompanion(
          status: const Value(domain.AttendanceSessionStatus.completed),
          endedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          syncStatus: const Value(domain.SyncStatus.pendingUpdate),
        ),
      );
    });
  }
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
    address: row.bleUuid,
    ownerStudentId: row.studentId,
    isConnected: false,
    lastSeenAt: null,
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

String newDatabaseId() => const Uuid().v4();
