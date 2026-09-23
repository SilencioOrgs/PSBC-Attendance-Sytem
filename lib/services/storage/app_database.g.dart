// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TeachersTable extends Teachers
    with TableInfo<$TeachersTable, TeacherRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeachersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<domain.SyncStatus>($TeachersTable.$convertersyncStatus);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, syncStatus, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teachers';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeacherRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TeacherRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeacherRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $TeachersTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TeachersTable createAlias(String alias) {
    return $TeachersTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class TeacherRow extends DataClass implements Insertable<TeacherRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final String name;
  const TeacherRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $TeachersTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  TeachersCompanion toCompanion(bool nullToAbsent) {
    return TeachersCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      name: Value(name),
    );
  }

  factory TeacherRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeacherRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'name': serializer.toJson<String>(name),
    };
  }

  TeacherRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    String? name,
  }) => TeacherRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    name: name ?? this.name,
  );
  TeacherRow copyWithCompanion(TeachersCompanion data) {
    return TeacherRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeacherRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, syncStatus, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeacherRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.name == this.name);
}

class TeachersCompanion extends UpdateCompanion<TeacherRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<String> name;
  final Value<int> rowid;
  const TeachersCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeachersCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       name = Value(name);
  static Insertable<TeacherRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeachersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return TeachersCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $TeachersTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeachersCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudentsTable extends Students
    with TableInfo<$StudentsTable, StudentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<domain.SyncStatus>($StudentsTable.$convertersyncStatus);
  static const VerificationMeta _studentNumberMeta = const VerificationMeta(
    'studentNumber',
  );
  @override
  late final GeneratedColumn<String> studentNumber = GeneratedColumn<String>(
    'student_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    studentNumber,
    fullName,
    isCurrent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'students';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('student_number')) {
      context.handle(
        _studentNumberMeta,
        studentNumber.isAcceptableOrUnknown(
          data['student_number']!,
          _studentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studentNumberMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $StudentsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      studentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_number'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
    );
  }

  @override
  $StudentsTable createAlias(String alias) {
    return $StudentsTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class StudentRow extends DataClass implements Insertable<StudentRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final String studentNumber;
  final String fullName;
  final bool isCurrent;
  const StudentRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.studentNumber,
    required this.fullName,
    required this.isCurrent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $StudentsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['student_number'] = Variable<String>(studentNumber);
    map['full_name'] = Variable<String>(fullName);
    map['is_current'] = Variable<bool>(isCurrent);
    return map;
  }

  StudentsCompanion toCompanion(bool nullToAbsent) {
    return StudentsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      studentNumber: Value(studentNumber),
      fullName: Value(fullName),
      isCurrent: Value(isCurrent),
    );
  }

  factory StudentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      studentNumber: serializer.fromJson<String>(json['studentNumber']),
      fullName: serializer.fromJson<String>(json['fullName']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'studentNumber': serializer.toJson<String>(studentNumber),
      'fullName': serializer.toJson<String>(fullName),
      'isCurrent': serializer.toJson<bool>(isCurrent),
    };
  }

  StudentRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    String? studentNumber,
    String? fullName,
    bool? isCurrent,
  }) => StudentRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    studentNumber: studentNumber ?? this.studentNumber,
    fullName: fullName ?? this.fullName,
    isCurrent: isCurrent ?? this.isCurrent,
  );
  StudentRow copyWithCompanion(StudentsCompanion data) {
    return StudentRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      studentNumber: data.studentNumber.present
          ? data.studentNumber.value
          : this.studentNumber,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('fullName: $fullName, ')
          ..write('isCurrent: $isCurrent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    syncStatus,
    studentNumber,
    fullName,
    isCurrent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.studentNumber == this.studentNumber &&
          other.fullName == this.fullName &&
          other.isCurrent == this.isCurrent);
}

class StudentsCompanion extends UpdateCompanion<StudentRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<String> studentNumber;
  final Value<String> fullName;
  final Value<bool> isCurrent;
  final Value<int> rowid;
  const StudentsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.studentNumber = const Value.absent(),
    this.fullName = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentsCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    required String studentNumber,
    required String fullName,
    this.isCurrent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       studentNumber = Value(studentNumber),
       fullName = Value(fullName);
  static Insertable<StudentRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<String>? studentNumber,
    Expression<String>? fullName,
    Expression<bool>? isCurrent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (studentNumber != null) 'student_number': studentNumber,
      if (fullName != null) 'full_name': fullName,
      if (isCurrent != null) 'is_current': isCurrent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<String>? studentNumber,
    Value<String>? fullName,
    Value<bool>? isCurrent,
    Value<int>? rowid,
  }) {
    return StudentsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      studentNumber: studentNumber ?? this.studentNumber,
      fullName: fullName ?? this.fullName,
      isCurrent: isCurrent ?? this.isCurrent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $StudentsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (studentNumber.present) {
      map['student_number'] = Variable<String>(studentNumber.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('studentNumber: $studentNumber, ')
          ..write('fullName: $fullName, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClassSectionsTable extends ClassSections
    with TableInfo<$ClassSectionsTable, ClassSectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClassSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<domain.SyncStatus>($ClassSectionsTable.$convertersyncStatus);
  static const VerificationMeta _gradeLevelMeta = const VerificationMeta(
    'gradeLevel',
  );
  @override
  late final GeneratedColumn<int> gradeLevel = GeneratedColumn<int>(
    'grade_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionLabelMeta = const VerificationMeta(
    'sectionLabel',
  );
  @override
  late final GeneratedColumn<String> sectionLabel = GeneratedColumn<String>(
    'section_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionCodeMeta = const VerificationMeta(
    'sectionCode',
  );
  @override
  late final GeneratedColumn<String> sectionCode = GeneratedColumn<String>(
    'section_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _roomMeta = const VerificationMeta('room');
  @override
  late final GeneratedColumn<String> room = GeneratedColumn<String>(
    'room',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleStartMeta = const VerificationMeta(
    'scheduleStart',
  );
  @override
  late final GeneratedColumn<DateTime> scheduleStart =
      GeneratedColumn<DateTime>(
        'schedule_start',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _scheduleEndMeta = const VerificationMeta(
    'scheduleEnd',
  );
  @override
  late final GeneratedColumn<DateTime> scheduleEnd = GeneratedColumn<DateTime>(
    'schedule_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bleBeaconIdMeta = const VerificationMeta(
    'bleBeaconId',
  );
  @override
  late final GeneratedColumn<String> bleBeaconId = GeneratedColumn<String>(
    'ble_beacon_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teacherIdMeta = const VerificationMeta(
    'teacherId',
  );
  @override
  late final GeneratedColumn<String> teacherId = GeneratedColumn<String>(
    'teacher_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teachers (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    gradeLevel,
    sectionLabel,
    sectionCode,
    subject,
    room,
    scheduleStart,
    scheduleEnd,
    bleBeaconId,
    teacherId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'class_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClassSectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('grade_level')) {
      context.handle(
        _gradeLevelMeta,
        gradeLevel.isAcceptableOrUnknown(data['grade_level']!, _gradeLevelMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeLevelMeta);
    }
    if (data.containsKey('section_label')) {
      context.handle(
        _sectionLabelMeta,
        sectionLabel.isAcceptableOrUnknown(
          data['section_label']!,
          _sectionLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionLabelMeta);
    }
    if (data.containsKey('section_code')) {
      context.handle(
        _sectionCodeMeta,
        sectionCode.isAcceptableOrUnknown(
          data['section_code']!,
          _sectionCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionCodeMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('room')) {
      context.handle(
        _roomMeta,
        room.isAcceptableOrUnknown(data['room']!, _roomMeta),
      );
    } else if (isInserting) {
      context.missing(_roomMeta);
    }
    if (data.containsKey('schedule_start')) {
      context.handle(
        _scheduleStartMeta,
        scheduleStart.isAcceptableOrUnknown(
          data['schedule_start']!,
          _scheduleStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleStartMeta);
    }
    if (data.containsKey('schedule_end')) {
      context.handle(
        _scheduleEndMeta,
        scheduleEnd.isAcceptableOrUnknown(
          data['schedule_end']!,
          _scheduleEndMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleEndMeta);
    }
    if (data.containsKey('ble_beacon_id')) {
      context.handle(
        _bleBeaconIdMeta,
        bleBeaconId.isAcceptableOrUnknown(
          data['ble_beacon_id']!,
          _bleBeaconIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bleBeaconIdMeta);
    }
    if (data.containsKey('teacher_id')) {
      context.handle(
        _teacherIdMeta,
        teacherId.isAcceptableOrUnknown(data['teacher_id']!, _teacherIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teacherIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClassSectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClassSectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $ClassSectionsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      gradeLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade_level'],
      )!,
      sectionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_label'],
      )!,
      sectionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_code'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      room: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room'],
      )!,
      scheduleStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}schedule_start'],
      )!,
      scheduleEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}schedule_end'],
      )!,
      bleBeaconId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ble_beacon_id'],
      )!,
      teacherId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}teacher_id'],
      )!,
    );
  }

  @override
  $ClassSectionsTable createAlias(String alias) {
    return $ClassSectionsTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class ClassSectionRow extends DataClass implements Insertable<ClassSectionRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final int gradeLevel;
  final String sectionLabel;
  final String sectionCode;
  final String subject;
  final String room;
  final DateTime scheduleStart;
  final DateTime scheduleEnd;
  final String bleBeaconId;
  final String teacherId;
  const ClassSectionRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.gradeLevel,
    required this.sectionLabel,
    required this.sectionCode,
    required this.subject,
    required this.room,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.bleBeaconId,
    required this.teacherId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $ClassSectionsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['grade_level'] = Variable<int>(gradeLevel);
    map['section_label'] = Variable<String>(sectionLabel);
    map['section_code'] = Variable<String>(sectionCode);
    map['subject'] = Variable<String>(subject);
    map['room'] = Variable<String>(room);
    map['schedule_start'] = Variable<DateTime>(scheduleStart);
    map['schedule_end'] = Variable<DateTime>(scheduleEnd);
    map['ble_beacon_id'] = Variable<String>(bleBeaconId);
    map['teacher_id'] = Variable<String>(teacherId);
    return map;
  }

  ClassSectionsCompanion toCompanion(bool nullToAbsent) {
    return ClassSectionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      gradeLevel: Value(gradeLevel),
      sectionLabel: Value(sectionLabel),
      sectionCode: Value(sectionCode),
      subject: Value(subject),
      room: Value(room),
      scheduleStart: Value(scheduleStart),
      scheduleEnd: Value(scheduleEnd),
      bleBeaconId: Value(bleBeaconId),
      teacherId: Value(teacherId),
    );
  }

  factory ClassSectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClassSectionRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      gradeLevel: serializer.fromJson<int>(json['gradeLevel']),
      sectionLabel: serializer.fromJson<String>(json['sectionLabel']),
      sectionCode: serializer.fromJson<String>(json['sectionCode']),
      subject: serializer.fromJson<String>(json['subject']),
      room: serializer.fromJson<String>(json['room']),
      scheduleStart: serializer.fromJson<DateTime>(json['scheduleStart']),
      scheduleEnd: serializer.fromJson<DateTime>(json['scheduleEnd']),
      bleBeaconId: serializer.fromJson<String>(json['bleBeaconId']),
      teacherId: serializer.fromJson<String>(json['teacherId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'gradeLevel': serializer.toJson<int>(gradeLevel),
      'sectionLabel': serializer.toJson<String>(sectionLabel),
      'sectionCode': serializer.toJson<String>(sectionCode),
      'subject': serializer.toJson<String>(subject),
      'room': serializer.toJson<String>(room),
      'scheduleStart': serializer.toJson<DateTime>(scheduleStart),
      'scheduleEnd': serializer.toJson<DateTime>(scheduleEnd),
      'bleBeaconId': serializer.toJson<String>(bleBeaconId),
      'teacherId': serializer.toJson<String>(teacherId),
    };
  }

  ClassSectionRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    int? gradeLevel,
    String? sectionLabel,
    String? sectionCode,
    String? subject,
    String? room,
    DateTime? scheduleStart,
    DateTime? scheduleEnd,
    String? bleBeaconId,
    String? teacherId,
  }) => ClassSectionRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    sectionLabel: sectionLabel ?? this.sectionLabel,
    sectionCode: sectionCode ?? this.sectionCode,
    subject: subject ?? this.subject,
    room: room ?? this.room,
    scheduleStart: scheduleStart ?? this.scheduleStart,
    scheduleEnd: scheduleEnd ?? this.scheduleEnd,
    bleBeaconId: bleBeaconId ?? this.bleBeaconId,
    teacherId: teacherId ?? this.teacherId,
  );
  ClassSectionRow copyWithCompanion(ClassSectionsCompanion data) {
    return ClassSectionRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      gradeLevel: data.gradeLevel.present
          ? data.gradeLevel.value
          : this.gradeLevel,
      sectionLabel: data.sectionLabel.present
          ? data.sectionLabel.value
          : this.sectionLabel,
      sectionCode: data.sectionCode.present
          ? data.sectionCode.value
          : this.sectionCode,
      subject: data.subject.present ? data.subject.value : this.subject,
      room: data.room.present ? data.room.value : this.room,
      scheduleStart: data.scheduleStart.present
          ? data.scheduleStart.value
          : this.scheduleStart,
      scheduleEnd: data.scheduleEnd.present
          ? data.scheduleEnd.value
          : this.scheduleEnd,
      bleBeaconId: data.bleBeaconId.present
          ? data.bleBeaconId.value
          : this.bleBeaconId,
      teacherId: data.teacherId.present ? data.teacherId.value : this.teacherId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClassSectionRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('sectionLabel: $sectionLabel, ')
          ..write('sectionCode: $sectionCode, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('scheduleStart: $scheduleStart, ')
          ..write('scheduleEnd: $scheduleEnd, ')
          ..write('bleBeaconId: $bleBeaconId, ')
          ..write('teacherId: $teacherId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    syncStatus,
    gradeLevel,
    sectionLabel,
    sectionCode,
    subject,
    room,
    scheduleStart,
    scheduleEnd,
    bleBeaconId,
    teacherId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClassSectionRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.gradeLevel == this.gradeLevel &&
          other.sectionLabel == this.sectionLabel &&
          other.sectionCode == this.sectionCode &&
          other.subject == this.subject &&
          other.room == this.room &&
          other.scheduleStart == this.scheduleStart &&
          other.scheduleEnd == this.scheduleEnd &&
          other.bleBeaconId == this.bleBeaconId &&
          other.teacherId == this.teacherId);
}

class ClassSectionsCompanion extends UpdateCompanion<ClassSectionRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<int> gradeLevel;
  final Value<String> sectionLabel;
  final Value<String> sectionCode;
  final Value<String> subject;
  final Value<String> room;
  final Value<DateTime> scheduleStart;
  final Value<DateTime> scheduleEnd;
  final Value<String> bleBeaconId;
  final Value<String> teacherId;
  final Value<int> rowid;
  const ClassSectionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.gradeLevel = const Value.absent(),
    this.sectionLabel = const Value.absent(),
    this.sectionCode = const Value.absent(),
    this.subject = const Value.absent(),
    this.room = const Value.absent(),
    this.scheduleStart = const Value.absent(),
    this.scheduleEnd = const Value.absent(),
    this.bleBeaconId = const Value.absent(),
    this.teacherId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClassSectionsCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    required int gradeLevel,
    required String sectionLabel,
    required String sectionCode,
    this.subject = const Value.absent(),
    required String room,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
    required String bleBeaconId,
    required String teacherId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       gradeLevel = Value(gradeLevel),
       sectionLabel = Value(sectionLabel),
       sectionCode = Value(sectionCode),
       room = Value(room),
       scheduleStart = Value(scheduleStart),
       scheduleEnd = Value(scheduleEnd),
       bleBeaconId = Value(bleBeaconId),
       teacherId = Value(teacherId);
  static Insertable<ClassSectionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? gradeLevel,
    Expression<String>? sectionLabel,
    Expression<String>? sectionCode,
    Expression<String>? subject,
    Expression<String>? room,
    Expression<DateTime>? scheduleStart,
    Expression<DateTime>? scheduleEnd,
    Expression<String>? bleBeaconId,
    Expression<String>? teacherId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (gradeLevel != null) 'grade_level': gradeLevel,
      if (sectionLabel != null) 'section_label': sectionLabel,
      if (sectionCode != null) 'section_code': sectionCode,
      if (subject != null) 'subject': subject,
      if (room != null) 'room': room,
      if (scheduleStart != null) 'schedule_start': scheduleStart,
      if (scheduleEnd != null) 'schedule_end': scheduleEnd,
      if (bleBeaconId != null) 'ble_beacon_id': bleBeaconId,
      if (teacherId != null) 'teacher_id': teacherId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClassSectionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<int>? gradeLevel,
    Value<String>? sectionLabel,
    Value<String>? sectionCode,
    Value<String>? subject,
    Value<String>? room,
    Value<DateTime>? scheduleStart,
    Value<DateTime>? scheduleEnd,
    Value<String>? bleBeaconId,
    Value<String>? teacherId,
    Value<int>? rowid,
  }) {
    return ClassSectionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      sectionCode: sectionCode ?? this.sectionCode,
      subject: subject ?? this.subject,
      room: room ?? this.room,
      scheduleStart: scheduleStart ?? this.scheduleStart,
      scheduleEnd: scheduleEnd ?? this.scheduleEnd,
      bleBeaconId: bleBeaconId ?? this.bleBeaconId,
      teacherId: teacherId ?? this.teacherId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $ClassSectionsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (gradeLevel.present) {
      map['grade_level'] = Variable<int>(gradeLevel.value);
    }
    if (sectionLabel.present) {
      map['section_label'] = Variable<String>(sectionLabel.value);
    }
    if (sectionCode.present) {
      map['section_code'] = Variable<String>(sectionCode.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (room.present) {
      map['room'] = Variable<String>(room.value);
    }
    if (scheduleStart.present) {
      map['schedule_start'] = Variable<DateTime>(scheduleStart.value);
    }
    if (scheduleEnd.present) {
      map['schedule_end'] = Variable<DateTime>(scheduleEnd.value);
    }
    if (bleBeaconId.present) {
      map['ble_beacon_id'] = Variable<String>(bleBeaconId.value);
    }
    if (teacherId.present) {
      map['teacher_id'] = Variable<String>(teacherId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClassSectionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('gradeLevel: $gradeLevel, ')
          ..write('sectionLabel: $sectionLabel, ')
          ..write('sectionCode: $sectionCode, ')
          ..write('subject: $subject, ')
          ..write('room: $room, ')
          ..write('scheduleStart: $scheduleStart, ')
          ..write('scheduleEnd: $scheduleEnd, ')
          ..write('bleBeaconId: $bleBeaconId, ')
          ..write('teacherId: $teacherId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnrollmentsTable extends Enrollments
    with TableInfo<$EnrollmentsTable, EnrollmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnrollmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<domain.SyncStatus>($EnrollmentsTable.$convertersyncStatus);
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students (id)',
    ),
  );
  static const VerificationMeta _classSectionIdMeta = const VerificationMeta(
    'classSectionId',
  );
  @override
  late final GeneratedColumn<String> classSectionId = GeneratedColumn<String>(
    'class_section_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES class_sections (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    studentId,
    classSectionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enrollments';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnrollmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('class_section_id')) {
      context.handle(
        _classSectionIdMeta,
        classSectionId.isAcceptableOrUnknown(
          data['class_section_id']!,
          _classSectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classSectionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnrollmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnrollmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $EnrollmentsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      classSectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_section_id'],
      )!,
    );
  }

  @override
  $EnrollmentsTable createAlias(String alias) {
    return $EnrollmentsTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class EnrollmentRow extends DataClass implements Insertable<EnrollmentRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final String studentId;
  final String classSectionId;
  const EnrollmentRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.studentId,
    required this.classSectionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $EnrollmentsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['student_id'] = Variable<String>(studentId);
    map['class_section_id'] = Variable<String>(classSectionId);
    return map;
  }

  EnrollmentsCompanion toCompanion(bool nullToAbsent) {
    return EnrollmentsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      studentId: Value(studentId),
      classSectionId: Value(classSectionId),
    );
  }

  factory EnrollmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnrollmentRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      studentId: serializer.fromJson<String>(json['studentId']),
      classSectionId: serializer.fromJson<String>(json['classSectionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'studentId': serializer.toJson<String>(studentId),
      'classSectionId': serializer.toJson<String>(classSectionId),
    };
  }

  EnrollmentRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    String? studentId,
    String? classSectionId,
  }) => EnrollmentRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    studentId: studentId ?? this.studentId,
    classSectionId: classSectionId ?? this.classSectionId,
  );
  EnrollmentRow copyWithCompanion(EnrollmentsCompanion data) {
    return EnrollmentRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      classSectionId: data.classSectionId.present
          ? data.classSectionId.value
          : this.classSectionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('studentId: $studentId, ')
          ..write('classSectionId: $classSectionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, syncStatus, studentId, classSectionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnrollmentRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.studentId == this.studentId &&
          other.classSectionId == this.classSectionId);
}

class EnrollmentsCompanion extends UpdateCompanion<EnrollmentRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<String> studentId;
  final Value<String> classSectionId;
  final Value<int> rowid;
  const EnrollmentsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.studentId = const Value.absent(),
    this.classSectionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnrollmentsCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    required String studentId,
    required String classSectionId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       studentId = Value(studentId),
       classSectionId = Value(classSectionId);
  static Insertable<EnrollmentRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<String>? studentId,
    Expression<String>? classSectionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (studentId != null) 'student_id': studentId,
      if (classSectionId != null) 'class_section_id': classSectionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnrollmentsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<String>? studentId,
    Value<String>? classSectionId,
    Value<int>? rowid,
  }) {
    return EnrollmentsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      studentId: studentId ?? this.studentId,
      classSectionId: classSectionId ?? this.classSectionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $EnrollmentsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (classSectionId.present) {
      map['class_section_id'] = Variable<String>(classSectionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('studentId: $studentId, ')
          ..write('classSectionId: $classSectionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceSessionsTable extends AttendanceSessions
    with TableInfo<$AttendanceSessionsTable, AttendanceSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<domain.SyncStatus>(
        $AttendanceSessionsTable.$convertersyncStatus,
      );
  static const VerificationMeta _classSectionIdMeta = const VerificationMeta(
    'classSectionId',
  );
  @override
  late final GeneratedColumn<String> classSectionId = GeneratedColumn<String>(
    'class_section_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES class_sections (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Attendance session'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanDurationSecondsMeta =
      const VerificationMeta('scanDurationSeconds');
  @override
  late final GeneratedColumn<int> scanDurationSeconds = GeneratedColumn<int>(
    'scan_duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    domain.AttendanceSessionStatus,
    String
  >
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<domain.AttendanceSessionStatus>(
        $AttendanceSessionsTable.$converterstatus,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    classSectionId,
    title,
    date,
    startedAt,
    endedAt,
    scanDurationSeconds,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('class_section_id')) {
      context.handle(
        _classSectionIdMeta,
        classSectionId.isAcceptableOrUnknown(
          data['class_section_id']!,
          _classSectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_classSectionIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('scan_duration_seconds')) {
      context.handle(
        _scanDurationSecondsMeta,
        scanDurationSeconds.isAcceptableOrUnknown(
          data['scan_duration_seconds']!,
          _scanDurationSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $AttendanceSessionsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      classSectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}class_section_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      scanDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_duration_seconds'],
      )!,
      status: $AttendanceSessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $AttendanceSessionsTable createAlias(String alias) {
    return $AttendanceSessionsTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
  static TypeConverter<domain.AttendanceSessionStatus, String>
  $converterstatus = const SessionStatusConverter();
}

class AttendanceSessionRow extends DataClass
    implements Insertable<AttendanceSessionRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final String classSectionId;
  final String title;
  final DateTime date;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int scanDurationSeconds;
  final domain.AttendanceSessionStatus status;
  const AttendanceSessionRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.classSectionId,
    required this.title,
    required this.date,
    required this.startedAt,
    this.endedAt,
    required this.scanDurationSeconds,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $AttendanceSessionsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['class_section_id'] = Variable<String>(classSectionId);
    map['title'] = Variable<String>(title);
    map['date'] = Variable<DateTime>(date);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['scan_duration_seconds'] = Variable<int>(scanDurationSeconds);
    {
      map['status'] = Variable<String>(
        $AttendanceSessionsTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  AttendanceSessionsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceSessionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      classSectionId: Value(classSectionId),
      title: Value(title),
      date: Value(date),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      scanDurationSeconds: Value(scanDurationSeconds),
      status: Value(status),
    );
  }

  factory AttendanceSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceSessionRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      classSectionId: serializer.fromJson<String>(json['classSectionId']),
      title: serializer.fromJson<String>(json['title']),
      date: serializer.fromJson<DateTime>(json['date']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      scanDurationSeconds: serializer.fromJson<int>(
        json['scanDurationSeconds'],
      ),
      status: serializer.fromJson<domain.AttendanceSessionStatus>(
        json['status'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'classSectionId': serializer.toJson<String>(classSectionId),
      'title': serializer.toJson<String>(title),
      'date': serializer.toJson<DateTime>(date),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'scanDurationSeconds': serializer.toJson<int>(scanDurationSeconds),
      'status': serializer.toJson<domain.AttendanceSessionStatus>(status),
    };
  }

  AttendanceSessionRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    String? classSectionId,
    String? title,
    DateTime? date,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? scanDurationSeconds,
    domain.AttendanceSessionStatus? status,
  }) => AttendanceSessionRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    classSectionId: classSectionId ?? this.classSectionId,
    title: title ?? this.title,
    date: date ?? this.date,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    scanDurationSeconds: scanDurationSeconds ?? this.scanDurationSeconds,
    status: status ?? this.status,
  );
  AttendanceSessionRow copyWithCompanion(AttendanceSessionsCompanion data) {
    return AttendanceSessionRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      classSectionId: data.classSectionId.present
          ? data.classSectionId.value
          : this.classSectionId,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      scanDurationSeconds: data.scanDurationSeconds.present
          ? data.scanDurationSeconds.value
          : this.scanDurationSeconds,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSessionRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('classSectionId: $classSectionId, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('scanDurationSeconds: $scanDurationSeconds, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    syncStatus,
    classSectionId,
    title,
    date,
    startedAt,
    endedAt,
    scanDurationSeconds,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceSessionRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.classSectionId == this.classSectionId &&
          other.title == this.title &&
          other.date == this.date &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.scanDurationSeconds == this.scanDurationSeconds &&
          other.status == this.status);
}

class AttendanceSessionsCompanion
    extends UpdateCompanion<AttendanceSessionRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<String> classSectionId;
  final Value<String> title;
  final Value<DateTime> date;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> scanDurationSeconds;
  final Value<domain.AttendanceSessionStatus> status;
  final Value<int> rowid;
  const AttendanceSessionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.classSectionId = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.scanDurationSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceSessionsCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    required String classSectionId,
    this.title = const Value.absent(),
    required DateTime date,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.scanDurationSeconds = const Value.absent(),
    required domain.AttendanceSessionStatus status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       classSectionId = Value(classSectionId),
       date = Value(date),
       startedAt = Value(startedAt),
       status = Value(status);
  static Insertable<AttendanceSessionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<String>? classSectionId,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? scanDurationSeconds,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (classSectionId != null) 'class_section_id': classSectionId,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (scanDurationSeconds != null)
        'scan_duration_seconds': scanDurationSeconds,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<String>? classSectionId,
    Value<String>? title,
    Value<DateTime>? date,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? scanDurationSeconds,
    Value<domain.AttendanceSessionStatus>? status,
    Value<int>? rowid,
  }) {
    return AttendanceSessionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      classSectionId: classSectionId ?? this.classSectionId,
      title: title ?? this.title,
      date: date ?? this.date,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      scanDurationSeconds: scanDurationSeconds ?? this.scanDurationSeconds,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $AttendanceSessionsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (classSectionId.present) {
      map['class_section_id'] = Variable<String>(classSectionId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (scanDurationSeconds.present) {
      map['scan_duration_seconds'] = Variable<int>(scanDurationSeconds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $AttendanceSessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceSessionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('classSectionId: $classSectionId, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('scanDurationSeconds: $scanDurationSeconds, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttendanceRecordsTable extends AttendanceRecords
    with TableInfo<$AttendanceRecordsTable, AttendanceRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttendanceRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<domain.SyncStatus>(
        $AttendanceRecordsTable.$convertersyncStatus,
      );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES attendance_sessions (id)',
    ),
  );
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES students (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    domain.AttendanceRecordStatus,
    String
  >
  status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<domain.AttendanceRecordStatus>(
        $AttendanceRecordsTable.$converterstatus,
      );
  static const VerificationMeta _rssiMeta = const VerificationMeta('rssi');
  @override
  late final GeneratedColumn<int> rssi = GeneratedColumn<int>(
    'rssi',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detectedAtMeta = const VerificationMeta(
    'detectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detectedAt = GeneratedColumn<DateTime>(
    'detected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    sessionId,
    studentId,
    status,
    rssi,
    detectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attendance_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttendanceRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('rssi')) {
      context.handle(
        _rssiMeta,
        rssi.isAcceptableOrUnknown(data['rssi']!, _rssiMeta),
      );
    }
    if (data.containsKey('detected_at')) {
      context.handle(
        _detectedAtMeta,
        detectedAt.isAcceptableOrUnknown(data['detected_at']!, _detectedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttendanceRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttendanceRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $AttendanceRecordsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      status: $AttendanceRecordsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      rssi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rssi'],
      ),
      detectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detected_at'],
      ),
    );
  }

  @override
  $AttendanceRecordsTable createAlias(String alias) {
    return $AttendanceRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
  static TypeConverter<domain.AttendanceRecordStatus, String> $converterstatus =
      const RecordStatusConverter();
}

class AttendanceRecordRow extends DataClass
    implements Insertable<AttendanceRecordRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final String sessionId;
  final String studentId;
  final domain.AttendanceRecordStatus status;
  final int? rssi;
  final DateTime? detectedAt;
  const AttendanceRecordRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.rssi,
    this.detectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $AttendanceRecordsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['session_id'] = Variable<String>(sessionId);
    map['student_id'] = Variable<String>(studentId);
    {
      map['status'] = Variable<String>(
        $AttendanceRecordsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || rssi != null) {
      map['rssi'] = Variable<int>(rssi);
    }
    if (!nullToAbsent || detectedAt != null) {
      map['detected_at'] = Variable<DateTime>(detectedAt);
    }
    return map;
  }

  AttendanceRecordsCompanion toCompanion(bool nullToAbsent) {
    return AttendanceRecordsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      sessionId: Value(sessionId),
      studentId: Value(studentId),
      status: Value(status),
      rssi: rssi == null && nullToAbsent ? const Value.absent() : Value(rssi),
      detectedAt: detectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detectedAt),
    );
  }

  factory AttendanceRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttendanceRecordRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      status: serializer.fromJson<domain.AttendanceRecordStatus>(
        json['status'],
      ),
      rssi: serializer.fromJson<int?>(json['rssi']),
      detectedAt: serializer.fromJson<DateTime?>(json['detectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'sessionId': serializer.toJson<String>(sessionId),
      'studentId': serializer.toJson<String>(studentId),
      'status': serializer.toJson<domain.AttendanceRecordStatus>(status),
      'rssi': serializer.toJson<int?>(rssi),
      'detectedAt': serializer.toJson<DateTime?>(detectedAt),
    };
  }

  AttendanceRecordRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    String? sessionId,
    String? studentId,
    domain.AttendanceRecordStatus? status,
    Value<int?> rssi = const Value.absent(),
    Value<DateTime?> detectedAt = const Value.absent(),
  }) => AttendanceRecordRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    sessionId: sessionId ?? this.sessionId,
    studentId: studentId ?? this.studentId,
    status: status ?? this.status,
    rssi: rssi.present ? rssi.value : this.rssi,
    detectedAt: detectedAt.present ? detectedAt.value : this.detectedAt,
  );
  AttendanceRecordRow copyWithCompanion(AttendanceRecordsCompanion data) {
    return AttendanceRecordRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      status: data.status.present ? data.status.value : this.status,
      rssi: data.rssi.present ? data.rssi.value : this.rssi,
      detectedAt: data.detectedAt.present
          ? data.detectedAt.value
          : this.detectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status, ')
          ..write('rssi: $rssi, ')
          ..write('detectedAt: $detectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    syncStatus,
    sessionId,
    studentId,
    status,
    rssi,
    detectedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttendanceRecordRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.sessionId == this.sessionId &&
          other.studentId == this.studentId &&
          other.status == this.status &&
          other.rssi == this.rssi &&
          other.detectedAt == this.detectedAt);
}

class AttendanceRecordsCompanion extends UpdateCompanion<AttendanceRecordRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<String> sessionId;
  final Value<String> studentId;
  final Value<domain.AttendanceRecordStatus> status;
  final Value<int?> rssi;
  final Value<DateTime?> detectedAt;
  final Value<int> rowid;
  const AttendanceRecordsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.status = const Value.absent(),
    this.rssi = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttendanceRecordsCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    required String sessionId,
    required String studentId,
    required domain.AttendanceRecordStatus status,
    this.rssi = const Value.absent(),
    this.detectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       sessionId = Value(sessionId),
       studentId = Value(studentId),
       status = Value(status);
  static Insertable<AttendanceRecordRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<String>? sessionId,
    Expression<String>? studentId,
    Expression<String>? status,
    Expression<int>? rssi,
    Expression<DateTime>? detectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (sessionId != null) 'session_id': sessionId,
      if (studentId != null) 'student_id': studentId,
      if (status != null) 'status': status,
      if (rssi != null) 'rssi': rssi,
      if (detectedAt != null) 'detected_at': detectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttendanceRecordsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<String>? sessionId,
    Value<String>? studentId,
    Value<domain.AttendanceRecordStatus>? status,
    Value<int?>? rssi,
    Value<DateTime?>? detectedAt,
    Value<int>? rowid,
  }) {
    return AttendanceRecordsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      status: status ?? this.status,
      rssi: rssi ?? this.rssi,
      detectedAt: detectedAt ?? this.detectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $AttendanceRecordsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $AttendanceRecordsTable.$converterstatus.toSql(status.value),
      );
    }
    if (rssi.present) {
      map['rssi'] = Variable<int>(rssi.value);
    }
    if (detectedAt.present) {
      map['detected_at'] = Variable<DateTime>(detectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttendanceRecordsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('sessionId: $sessionId, ')
          ..write('studentId: $studentId, ')
          ..write('status: $status, ')
          ..write('rssi: $rssi, ')
          ..write('detectedAt: $detectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, DeviceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<domain.SyncStatus>($DevicesTable.$convertersyncStatus);
  static const VerificationMeta _studentIdMeta = const VerificationMeta(
    'studentId',
  );
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
    'student_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES students (id)',
    ),
  );
  static const VerificationMeta _bleUuidMeta = const VerificationMeta(
    'bleUuid',
  );
  @override
  late final GeneratedColumn<String> bleUuid = GeneratedColumn<String>(
    'ble_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _deviceModelMeta = const VerificationMeta(
    'deviceModel',
  );
  @override
  late final GeneratedColumn<String> deviceModel = GeneratedColumn<String>(
    'device_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registeredAtMeta = const VerificationMeta(
    'registeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> registeredAt = GeneratedColumn<DateTime>(
    'registered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    studentId,
    bleUuid,
    deviceModel,
    registeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(
        _studentIdMeta,
        studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('ble_uuid')) {
      context.handle(
        _bleUuidMeta,
        bleUuid.isAcceptableOrUnknown(data['ble_uuid']!, _bleUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_bleUuidMeta);
    }
    if (data.containsKey('device_model')) {
      context.handle(
        _deviceModelMeta,
        deviceModel.isAcceptableOrUnknown(
          data['device_model']!,
          _deviceModelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceModelMeta);
    }
    if (data.containsKey('registered_at')) {
      context.handle(
        _registeredAtMeta,
        registeredAt.isAcceptableOrUnknown(
          data['registered_at']!,
          _registeredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $DevicesTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      studentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}student_id'],
      )!,
      bleUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ble_uuid'],
      )!,
      deviceModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_model'],
      )!,
      registeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}registered_at'],
      )!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class DeviceRow extends DataClass implements Insertable<DeviceRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final String studentId;
  final String bleUuid;
  final String deviceModel;
  final DateTime registeredAt;
  const DeviceRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.studentId,
    required this.bleUuid,
    required this.deviceModel,
    required this.registeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $DevicesTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['student_id'] = Variable<String>(studentId);
    map['ble_uuid'] = Variable<String>(bleUuid);
    map['device_model'] = Variable<String>(deviceModel);
    map['registered_at'] = Variable<DateTime>(registeredAt);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      studentId: Value(studentId),
      bleUuid: Value(bleUuid),
      deviceModel: Value(deviceModel),
      registeredAt: Value(registeredAt),
    );
  }

  factory DeviceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      studentId: serializer.fromJson<String>(json['studentId']),
      bleUuid: serializer.fromJson<String>(json['bleUuid']),
      deviceModel: serializer.fromJson<String>(json['deviceModel']),
      registeredAt: serializer.fromJson<DateTime>(json['registeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'studentId': serializer.toJson<String>(studentId),
      'bleUuid': serializer.toJson<String>(bleUuid),
      'deviceModel': serializer.toJson<String>(deviceModel),
      'registeredAt': serializer.toJson<DateTime>(registeredAt),
    };
  }

  DeviceRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    String? studentId,
    String? bleUuid,
    String? deviceModel,
    DateTime? registeredAt,
  }) => DeviceRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    studentId: studentId ?? this.studentId,
    bleUuid: bleUuid ?? this.bleUuid,
    deviceModel: deviceModel ?? this.deviceModel,
    registeredAt: registeredAt ?? this.registeredAt,
  );
  DeviceRow copyWithCompanion(DevicesCompanion data) {
    return DeviceRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      bleUuid: data.bleUuid.present ? data.bleUuid.value : this.bleUuid,
      deviceModel: data.deviceModel.present
          ? data.deviceModel.value
          : this.deviceModel,
      registeredAt: data.registeredAt.present
          ? data.registeredAt.value
          : this.registeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('studentId: $studentId, ')
          ..write('bleUuid: $bleUuid, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('registeredAt: $registeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    syncStatus,
    studentId,
    bleUuid,
    deviceModel,
    registeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.studentId == this.studentId &&
          other.bleUuid == this.bleUuid &&
          other.deviceModel == this.deviceModel &&
          other.registeredAt == this.registeredAt);
}

class DevicesCompanion extends UpdateCompanion<DeviceRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<String> studentId;
  final Value<String> bleUuid;
  final Value<String> deviceModel;
  final Value<DateTime> registeredAt;
  final Value<int> rowid;
  const DevicesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.studentId = const Value.absent(),
    this.bleUuid = const Value.absent(),
    this.deviceModel = const Value.absent(),
    this.registeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    required String studentId,
    required String bleUuid,
    required String deviceModel,
    required DateTime registeredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       studentId = Value(studentId),
       bleUuid = Value(bleUuid),
       deviceModel = Value(deviceModel),
       registeredAt = Value(registeredAt);
  static Insertable<DeviceRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<String>? studentId,
    Expression<String>? bleUuid,
    Expression<String>? deviceModel,
    Expression<DateTime>? registeredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (studentId != null) 'student_id': studentId,
      if (bleUuid != null) 'ble_uuid': bleUuid,
      if (deviceModel != null) 'device_model': deviceModel,
      if (registeredAt != null) 'registered_at': registeredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<String>? studentId,
    Value<String>? bleUuid,
    Value<String>? deviceModel,
    Value<DateTime>? registeredAt,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      studentId: studentId ?? this.studentId,
      bleUuid: bleUuid ?? this.bleUuid,
      deviceModel: deviceModel ?? this.deviceModel,
      registeredAt: registeredAt ?? this.registeredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $DevicesTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (bleUuid.present) {
      map['ble_uuid'] = Variable<String>(bleUuid.value);
    }
    if (deviceModel.present) {
      map['device_model'] = Variable<String>(deviceModel.value);
    }
    if (registeredAt.present) {
      map['registered_at'] = Variable<DateTime>(registeredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('studentId: $studentId, ')
          ..write('bleUuid: $bleUuid, ')
          ..write('deviceModel: $deviceModel, ')
          ..write('registeredAt: $registeredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsRowsTable extends AppSettingsRows
    with TableInfo<$AppSettingsRowsTable, AppSettingsDataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<domain.SyncStatus, String>
  syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<domain.SyncStatus>(
        $AppSettingsRowsTable.$convertersyncStatus,
      );
  static const VerificationMeta _singletonKeyMeta = const VerificationMeta(
    'singletonKey',
  );
  @override
  late final GeneratedColumn<String> singletonKey = GeneratedColumn<String>(
    'singleton_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    defaultValue: const Constant('settings'),
  );
  static const VerificationMeta _scanDurationSecondsMeta =
      const VerificationMeta('scanDurationSeconds');
  @override
  late final GeneratedColumn<int> scanDurationSeconds = GeneratedColumn<int>(
    'scan_duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rssiThresholdMeta = const VerificationMeta(
    'rssiThreshold',
  );
  @override
  late final GeneratedColumn<int> rssiThreshold = GeneratedColumn<int>(
    'rssi_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soundEnabledMeta = const VerificationMeta(
    'soundEnabled',
  );
  @override
  late final GeneratedColumn<bool> soundEnabled = GeneratedColumn<bool>(
    'sound_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sound_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _vibrationEnabledMeta = const VerificationMeta(
    'vibrationEnabled',
  );
  @override
  late final GeneratedColumn<bool> vibrationEnabled = GeneratedColumn<bool>(
    'vibration_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vibration_enabled" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    syncStatus,
    singletonKey,
    scanDurationSeconds,
    rssiThreshold,
    soundEnabled,
    vibrationEnabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('singleton_key')) {
      context.handle(
        _singletonKeyMeta,
        singletonKey.isAcceptableOrUnknown(
          data['singleton_key']!,
          _singletonKeyMeta,
        ),
      );
    }
    if (data.containsKey('scan_duration_seconds')) {
      context.handle(
        _scanDurationSecondsMeta,
        scanDurationSeconds.isAcceptableOrUnknown(
          data['scan_duration_seconds']!,
          _scanDurationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scanDurationSecondsMeta);
    }
    if (data.containsKey('rssi_threshold')) {
      context.handle(
        _rssiThresholdMeta,
        rssiThreshold.isAcceptableOrUnknown(
          data['rssi_threshold']!,
          _rssiThresholdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rssiThresholdMeta);
    }
    if (data.containsKey('sound_enabled')) {
      context.handle(
        _soundEnabledMeta,
        soundEnabled.isAcceptableOrUnknown(
          data['sound_enabled']!,
          _soundEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_soundEnabledMeta);
    }
    if (data.containsKey('vibration_enabled')) {
      context.handle(
        _vibrationEnabledMeta,
        vibrationEnabled.isAcceptableOrUnknown(
          data['vibration_enabled']!,
          _vibrationEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vibrationEnabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsDataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsDataRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: $AppSettingsRowsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      singletonKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}singleton_key'],
      )!,
      scanDurationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_duration_seconds'],
      )!,
      rssiThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rssi_threshold'],
      )!,
      soundEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sound_enabled'],
      )!,
      vibrationEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vibration_enabled'],
      )!,
    );
  }

  @override
  $AppSettingsRowsTable createAlias(String alias) {
    return $AppSettingsRowsTable(attachedDatabase, alias);
  }

  static TypeConverter<domain.SyncStatus, String> $convertersyncStatus =
      const SyncStatusConverter();
}

class AppSettingsDataRow extends DataClass
    implements Insertable<AppSettingsDataRow> {
  final String id;
  final DateTime updatedAt;
  final domain.SyncStatus syncStatus;
  final String singletonKey;
  final int scanDurationSeconds;
  final int rssiThreshold;
  final bool soundEnabled;
  final bool vibrationEnabled;
  const AppSettingsDataRow({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.singletonKey,
    required this.scanDurationSeconds,
    required this.rssiThreshold,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['sync_status'] = Variable<String>(
        $AppSettingsRowsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    map['singleton_key'] = Variable<String>(singletonKey);
    map['scan_duration_seconds'] = Variable<int>(scanDurationSeconds);
    map['rssi_threshold'] = Variable<int>(rssiThreshold);
    map['sound_enabled'] = Variable<bool>(soundEnabled);
    map['vibration_enabled'] = Variable<bool>(vibrationEnabled);
    return map;
  }

  AppSettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsRowsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      singletonKey: Value(singletonKey),
      scanDurationSeconds: Value(scanDurationSeconds),
      rssiThreshold: Value(rssiThreshold),
      soundEnabled: Value(soundEnabled),
      vibrationEnabled: Value(vibrationEnabled),
    );
  }

  factory AppSettingsDataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsDataRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncStatus: serializer.fromJson<domain.SyncStatus>(json['syncStatus']),
      singletonKey: serializer.fromJson<String>(json['singletonKey']),
      scanDurationSeconds: serializer.fromJson<int>(
        json['scanDurationSeconds'],
      ),
      rssiThreshold: serializer.fromJson<int>(json['rssiThreshold']),
      soundEnabled: serializer.fromJson<bool>(json['soundEnabled']),
      vibrationEnabled: serializer.fromJson<bool>(json['vibrationEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncStatus': serializer.toJson<domain.SyncStatus>(syncStatus),
      'singletonKey': serializer.toJson<String>(singletonKey),
      'scanDurationSeconds': serializer.toJson<int>(scanDurationSeconds),
      'rssiThreshold': serializer.toJson<int>(rssiThreshold),
      'soundEnabled': serializer.toJson<bool>(soundEnabled),
      'vibrationEnabled': serializer.toJson<bool>(vibrationEnabled),
    };
  }

  AppSettingsDataRow copyWith({
    String? id,
    DateTime? updatedAt,
    domain.SyncStatus? syncStatus,
    String? singletonKey,
    int? scanDurationSeconds,
    int? rssiThreshold,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) => AppSettingsDataRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    singletonKey: singletonKey ?? this.singletonKey,
    scanDurationSeconds: scanDurationSeconds ?? this.scanDurationSeconds,
    rssiThreshold: rssiThreshold ?? this.rssiThreshold,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
  );
  AppSettingsDataRow copyWithCompanion(AppSettingsRowsCompanion data) {
    return AppSettingsDataRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      singletonKey: data.singletonKey.present
          ? data.singletonKey.value
          : this.singletonKey,
      scanDurationSeconds: data.scanDurationSeconds.present
          ? data.scanDurationSeconds.value
          : this.scanDurationSeconds,
      rssiThreshold: data.rssiThreshold.present
          ? data.rssiThreshold.value
          : this.rssiThreshold,
      soundEnabled: data.soundEnabled.present
          ? data.soundEnabled.value
          : this.soundEnabled,
      vibrationEnabled: data.vibrationEnabled.present
          ? data.vibrationEnabled.value
          : this.vibrationEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsDataRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('singletonKey: $singletonKey, ')
          ..write('scanDurationSeconds: $scanDurationSeconds, ')
          ..write('rssiThreshold: $rssiThreshold, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('vibrationEnabled: $vibrationEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    syncStatus,
    singletonKey,
    scanDurationSeconds,
    rssiThreshold,
    soundEnabled,
    vibrationEnabled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsDataRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.singletonKey == this.singletonKey &&
          other.scanDurationSeconds == this.scanDurationSeconds &&
          other.rssiThreshold == this.rssiThreshold &&
          other.soundEnabled == this.soundEnabled &&
          other.vibrationEnabled == this.vibrationEnabled);
}

class AppSettingsRowsCompanion extends UpdateCompanion<AppSettingsDataRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<domain.SyncStatus> syncStatus;
  final Value<String> singletonKey;
  final Value<int> scanDurationSeconds;
  final Value<int> rssiThreshold;
  final Value<bool> soundEnabled;
  final Value<bool> vibrationEnabled;
  final Value<int> rowid;
  const AppSettingsRowsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.singletonKey = const Value.absent(),
    this.scanDurationSeconds = const Value.absent(),
    this.rssiThreshold = const Value.absent(),
    this.soundEnabled = const Value.absent(),
    this.vibrationEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsRowsCompanion.insert({
    required String id,
    required DateTime updatedAt,
    required domain.SyncStatus syncStatus,
    this.singletonKey = const Value.absent(),
    required int scanDurationSeconds,
    required int rssiThreshold,
    required bool soundEnabled,
    required bool vibrationEnabled,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       syncStatus = Value(syncStatus),
       scanDurationSeconds = Value(scanDurationSeconds),
       rssiThreshold = Value(rssiThreshold),
       soundEnabled = Value(soundEnabled),
       vibrationEnabled = Value(vibrationEnabled);
  static Insertable<AppSettingsDataRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncStatus,
    Expression<String>? singletonKey,
    Expression<int>? scanDurationSeconds,
    Expression<int>? rssiThreshold,
    Expression<bool>? soundEnabled,
    Expression<bool>? vibrationEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (singletonKey != null) 'singleton_key': singletonKey,
      if (scanDurationSeconds != null)
        'scan_duration_seconds': scanDurationSeconds,
      if (rssiThreshold != null) 'rssi_threshold': rssiThreshold,
      if (soundEnabled != null) 'sound_enabled': soundEnabled,
      if (vibrationEnabled != null) 'vibration_enabled': vibrationEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsRowsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<domain.SyncStatus>? syncStatus,
    Value<String>? singletonKey,
    Value<int>? scanDurationSeconds,
    Value<int>? rssiThreshold,
    Value<bool>? soundEnabled,
    Value<bool>? vibrationEnabled,
    Value<int>? rowid,
  }) {
    return AppSettingsRowsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      singletonKey: singletonKey ?? this.singletonKey,
      scanDurationSeconds: scanDurationSeconds ?? this.scanDurationSeconds,
      rssiThreshold: rssiThreshold ?? this.rssiThreshold,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $AppSettingsRowsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (singletonKey.present) {
      map['singleton_key'] = Variable<String>(singletonKey.value);
    }
    if (scanDurationSeconds.present) {
      map['scan_duration_seconds'] = Variable<int>(scanDurationSeconds.value);
    }
    if (rssiThreshold.present) {
      map['rssi_threshold'] = Variable<int>(rssiThreshold.value);
    }
    if (soundEnabled.present) {
      map['sound_enabled'] = Variable<bool>(soundEnabled.value);
    }
    if (vibrationEnabled.present) {
      map['vibration_enabled'] = Variable<bool>(vibrationEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRowsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('singletonKey: $singletonKey, ')
          ..write('scanDurationSeconds: $scanDurationSeconds, ')
          ..write('rssiThreshold: $rssiThreshold, ')
          ..write('soundEnabled: $soundEnabled, ')
          ..write('vibrationEnabled: $vibrationEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TeachersTable teachers = $TeachersTable(this);
  late final $StudentsTable students = $StudentsTable(this);
  late final $ClassSectionsTable classSections = $ClassSectionsTable(this);
  late final $EnrollmentsTable enrollments = $EnrollmentsTable(this);
  late final $AttendanceSessionsTable attendanceSessions =
      $AttendanceSessionsTable(this);
  late final $AttendanceRecordsTable attendanceRecords =
      $AttendanceRecordsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $AppSettingsRowsTable appSettingsRows = $AppSettingsRowsTable(
    this,
  );
  late final Index enrollmentsStudentClassUnique = Index(
    'enrollments_student_class_unique',
    'CREATE UNIQUE INDEX enrollments_student_class_unique ON enrollments (student_id, class_section_id)',
  );
  late final Index attendanceRecordsSessionStudentUnique = Index(
    'attendance_records_session_student_unique',
    'CREATE UNIQUE INDEX attendance_records_session_student_unique ON attendance_records (session_id, student_id)',
  );
  late final TeacherDao teacherDao = TeacherDao(this as AppDatabase);
  late final StudentDao studentDao = StudentDao(this as AppDatabase);
  late final ClassDao classDao = ClassDao(this as AppDatabase);
  late final EnrollmentDao enrollmentDao = EnrollmentDao(this as AppDatabase);
  late final AttendanceDao attendanceDao = AttendanceDao(this as AppDatabase);
  late final DeviceDao deviceDao = DeviceDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    teachers,
    students,
    classSections,
    enrollments,
    attendanceSessions,
    attendanceRecords,
    devices,
    appSettingsRows,
    enrollmentsStudentClassUnique,
    attendanceRecordsSessionStudentUnique,
  ];
}

typedef $$TeachersTableCreateCompanionBuilder = TeachersCompanion Function({
  required String id,
  required DateTime updatedAt,
  required domain.SyncStatus syncStatus,
  required String name,
  Value<int> rowid,
});
typedef $$TeachersTableUpdateCompanionBuilder = TeachersCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<domain.SyncStatus> syncStatus,
  Value<String> name,
  Value<int> rowid,
});

final class $$TeachersTableReferences
    extends BaseReferences<_$AppDatabase, $TeachersTable, TeacherRow> {
  $$TeachersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ClassSectionsTable, List<ClassSectionRow>>
  _classSectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.classSections,
    aliasName: 'teachers__id__class_sections__teacher_id',
  );

  $$ClassSectionsTableProcessedTableManager get classSectionsRefs {
    final manager = $$ClassSectionsTableTableManager(
      $_db,
      $_db.classSections,
    ).filter((f) => f.teacherId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_classSectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeachersTableFilterComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> classSectionsRefs(
    Expression<bool> Function($$ClassSectionsTableFilterComposer f) f,
  ) {
    final $$ClassSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.teacherId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableFilterComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeachersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TeachersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeachersTable> {
  $$TeachersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> classSectionsRefs<T extends Object>(
    Expression<T> Function($$ClassSectionsTableAnnotationComposer a) f,
  ) {
    final $$ClassSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.teacherId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeachersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeachersTable,
          TeacherRow,
          $$TeachersTableFilterComposer,
          $$TeachersTableOrderingComposer,
          $$TeachersTableAnnotationComposer,
          $$TeachersTableCreateCompanionBuilder,
          $$TeachersTableUpdateCompanionBuilder,
          (TeacherRow, $$TeachersTableReferences),
          TeacherRow,
          PrefetchHooks Function({bool classSectionsRefs})
        > {
  $$TeachersTableTableManager(_$AppDatabase db, $TeachersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeachersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeachersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeachersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeachersCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => TeachersCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeachersTable, TeacherRow>(table),
                  $$TeachersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({classSectionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (classSectionsRefs) db.classSections,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (classSectionsRefs)
                    await $_getPrefetchedData<
                      TeacherRow,
                      $TeachersTable,
                      ClassSectionRow
                    >(
                      currentTable: table,
                      referencedTable: $$TeachersTableReferences
                          ._classSectionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TeachersTableReferences(
                        db,
                        table,
                        p0,
                      ).classSectionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.teacherId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TeachersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeachersTable,
      TeacherRow,
      $$TeachersTableFilterComposer,
      $$TeachersTableOrderingComposer,
      $$TeachersTableAnnotationComposer,
      $$TeachersTableCreateCompanionBuilder,
      $$TeachersTableUpdateCompanionBuilder,
      (TeacherRow, $$TeachersTableReferences),
      TeacherRow,
      PrefetchHooks Function({bool classSectionsRefs})
    >;
typedef $$StudentsTableCreateCompanionBuilder = StudentsCompanion Function({
  required String id,
  required DateTime updatedAt,
  required domain.SyncStatus syncStatus,
  required String studentNumber,
  required String fullName,
  Value<bool> isCurrent,
  Value<int> rowid,
});
typedef $$StudentsTableUpdateCompanionBuilder = StudentsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<domain.SyncStatus> syncStatus,
  Value<String> studentNumber,
  Value<String> fullName,
  Value<bool> isCurrent,
  Value<int> rowid,
});

final class $$StudentsTableReferences
    extends BaseReferences<_$AppDatabase, $StudentsTable, StudentRow> {
  $$StudentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EnrollmentsTable, List<EnrollmentRow>>
  _enrollmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.enrollments,
    aliasName: 'students__id__enrollments__student_id',
  );

  $$EnrollmentsTableProcessedTableManager get enrollmentsRefs {
    final manager = $$EnrollmentsTableTableManager(
      $_db,
      $_db.enrollments,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_enrollmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttendanceRecordsTable, List<AttendanceRecordRow>>
  _attendanceRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceRecords,
        aliasName: 'students__id__attendance_records__student_id',
      );

  $$AttendanceRecordsTableProcessedTableManager get attendanceRecordsRefs {
    final manager = $$AttendanceRecordsTableTableManager(
      $_db,
      $_db.attendanceRecords,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DevicesTable, List<DeviceRow>> _devicesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.devices,
    aliasName: 'students__id__devices__student_id',
  );

  $$DevicesTableProcessedTableManager get devicesRefs {
    final manager = $$DevicesTableTableManager(
      $_db,
      $_db.devices,
    ).filter((f) => f.studentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudentsTableFilterComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> enrollmentsRefs(
    Expression<bool> Function($$EnrollmentsTableFilterComposer f) f,
  ) {
    final $$EnrollmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrollments,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrollmentsTableFilterComposer(
            $db: $db,
            $table: $db.enrollments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attendanceRecordsRefs(
    Expression<bool> Function($$AttendanceRecordsTableFilterComposer f) f,
  ) {
    final $$AttendanceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceRecords,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> devicesRefs(
    Expression<bool> Function($$DevicesTableFilterComposer f) f,
  ) {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableFilterComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudentsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentsTable> {
  $$StudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get studentNumber => $composableBuilder(
    column: $table.studentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  Expression<T> enrollmentsRefs<T extends Object>(
    Expression<T> Function($$EnrollmentsTableAnnotationComposer a) f,
  ) {
    final $$EnrollmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrollments,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrollmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.enrollments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attendanceRecordsRefs<T extends Object>(
    Expression<T> Function($$AttendanceRecordsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceRecords,
          getReferencedColumn: (t) => t.studentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> devicesRefs<T extends Object>(
    Expression<T> Function($$DevicesTableAnnotationComposer a) f,
  ) {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.devices,
      getReferencedColumn: (t) => t.studentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.devices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentsTable,
          StudentRow,
          $$StudentsTableFilterComposer,
          $$StudentsTableOrderingComposer,
          $$StudentsTableAnnotationComposer,
          $$StudentsTableCreateCompanionBuilder,
          $$StudentsTableUpdateCompanionBuilder,
          (StudentRow, $$StudentsTableReferences),
          StudentRow,
          PrefetchHooks Function({
            bool enrollmentsRefs,
            bool attendanceRecordsRefs,
            bool devicesRefs,
          })
        > {
  $$StudentsTableTableManager(_$AppDatabase db, $StudentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<String> studentNumber = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                studentNumber: studentNumber,
                fullName: fullName,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                required String studentNumber,
                required String fullName,
                Value<bool> isCurrent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                studentNumber: studentNumber,
                fullName: fullName,
                isCurrent: isCurrent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StudentsTable, StudentRow>(table),
                  $$StudentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                enrollmentsRefs = false,
                attendanceRecordsRefs = false,
                devicesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (enrollmentsRefs) db.enrollments,
                    if (attendanceRecordsRefs) db.attendanceRecords,
                    if (devicesRefs) db.devices,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (enrollmentsRefs)
                        await $_getPrefetchedData<
                          StudentRow,
                          $StudentsTable,
                          EnrollmentRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._enrollmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).enrollmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attendanceRecordsRefs)
                        await $_getPrefetchedData<
                          StudentRow,
                          $StudentsTable,
                          AttendanceRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._attendanceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (devicesRefs)
                        await $_getPrefetchedData<
                          StudentRow,
                          $StudentsTable,
                          DeviceRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudentsTableReferences
                              ._devicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudentsTableReferences(
                                db,
                                table,
                                p0,
                              ).devicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studentId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StudentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentsTable,
      StudentRow,
      $$StudentsTableFilterComposer,
      $$StudentsTableOrderingComposer,
      $$StudentsTableAnnotationComposer,
      $$StudentsTableCreateCompanionBuilder,
      $$StudentsTableUpdateCompanionBuilder,
      (StudentRow, $$StudentsTableReferences),
      StudentRow,
      PrefetchHooks Function({
        bool enrollmentsRefs,
        bool attendanceRecordsRefs,
        bool devicesRefs,
      })
    >;
typedef $$ClassSectionsTableCreateCompanionBuilder =
    ClassSectionsCompanion Function({
      required String id,
      required DateTime updatedAt,
      required domain.SyncStatus syncStatus,
      required int gradeLevel,
      required String sectionLabel,
      required String sectionCode,
      Value<String> subject,
      required String room,
      required DateTime scheduleStart,
      required DateTime scheduleEnd,
      required String bleBeaconId,
      required String teacherId,
      Value<int> rowid,
    });
typedef $$ClassSectionsTableUpdateCompanionBuilder =
    ClassSectionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<domain.SyncStatus> syncStatus,
      Value<int> gradeLevel,
      Value<String> sectionLabel,
      Value<String> sectionCode,
      Value<String> subject,
      Value<String> room,
      Value<DateTime> scheduleStart,
      Value<DateTime> scheduleEnd,
      Value<String> bleBeaconId,
      Value<String> teacherId,
      Value<int> rowid,
    });

final class $$ClassSectionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ClassSectionsTable, ClassSectionRow> {
  $$ClassSectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TeachersTable _teacherIdTable(_$AppDatabase db) =>
      db.teachers.createAlias('class_sections__teacher_id__teachers__id');

  $$TeachersTableProcessedTableManager get teacherId {
    final $_column = $_itemColumn<String>('teacher_id')!;

    final manager = $$TeachersTableTableManager(
      $_db,
      $_db.teachers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teacherIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EnrollmentsTable, List<EnrollmentRow>>
  _enrollmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.enrollments,
    aliasName: 'class_sections__id__enrollments__class_section_id',
  );

  $$EnrollmentsTableProcessedTableManager get enrollmentsRefs {
    final manager = $$EnrollmentsTableTableManager(
      $_db,
      $_db.enrollments,
    ).filter((f) => f.classSectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_enrollmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AttendanceSessionsTable,
    List<AttendanceSessionRow>
  >
  _attendanceSessionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceSessions,
        aliasName: 'class_sections__id__attendance_sessions__class_section_id',
      );

  $$AttendanceSessionsTableProcessedTableManager get attendanceSessionsRefs {
    final manager = $$AttendanceSessionsTableTableManager(
      $_db,
      $_db.attendanceSessions,
    ).filter((f) => f.classSectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClassSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ClassSectionsTable> {
  $$ClassSectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionLabel => $composableBuilder(
    column: $table.sectionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionCode => $composableBuilder(
    column: $table.sectionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduleStart => $composableBuilder(
    column: $table.scheduleStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduleEnd => $composableBuilder(
    column: $table.scheduleEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bleBeaconId => $composableBuilder(
    column: $table.bleBeaconId,
    builder: (column) => ColumnFilters(column),
  );

  $$TeachersTableFilterComposer get teacherId {
    final $$TeachersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teacherId,
      referencedTable: $db.teachers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeachersTableFilterComposer(
            $db: $db,
            $table: $db.teachers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> enrollmentsRefs(
    Expression<bool> Function($$EnrollmentsTableFilterComposer f) f,
  ) {
    final $$EnrollmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrollments,
      getReferencedColumn: (t) => t.classSectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrollmentsTableFilterComposer(
            $db: $db,
            $table: $db.enrollments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attendanceSessionsRefs(
    Expression<bool> Function($$AttendanceSessionsTableFilterComposer f) f,
  ) {
    final $$AttendanceSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceSessions,
      getReferencedColumn: (t) => t.classSectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceSessionsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClassSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClassSectionsTable> {
  $$ClassSectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionLabel => $composableBuilder(
    column: $table.sectionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionCode => $composableBuilder(
    column: $table.sectionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get room => $composableBuilder(
    column: $table.room,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduleStart => $composableBuilder(
    column: $table.scheduleStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduleEnd => $composableBuilder(
    column: $table.scheduleEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bleBeaconId => $composableBuilder(
    column: $table.bleBeaconId,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeachersTableOrderingComposer get teacherId {
    final $$TeachersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teacherId,
      referencedTable: $db.teachers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeachersTableOrderingComposer(
            $db: $db,
            $table: $db.teachers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClassSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClassSectionsTable> {
  $$ClassSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get gradeLevel => $composableBuilder(
    column: $table.gradeLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionLabel => $composableBuilder(
    column: $table.sectionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionCode => $composableBuilder(
    column: $table.sectionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get room =>
      $composableBuilder(column: $table.room, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduleStart => $composableBuilder(
    column: $table.scheduleStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduleEnd => $composableBuilder(
    column: $table.scheduleEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bleBeaconId => $composableBuilder(
    column: $table.bleBeaconId,
    builder: (column) => column,
  );

  $$TeachersTableAnnotationComposer get teacherId {
    final $$TeachersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teacherId,
      referencedTable: $db.teachers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeachersTableAnnotationComposer(
            $db: $db,
            $table: $db.teachers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> enrollmentsRefs<T extends Object>(
    Expression<T> Function($$EnrollmentsTableAnnotationComposer a) f,
  ) {
    final $$EnrollmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrollments,
      getReferencedColumn: (t) => t.classSectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrollmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.enrollments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attendanceSessionsRefs<T extends Object>(
    Expression<T> Function($$AttendanceSessionsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceSessions,
          getReferencedColumn: (t) => t.classSectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ClassSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClassSectionsTable,
          ClassSectionRow,
          $$ClassSectionsTableFilterComposer,
          $$ClassSectionsTableOrderingComposer,
          $$ClassSectionsTableAnnotationComposer,
          $$ClassSectionsTableCreateCompanionBuilder,
          $$ClassSectionsTableUpdateCompanionBuilder,
          (ClassSectionRow, $$ClassSectionsTableReferences),
          ClassSectionRow,
          PrefetchHooks Function({
            bool teacherId,
            bool enrollmentsRefs,
            bool attendanceSessionsRefs,
          })
        > {
  $$ClassSectionsTableTableManager(_$AppDatabase db, $ClassSectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClassSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClassSectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClassSectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<int> gradeLevel = const Value.absent(),
                Value<String> sectionLabel = const Value.absent(),
                Value<String> sectionCode = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> room = const Value.absent(),
                Value<DateTime> scheduleStart = const Value.absent(),
                Value<DateTime> scheduleEnd = const Value.absent(),
                Value<String> bleBeaconId = const Value.absent(),
                Value<String> teacherId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClassSectionsCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                gradeLevel: gradeLevel,
                sectionLabel: sectionLabel,
                sectionCode: sectionCode,
                subject: subject,
                room: room,
                scheduleStart: scheduleStart,
                scheduleEnd: scheduleEnd,
                bleBeaconId: bleBeaconId,
                teacherId: teacherId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                required int gradeLevel,
                required String sectionLabel,
                required String sectionCode,
                Value<String> subject = const Value.absent(),
                required String room,
                required DateTime scheduleStart,
                required DateTime scheduleEnd,
                required String bleBeaconId,
                required String teacherId,
                Value<int> rowid = const Value.absent(),
              }) => ClassSectionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                gradeLevel: gradeLevel,
                sectionLabel: sectionLabel,
                sectionCode: sectionCode,
                subject: subject,
                room: room,
                scheduleStart: scheduleStart,
                scheduleEnd: scheduleEnd,
                bleBeaconId: bleBeaconId,
                teacherId: teacherId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClassSectionsTable, ClassSectionRow>(table),
                  $$ClassSectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                teacherId = false,
                enrollmentsRefs = false,
                attendanceSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (enrollmentsRefs) db.enrollments,
                    if (attendanceSessionsRefs) db.attendanceSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (teacherId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.teacherId,
                            referencedTable: $$ClassSectionsTableReferences
                                ._teacherIdTable(db),
                            referencedColumn: $$ClassSectionsTableReferences
                                ._teacherIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (enrollmentsRefs)
                        await $_getPrefetchedData<
                          ClassSectionRow,
                          $ClassSectionsTable,
                          EnrollmentRow
                        >(
                          currentTable: table,
                          referencedTable: $$ClassSectionsTableReferences
                              ._enrollmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassSectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).enrollmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classSectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attendanceSessionsRefs)
                        await $_getPrefetchedData<
                          ClassSectionRow,
                          $ClassSectionsTable,
                          AttendanceSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ClassSectionsTableReferences
                              ._attendanceSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClassSectionsTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.classSectionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ClassSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClassSectionsTable,
      ClassSectionRow,
      $$ClassSectionsTableFilterComposer,
      $$ClassSectionsTableOrderingComposer,
      $$ClassSectionsTableAnnotationComposer,
      $$ClassSectionsTableCreateCompanionBuilder,
      $$ClassSectionsTableUpdateCompanionBuilder,
      (ClassSectionRow, $$ClassSectionsTableReferences),
      ClassSectionRow,
      PrefetchHooks Function({
        bool teacherId,
        bool enrollmentsRefs,
        bool attendanceSessionsRefs,
      })
    >;
typedef $$EnrollmentsTableCreateCompanionBuilder =
    EnrollmentsCompanion Function({
      required String id,
      required DateTime updatedAt,
      required domain.SyncStatus syncStatus,
      required String studentId,
      required String classSectionId,
      Value<int> rowid,
    });
typedef $$EnrollmentsTableUpdateCompanionBuilder =
    EnrollmentsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<domain.SyncStatus> syncStatus,
      Value<String> studentId,
      Value<String> classSectionId,
      Value<int> rowid,
    });

final class $$EnrollmentsTableReferences
    extends BaseReferences<_$AppDatabase, $EnrollmentsTable, EnrollmentRow> {
  $$EnrollmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StudentsTable _studentIdTable(_$AppDatabase db) =>
      db.students.createAlias('enrollments__student_id__students__id');

  $$StudentsTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<String>('student_id')!;

    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ClassSectionsTable _classSectionIdTable(_$AppDatabase db) => db
      .classSections
      .createAlias('enrollments__class_section_id__class_sections__id');

  $$ClassSectionsTableProcessedTableManager get classSectionId {
    final $_column = $_itemColumn<String>('class_section_id')!;

    final manager = $$ClassSectionsTableTableManager(
      $_db,
      $_db.classSections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classSectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EnrollmentsTableFilterComposer
    extends Composer<_$AppDatabase, $EnrollmentsTable> {
  $$EnrollmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassSectionsTableFilterComposer get classSectionId {
    final $$ClassSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classSectionId,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableFilterComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrollmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $EnrollmentsTable> {
  $$EnrollmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassSectionsTableOrderingComposer get classSectionId {
    final $$ClassSectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classSectionId,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableOrderingComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrollmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnrollmentsTable> {
  $$EnrollmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClassSectionsTableAnnotationComposer get classSectionId {
    final $$ClassSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classSectionId,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrollmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnrollmentsTable,
          EnrollmentRow,
          $$EnrollmentsTableFilterComposer,
          $$EnrollmentsTableOrderingComposer,
          $$EnrollmentsTableAnnotationComposer,
          $$EnrollmentsTableCreateCompanionBuilder,
          $$EnrollmentsTableUpdateCompanionBuilder,
          (EnrollmentRow, $$EnrollmentsTableReferences),
          EnrollmentRow,
          PrefetchHooks Function({bool studentId, bool classSectionId})
        > {
  $$EnrollmentsTableTableManager(_$AppDatabase db, $EnrollmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnrollmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnrollmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnrollmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> classSectionId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnrollmentsCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                studentId: studentId,
                classSectionId: classSectionId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                required String studentId,
                required String classSectionId,
                Value<int> rowid = const Value.absent(),
              }) => EnrollmentsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                studentId: studentId,
                classSectionId: classSectionId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EnrollmentsTable, EnrollmentRow>(table),
                  $$EnrollmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentId = false, classSectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.studentId,
                        referencedTable: $$EnrollmentsTableReferences
                            ._studentIdTable(db),
                        referencedColumn: $$EnrollmentsTableReferences
                            ._studentIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (classSectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.classSectionId,
                        referencedTable: $$EnrollmentsTableReferences
                            ._classSectionIdTable(db),
                        referencedColumn: $$EnrollmentsTableReferences
                            ._classSectionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EnrollmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnrollmentsTable,
      EnrollmentRow,
      $$EnrollmentsTableFilterComposer,
      $$EnrollmentsTableOrderingComposer,
      $$EnrollmentsTableAnnotationComposer,
      $$EnrollmentsTableCreateCompanionBuilder,
      $$EnrollmentsTableUpdateCompanionBuilder,
      (EnrollmentRow, $$EnrollmentsTableReferences),
      EnrollmentRow,
      PrefetchHooks Function({bool studentId, bool classSectionId})
    >;
typedef $$AttendanceSessionsTableCreateCompanionBuilder =
    AttendanceSessionsCompanion Function({
      required String id,
      required DateTime updatedAt,
      required domain.SyncStatus syncStatus,
      required String classSectionId,
      Value<String> title,
      required DateTime date,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> scanDurationSeconds,
      required domain.AttendanceSessionStatus status,
      Value<int> rowid,
    });
typedef $$AttendanceSessionsTableUpdateCompanionBuilder =
    AttendanceSessionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<domain.SyncStatus> syncStatus,
      Value<String> classSectionId,
      Value<String> title,
      Value<DateTime> date,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> scanDurationSeconds,
      Value<domain.AttendanceSessionStatus> status,
      Value<int> rowid,
    });

final class $$AttendanceSessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceSessionsTable,
          AttendanceSessionRow
        > {
  $$AttendanceSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClassSectionsTable _classSectionIdTable(_$AppDatabase db) => db
      .classSections
      .createAlias('attendance_sessions__class_section_id__class_sections__id');

  $$ClassSectionsTableProcessedTableManager get classSectionId {
    final $_column = $_itemColumn<String>('class_section_id')!;

    final manager = $$ClassSectionsTableTableManager(
      $_db,
      $_db.classSections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classSectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttendanceRecordsTable, List<AttendanceRecordRow>>
  _attendanceRecordsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attendanceRecords,
        aliasName: 'attendance_sessions__id__attendance_records__session_id',
      );

  $$AttendanceRecordsTableProcessedTableManager get attendanceRecordsRefs {
    final manager = $$AttendanceRecordsTableTableManager(
      $_db,
      $_db.attendanceRecords,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attendanceRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AttendanceSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanDurationSeconds => $composableBuilder(
    column: $table.scanDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    domain.AttendanceSessionStatus,
    domain.AttendanceSessionStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$ClassSectionsTableFilterComposer get classSectionId {
    final $$ClassSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classSectionId,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableFilterComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attendanceRecordsRefs(
    Expression<bool> Function($$AttendanceRecordsTableFilterComposer f) f,
  ) {
    final $$AttendanceRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attendanceRecords,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceRecordsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AttendanceSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanDurationSeconds => $composableBuilder(
    column: $table.scanDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClassSectionsTableOrderingComposer get classSectionId {
    final $$ClassSectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classSectionId,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableOrderingComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceSessionsTable> {
  $$AttendanceSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get scanDurationSeconds => $composableBuilder(
    column: $table.scanDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<domain.AttendanceSessionStatus, String>
  get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$ClassSectionsTableAnnotationComposer get classSectionId {
    final $$ClassSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.classSectionId,
      referencedTable: $db.classSections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClassSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.classSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attendanceRecordsRefs<T extends Object>(
    Expression<T> Function($$AttendanceRecordsTableAnnotationComposer a) f,
  ) {
    final $$AttendanceRecordsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attendanceRecords,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceRecordsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceRecords,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AttendanceSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceSessionsTable,
          AttendanceSessionRow,
          $$AttendanceSessionsTableFilterComposer,
          $$AttendanceSessionsTableOrderingComposer,
          $$AttendanceSessionsTableAnnotationComposer,
          $$AttendanceSessionsTableCreateCompanionBuilder,
          $$AttendanceSessionsTableUpdateCompanionBuilder,
          (AttendanceSessionRow, $$AttendanceSessionsTableReferences),
          AttendanceSessionRow,
          PrefetchHooks Function({
            bool classSectionId,
            bool attendanceRecordsRefs,
          })
        > {
  $$AttendanceSessionsTableTableManager(
    _$AppDatabase db,
    $AttendanceSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<String> classSectionId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> scanDurationSeconds = const Value.absent(),
                Value<domain.AttendanceSessionStatus> status =
                    const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceSessionsCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                classSectionId: classSectionId,
                title: title,
                date: date,
                startedAt: startedAt,
                endedAt: endedAt,
                scanDurationSeconds: scanDurationSeconds,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                required String classSectionId,
                Value<String> title = const Value.absent(),
                required DateTime date,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> scanDurationSeconds = const Value.absent(),
                required domain.AttendanceSessionStatus status,
                Value<int> rowid = const Value.absent(),
              }) => AttendanceSessionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                classSectionId: classSectionId,
                title: title,
                date: date,
                startedAt: startedAt,
                endedAt: endedAt,
                scanDurationSeconds: scanDurationSeconds,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttendanceSessionsTable, AttendanceSessionRow>(
                    table,
                  ),
                  $$AttendanceSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({classSectionId = false, attendanceRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attendanceRecordsRefs) db.attendanceRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (classSectionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.classSectionId,
                            referencedTable: $$AttendanceSessionsTableReferences
                                ._classSectionIdTable(db),
                            referencedColumn:
                                $$AttendanceSessionsTableReferences
                                    ._classSectionIdTable(db)
                                    .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attendanceRecordsRefs)
                        await $_getPrefetchedData<
                          AttendanceSessionRow,
                          $AttendanceSessionsTable,
                          AttendanceRecordRow
                        >(
                          currentTable: table,
                          referencedTable: $$AttendanceSessionsTableReferences
                              ._attendanceRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AttendanceSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).attendanceRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AttendanceSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceSessionsTable,
      AttendanceSessionRow,
      $$AttendanceSessionsTableFilterComposer,
      $$AttendanceSessionsTableOrderingComposer,
      $$AttendanceSessionsTableAnnotationComposer,
      $$AttendanceSessionsTableCreateCompanionBuilder,
      $$AttendanceSessionsTableUpdateCompanionBuilder,
      (AttendanceSessionRow, $$AttendanceSessionsTableReferences),
      AttendanceSessionRow,
      PrefetchHooks Function({bool classSectionId, bool attendanceRecordsRefs})
    >;
typedef $$AttendanceRecordsTableCreateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      required String id,
      required DateTime updatedAt,
      required domain.SyncStatus syncStatus,
      required String sessionId,
      required String studentId,
      required domain.AttendanceRecordStatus status,
      Value<int?> rssi,
      Value<DateTime?> detectedAt,
      Value<int> rowid,
    });
typedef $$AttendanceRecordsTableUpdateCompanionBuilder =
    AttendanceRecordsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<domain.SyncStatus> syncStatus,
      Value<String> sessionId,
      Value<String> studentId,
      Value<domain.AttendanceRecordStatus> status,
      Value<int?> rssi,
      Value<DateTime?> detectedAt,
      Value<int> rowid,
    });

final class $$AttendanceRecordsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecordRow
        > {
  $$AttendanceRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AttendanceSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .attendanceSessions
      .createAlias('attendance_records__session_id__attendance_sessions__id');

  $$AttendanceSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$AttendanceSessionsTableTableManager(
      $_db,
      $_db.attendanceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StudentsTable _studentIdTable(_$AppDatabase db) =>
      db.students.createAlias('attendance_records__student_id__students__id');

  $$StudentsTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<String>('student_id')!;

    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttendanceRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    domain.AttendanceRecordStatus,
    domain.AttendanceRecordStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AttendanceSessionsTableFilterComposer get sessionId {
    final $$AttendanceSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.attendanceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceSessionsTableFilterComposer(
            $db: $db,
            $table: $db.attendanceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rssi => $composableBuilder(
    column: $table.rssi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AttendanceSessionsTableOrderingComposer get sessionId {
    final $$AttendanceSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.attendanceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttendanceSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.attendanceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttendanceRecordsTable> {
  $$AttendanceRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<domain.AttendanceRecordStatus, String>
  get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get rssi =>
      $composableBuilder(column: $table.rssi, builder: (column) => column);

  GeneratedColumn<DateTime> get detectedAt => $composableBuilder(
    column: $table.detectedAt,
    builder: (column) => column,
  );

  $$AttendanceSessionsTableAnnotationComposer get sessionId {
    final $$AttendanceSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.sessionId,
          referencedTable: $db.attendanceSessions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttendanceSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.attendanceSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttendanceRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttendanceRecordsTable,
          AttendanceRecordRow,
          $$AttendanceRecordsTableFilterComposer,
          $$AttendanceRecordsTableOrderingComposer,
          $$AttendanceRecordsTableAnnotationComposer,
          $$AttendanceRecordsTableCreateCompanionBuilder,
          $$AttendanceRecordsTableUpdateCompanionBuilder,
          (AttendanceRecordRow, $$AttendanceRecordsTableReferences),
          AttendanceRecordRow,
          PrefetchHooks Function({bool sessionId, bool studentId})
        > {
  $$AttendanceRecordsTableTableManager(
    _$AppDatabase db,
    $AttendanceRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttendanceRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttendanceRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttendanceRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<domain.AttendanceRecordStatus> status =
                    const Value.absent(),
                Value<int?> rssi = const Value.absent(),
                Value<DateTime?> detectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordsCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                sessionId: sessionId,
                studentId: studentId,
                status: status,
                rssi: rssi,
                detectedAt: detectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                required String sessionId,
                required String studentId,
                required domain.AttendanceRecordStatus status,
                Value<int?> rssi = const Value.absent(),
                Value<DateTime?> detectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttendanceRecordsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                sessionId: sessionId,
                studentId: studentId,
                status: status,
                rssi: rssi,
                detectedAt: detectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttendanceRecordsTable, AttendanceRecordRow>(
                    table,
                  ),
                  $$AttendanceRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$AttendanceRecordsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$AttendanceRecordsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (studentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.studentId,
                        referencedTable: $$AttendanceRecordsTableReferences
                            ._studentIdTable(db),
                        referencedColumn: $$AttendanceRecordsTableReferences
                            ._studentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttendanceRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttendanceRecordsTable,
      AttendanceRecordRow,
      $$AttendanceRecordsTableFilterComposer,
      $$AttendanceRecordsTableOrderingComposer,
      $$AttendanceRecordsTableAnnotationComposer,
      $$AttendanceRecordsTableCreateCompanionBuilder,
      $$AttendanceRecordsTableUpdateCompanionBuilder,
      (AttendanceRecordRow, $$AttendanceRecordsTableReferences),
      AttendanceRecordRow,
      PrefetchHooks Function({bool sessionId, bool studentId})
    >;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String id,
  required DateTime updatedAt,
  required domain.SyncStatus syncStatus,
  required String studentId,
  required String bleUuid,
  required String deviceModel,
  required DateTime registeredAt,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<domain.SyncStatus> syncStatus,
  Value<String> studentId,
  Value<String> bleUuid,
  Value<String> deviceModel,
  Value<DateTime> registeredAt,
  Value<int> rowid,
});

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, DeviceRow> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StudentsTable _studentIdTable(_$AppDatabase db) =>
      db.students.createAlias('devices__student_id__students__id');

  $$StudentsTableProcessedTableManager get studentId {
    final $_column = $_itemColumn<String>('student_id')!;

    final manager = $$StudentsTableTableManager(
      $_db,
      $_db.students,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get bleUuid => $composableBuilder(
    column: $table.bleUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StudentsTableFilterComposer get studentId {
    final $$StudentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableFilterComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bleUuid => $composableBuilder(
    column: $table.bleUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudentsTableOrderingComposer get studentId {
    final $$StudentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableOrderingComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get bleUuid =>
      $composableBuilder(column: $table.bleUuid, builder: (column) => column);

  GeneratedColumn<String> get deviceModel => $composableBuilder(
    column: $table.deviceModel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get registeredAt => $composableBuilder(
    column: $table.registeredAt,
    builder: (column) => column,
  );

  $$StudentsTableAnnotationComposer get studentId {
    final $$StudentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studentId,
      referencedTable: $db.students,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudentsTableAnnotationComposer(
            $db: $db,
            $table: $db.students,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevicesTable,
          DeviceRow,
          $$DevicesTableFilterComposer,
          $$DevicesTableOrderingComposer,
          $$DevicesTableAnnotationComposer,
          $$DevicesTableCreateCompanionBuilder,
          $$DevicesTableUpdateCompanionBuilder,
          (DeviceRow, $$DevicesTableReferences),
          DeviceRow,
          PrefetchHooks Function({bool studentId})
        > {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<String> studentId = const Value.absent(),
                Value<String> bleUuid = const Value.absent(),
                Value<String> deviceModel = const Value.absent(),
                Value<DateTime> registeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                studentId: studentId,
                bleUuid: bleUuid,
                deviceModel: deviceModel,
                registeredAt: registeredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                required String studentId,
                required String bleUuid,
                required String deviceModel,
                required DateTime registeredAt,
                Value<int> rowid = const Value.absent(),
              }) => DevicesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                studentId: studentId,
                bleUuid: bleUuid,
                deviceModel: deviceModel,
                registeredAt: registeredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DevicesTable, DeviceRow>(table),
                  $$DevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.studentId,
                        referencedTable: $$DevicesTableReferences
                            ._studentIdTable(db),
                        referencedColumn: $$DevicesTableReferences
                            ._studentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevicesTable,
      DeviceRow,
      $$DevicesTableFilterComposer,
      $$DevicesTableOrderingComposer,
      $$DevicesTableAnnotationComposer,
      $$DevicesTableCreateCompanionBuilder,
      $$DevicesTableUpdateCompanionBuilder,
      (DeviceRow, $$DevicesTableReferences),
      DeviceRow,
      PrefetchHooks Function({bool studentId})
    >;
typedef $$AppSettingsRowsTableCreateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      required String id,
      required DateTime updatedAt,
      required domain.SyncStatus syncStatus,
      Value<String> singletonKey,
      required int scanDurationSeconds,
      required int rssiThreshold,
      required bool soundEnabled,
      required bool vibrationEnabled,
      Value<int> rowid,
    });
typedef $$AppSettingsRowsTableUpdateCompanionBuilder =
    AppSettingsRowsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<domain.SyncStatus> syncStatus,
      Value<String> singletonKey,
      Value<int> scanDurationSeconds,
      Value<int> rssiThreshold,
      Value<bool> soundEnabled,
      Value<bool> vibrationEnabled,
      Value<int> rowid,
    });

class $$AppSettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<domain.SyncStatus, domain.SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get singletonKey => $composableBuilder(
    column: $table.singletonKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanDurationSeconds => $composableBuilder(
    column: $table.scanDurationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rssiThreshold => $composableBuilder(
    column: $table.rssiThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vibrationEnabled => $composableBuilder(
    column: $table.vibrationEnabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get singletonKey => $composableBuilder(
    column: $table.singletonKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanDurationSeconds => $composableBuilder(
    column: $table.scanDurationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rssiThreshold => $composableBuilder(
    column: $table.rssiThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vibrationEnabled => $composableBuilder(
    column: $table.vibrationEnabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsRowsTable> {
  $$AppSettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<domain.SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get singletonKey => $composableBuilder(
    column: $table.singletonKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scanDurationSeconds => $composableBuilder(
    column: $table.scanDurationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rssiThreshold => $composableBuilder(
    column: $table.rssiThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get soundEnabled => $composableBuilder(
    column: $table.soundEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get vibrationEnabled => $composableBuilder(
    column: $table.vibrationEnabled,
    builder: (column) => column,
  );
}

class $$AppSettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsRowsTable,
          AppSettingsDataRow,
          $$AppSettingsRowsTableFilterComposer,
          $$AppSettingsRowsTableOrderingComposer,
          $$AppSettingsRowsTableAnnotationComposer,
          $$AppSettingsRowsTableCreateCompanionBuilder,
          $$AppSettingsRowsTableUpdateCompanionBuilder,
          (
            AppSettingsDataRow,
            BaseReferences<
              _$AppDatabase,
              $AppSettingsRowsTable,
              AppSettingsDataRow
            >,
          ),
          AppSettingsDataRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsRowsTableTableManager(
    _$AppDatabase db,
    $AppSettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<domain.SyncStatus> syncStatus = const Value.absent(),
                Value<String> singletonKey = const Value.absent(),
                Value<int> scanDurationSeconds = const Value.absent(),
                Value<int> rssiThreshold = const Value.absent(),
                Value<bool> soundEnabled = const Value.absent(),
                Value<bool> vibrationEnabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsRowsCompanion(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                singletonKey: singletonKey,
                scanDurationSeconds: scanDurationSeconds,
                rssiThreshold: rssiThreshold,
                soundEnabled: soundEnabled,
                vibrationEnabled: vibrationEnabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime updatedAt,
                required domain.SyncStatus syncStatus,
                Value<String> singletonKey = const Value.absent(),
                required int scanDurationSeconds,
                required int rssiThreshold,
                required bool soundEnabled,
                required bool vibrationEnabled,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsRowsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                singletonKey: singletonKey,
                scanDurationSeconds: scanDurationSeconds,
                rssiThreshold: rssiThreshold,
                soundEnabled: soundEnabled,
                vibrationEnabled: vibrationEnabled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsRowsTable, AppSettingsDataRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsRowsTable,
                    AppSettingsDataRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsRowsTable,
      AppSettingsDataRow,
      $$AppSettingsRowsTableFilterComposer,
      $$AppSettingsRowsTableOrderingComposer,
      $$AppSettingsRowsTableAnnotationComposer,
      $$AppSettingsRowsTableCreateCompanionBuilder,
      $$AppSettingsRowsTableUpdateCompanionBuilder,
      (
        AppSettingsDataRow,
        BaseReferences<
          _$AppDatabase,
          $AppSettingsRowsTable,
          AppSettingsDataRow
        >,
      ),
      AppSettingsDataRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db, _db.teachers);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db, _db.students);
  $$ClassSectionsTableTableManager get classSections =>
      $$ClassSectionsTableTableManager(_db, _db.classSections);
  $$EnrollmentsTableTableManager get enrollments =>
      $$EnrollmentsTableTableManager(_db, _db.enrollments);
  $$AttendanceSessionsTableTableManager get attendanceSessions =>
      $$AttendanceSessionsTableTableManager(_db, _db.attendanceSessions);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(_db, _db.attendanceRecords);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$AppSettingsRowsTableTableManager get appSettingsRows =>
      $$AppSettingsRowsTableTableManager(_db, _db.appSettingsRows);
}

mixin _$TeacherDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeachersTable get teachers => attachedDatabase.teachers;
  TeacherDaoManager get managers => TeacherDaoManager(this);
}

class TeacherDaoManager {
  final _$TeacherDaoMixin _db;
  TeacherDaoManager(this._db);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db.attachedDatabase, _db.teachers);
}

mixin _$StudentDaoMixin on DatabaseAccessor<AppDatabase> {
  $StudentsTable get students => attachedDatabase.students;
  $TeachersTable get teachers => attachedDatabase.teachers;
  $ClassSectionsTable get classSections => attachedDatabase.classSections;
  $EnrollmentsTable get enrollments => attachedDatabase.enrollments;
  $DevicesTable get devices => attachedDatabase.devices;
  StudentDaoManager get managers => StudentDaoManager(this);
}

class StudentDaoManager {
  final _$StudentDaoMixin _db;
  StudentDaoManager(this._db);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db.attachedDatabase, _db.teachers);
  $$ClassSectionsTableTableManager get classSections =>
      $$ClassSectionsTableTableManager(_db.attachedDatabase, _db.classSections);
  $$EnrollmentsTableTableManager get enrollments =>
      $$EnrollmentsTableTableManager(_db.attachedDatabase, _db.enrollments);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
}

mixin _$ClassDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeachersTable get teachers => attachedDatabase.teachers;
  $ClassSectionsTable get classSections => attachedDatabase.classSections;
  $StudentsTable get students => attachedDatabase.students;
  $EnrollmentsTable get enrollments => attachedDatabase.enrollments;
  $DevicesTable get devices => attachedDatabase.devices;
  ClassDaoManager get managers => ClassDaoManager(this);
}

class ClassDaoManager {
  final _$ClassDaoMixin _db;
  ClassDaoManager(this._db);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db.attachedDatabase, _db.teachers);
  $$ClassSectionsTableTableManager get classSections =>
      $$ClassSectionsTableTableManager(_db.attachedDatabase, _db.classSections);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
  $$EnrollmentsTableTableManager get enrollments =>
      $$EnrollmentsTableTableManager(_db.attachedDatabase, _db.enrollments);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
}

mixin _$EnrollmentDaoMixin on DatabaseAccessor<AppDatabase> {
  $StudentsTable get students => attachedDatabase.students;
  $TeachersTable get teachers => attachedDatabase.teachers;
  $ClassSectionsTable get classSections => attachedDatabase.classSections;
  $EnrollmentsTable get enrollments => attachedDatabase.enrollments;
  EnrollmentDaoManager get managers => EnrollmentDaoManager(this);
}

class EnrollmentDaoManager {
  final _$EnrollmentDaoMixin _db;
  EnrollmentDaoManager(this._db);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db.attachedDatabase, _db.teachers);
  $$ClassSectionsTableTableManager get classSections =>
      $$ClassSectionsTableTableManager(_db.attachedDatabase, _db.classSections);
  $$EnrollmentsTableTableManager get enrollments =>
      $$EnrollmentsTableTableManager(_db.attachedDatabase, _db.enrollments);
}

mixin _$AttendanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $TeachersTable get teachers => attachedDatabase.teachers;
  $ClassSectionsTable get classSections => attachedDatabase.classSections;
  $AttendanceSessionsTable get attendanceSessions =>
      attachedDatabase.attendanceSessions;
  $StudentsTable get students => attachedDatabase.students;
  $AttendanceRecordsTable get attendanceRecords =>
      attachedDatabase.attendanceRecords;
  AttendanceDaoManager get managers => AttendanceDaoManager(this);
}

class AttendanceDaoManager {
  final _$AttendanceDaoMixin _db;
  AttendanceDaoManager(this._db);
  $$TeachersTableTableManager get teachers =>
      $$TeachersTableTableManager(_db.attachedDatabase, _db.teachers);
  $$ClassSectionsTableTableManager get classSections =>
      $$ClassSectionsTableTableManager(_db.attachedDatabase, _db.classSections);
  $$AttendanceSessionsTableTableManager get attendanceSessions =>
      $$AttendanceSessionsTableTableManager(
        _db.attachedDatabase,
        _db.attendanceSessions,
      );
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
  $$AttendanceRecordsTableTableManager get attendanceRecords =>
      $$AttendanceRecordsTableTableManager(
        _db.attachedDatabase,
        _db.attendanceRecords,
      );
}

mixin _$DeviceDaoMixin on DatabaseAccessor<AppDatabase> {
  $StudentsTable get students => attachedDatabase.students;
  $DevicesTable get devices => attachedDatabase.devices;
  DeviceDaoManager get managers => DeviceDaoManager(this);
}

class DeviceDaoManager {
  final _$DeviceDaoMixin _db;
  DeviceDaoManager(this._db);
  $$StudentsTableTableManager get students =>
      $$StudentsTableTableManager(_db.attachedDatabase, _db.students);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
}

mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AppSettingsRowsTable get appSettingsRows => attachedDatabase.appSettingsRows;
  SettingsDaoManager get managers => SettingsDaoManager(this);
}

class SettingsDaoManager {
  final _$SettingsDaoMixin _db;
  SettingsDaoManager(this._db);
  $$AppSettingsRowsTableTableManager get appSettingsRows =>
      $$AppSettingsRowsTableTableManager(
        _db.attachedDatabase,
        _db.appSettingsRows,
      );
}
