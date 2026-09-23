import '../core/utils/section_code.dart';
import '../core/utils/teacher_pin.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import 'seed_data.dart';

Stream<T> _once<T>(Future<T> future) async* {
  yield await future;
}

class MockTeacherRepository implements TeacherRepository {
  Teacher _teacher = seedTeacher;
  @override
  Future<Teacher> getTeacher() async => _teacher;
  @override
  Stream<Teacher> watchTeacher() => _once(getTeacher());
  @override
  Future<Teacher> setupTeacher({
    required String name,
    required String pin,
  }) async {
    if (!isValidTeacherPin(normalizeTeacherPin(pin))) {
      throw ArgumentError('PIN must contain 4 to 6 digits.');
    }
    _teacher = Teacher(
      id: _teacher.id,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      name: name.trim(),
    );
    return _teacher;
  }
}

class MockClassRepository implements ClassRepository {
  final List<ClassSection> _classes = [...seedClasses];
  @override
  Future<List<ClassSection>> getClasses() async => List.unmodifiable(_classes);
  @override
  Stream<List<ClassSection>> watchClasses() => _once(getClasses());
  @override
  Future<ClassSection?> getClass(String classId) async =>
      _classes.where((section) => section.id == classId).firstOrNull;
  @override
  Stream<ClassSection?> watchClass(String classId) => _once(getClass(classId));
  @override
  Future<ClassSection?> getClassByCode(String sectionCode) async {
    final normalized = normalizeSectionCode(sectionCode);
    return _classes
        .where((section) => section.sectionCode == normalized)
        .firstOrNull;
  }

  @override
  Future<List<Student>> getStudents(String classId) async => List.unmodifiable(
    seedStudents.where((student) => student.classId == classId),
  );
  @override
  Stream<List<Student>> watchStudents(String classId) =>
      _once(getStudents(classId));

  @override
  Future<ClassSection> createClass({
    required int gradeLevel,
    required String sectionLabel,
    required String subject,
    required String room,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
  }) async {
    final code = normalizeSectionCode('GRADE$gradeLevel-$sectionLabel');
    if (parseSectionCode(code) == null ||
        subject.trim().isEmpty ||
        room.trim().isEmpty ||
        !scheduleEnd.isAfter(scheduleStart)) {
      throw const ClassValidationException();
    }
    if (_classes.any((section) => section.sectionCode == code)) {
      throw const DuplicateClassException();
    }
    final now = DateTime.now();
    final section = ClassSection(
      id: 'mock-class-${_classes.length}',
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      name: 'Grade $gradeLevel - ${sectionLabel.trim()}',
      subject: subject.trim(),
      room: room.trim(),
      schedule: '$scheduleStart - $scheduleEnd',
      studentCount: 0,
      gradeLevel: gradeLevel,
      sectionLabel: sectionLabel.trim().toUpperCase(),
      sectionCode: code,
    );
    _classes.add(section);
    return section;
  }

  @override
  Future<ClassSection> updateClass(ClassSection section) async {
    if (_classes.any(
      (item) =>
          item.id != section.id && item.sectionCode == section.sectionCode,
    )) {
      throw const DuplicateClassException();
    }
    final index = _classes.indexWhere((item) => item.id == section.id);
    if (index < 0) throw const ClassSectionNotFoundException();
    _classes[index] = section;
    return section;
  }

  @override
  Future<void> deleteClass(String classId) async =>
      _classes.removeWhere((section) => section.id == classId);
}

class MockStudentRepository implements StudentRepository {
  final List<Student> _students = [...seedStudents];
  String _currentStudentId = 'student-01';
  final Set<String> _removedEnrollments = {};
  @override
  Future<List<Student>> getStudents() async => List.unmodifiable(_students);
  @override
  Stream<List<Student>> watchStudents() => _once(getStudents());
  @override
  Future<Student?> getStudent(String id) async =>
      _students.where((student) => student.id == id).firstOrNull;
  @override
  Stream<Student?> watchStudent(String id) => _once(getStudent(id));
  @override
  Future<Student?> getCurrentStudent() => getStudent(_currentStudentId);
  @override
  Stream<Student?> watchCurrentStudent() => _once(getCurrentStudent());
  @override
  Future<Student> registerStudent({
    required String name,
    required String studentNumber,
    required String sectionCode,
  }) async {
    final parsed = parseSectionCode(sectionCode);
    if (parsed == null) throw const InvalidSectionCodeException();
    final section = seedClasses
        .where((item) => item.sectionCode == normalizeSectionCode(sectionCode))
        .firstOrNull;
    if (section == null) throw const ClassSectionNotFoundException();
    if (_students.any(
      (student) => student.studentNumber == studentNumber.trim(),
    )) {
      throw const DuplicateStudentNumberException();
    }
    final student = Student(
      id: 'student-registered',
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingCreate,
      name: name.trim(),
      studentNumber: studentNumber.trim(),
      classId: section.id,
      gradeLevel: 'Grade ${parsed.gradeLevel}',
      deviceRegistered: false,
    );
    _students.removeWhere((old) => old.id == student.id);
    _students.add(student);
    _currentStudentId = student.id;
    return student;
  }

  @override
  Future<Student> addStudentToClass({
    required String name,
    required String studentNumber,
    required String classId,
    String? bleUuid,
  }) async {
    if (name.trim().isEmpty || studentNumber.trim().isEmpty) {
      throw const ClassValidationException();
    }
    if (_students.any(
      (student) => student.studentNumber == studentNumber.trim(),
    )) {
      throw const DuplicateStudentNumberException();
    }
    final section = seedClasses.where((item) => item.id == classId).firstOrNull;
    if (section == null) throw const ClassSectionNotFoundException();
    final student = Student(
      id: 'student-managed-${DateTime.now().microsecondsSinceEpoch}',
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingCreate,
      name: name.trim(),
      studentNumber: studentNumber.trim(),
      classId: classId,
      gradeLevel: 'Grade ${section.gradeLevel}',
      deviceRegistered: false,
    );
    _students.add(student);
    return student;
  }

  @override
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    required String studentNumber,
  }) async {
    if (name.trim().isEmpty || studentNumber.trim().isEmpty) {
      throw const ClassValidationException();
    }
    if (_students.any(
      (student) =>
          student.id != studentId &&
          student.studentNumber == studentNumber.trim(),
    )) {
      throw const DuplicateStudentNumberException();
    }
    final index = _students.indexWhere((student) => student.id == studentId);
    if (index < 0) throw const ClassSectionNotFoundException();
    final current = _students[index];
    _students[index] = Student(
      id: current.id,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      name: name.trim(),
      studentNumber: studentNumber.trim(),
      classId: current.classId,
      gradeLevel: current.gradeLevel,
      deviceRegistered: current.deviceRegistered,
    );
    return _students[index];
  }

  @override
  Future<void> removeStudentFromClass({
    required String studentId,
    required String classId,
  }) async {
    _students.removeWhere(
      (student) => student.id == studentId && student.classId == classId,
    );
    _removedEnrollments.add('$classId/$studentId');
  }
}

class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> _records = [
    ...seedAttendanceRecords,
    ...seedHistoricalRecords,
  ];
  final List<AttendanceSession> _extraSessions = [];
  List<AttendanceSession> get _sessions => [
    ..._extraSessions,
    seedTodaySession,
    ...seedHistoricalSessions,
  ];
  @override
  Future<AttendanceSession> startSession(String classId) async {
    final roster = seedStudents
        .where((student) => student.classId == classId)
        .toList();
    if (roster.isEmpty) throw const EmptyClassRosterException();
    final now = DateTime.now();
    final session = AttendanceSession(
      id: 'mock-session-${_extraSessions.length}',
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      classId: classId,
      title: classId,
      startedAt: now,
      status: 'Scanning',
    );
    _extraSessions.add(session);
    for (final student in roster) {
      _records.add(
        AttendanceRecord(
          id: 'mock-record-${session.id}-${student.id}',
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          sessionId: session.id,
          studentId: student.id,
          isPresent: false,
          detectedAt: null,
          recordStatus: AttendanceRecordStatus.unverified,
        ),
      );
    }
    return session;
  }

  @override
  Future<AttendanceSession> getTodaySession() async => seedTodaySession;
  @override
  Stream<AttendanceSession> watchTodaySession() => _once(getTodaySession());
  @override
  Future<List<AttendanceSession>> getSessions() async => _sessions;
  @override
  Stream<List<AttendanceSession>> watchSessions() => _once(getSessions());
  @override
  Future<AttendanceSession?> getSession(String id) async =>
      _sessions.where((item) => item.id == id).firstOrNull;
  @override
  Stream<AttendanceSession?> watchSession(String id) => _once(getSession(id));
  @override
  Future<List<AttendanceRecord>> getRecords(String id) async =>
      List.unmodifiable(_records.where((item) => item.sessionId == id));
  @override
  Stream<List<AttendanceRecord>> watchRecords(String id) =>
      _once(getRecords(id));
  @override
  Future<List<AttendanceRecord>> getStudentRecords(String id) async =>
      List.unmodifiable(_records.where((item) => item.studentId == id));
  @override
  Stream<List<AttendanceRecord>> watchStudentRecords(String id) =>
      _once(getStudentRecords(id));
  @override
  Future<AttendanceRecord> toggleStatus(
    String sessionId,
    String studentId,
  ) async {
    final index = _records.indexWhere(
      (item) => item.sessionId == sessionId && item.studentId == studentId,
    );
    if (index < 0) throw StateError('Attendance record was not found.');
    final changed = _records[index].copyWith(
      isPresent: !_records[index].isPresent,
    );
    _records[index] = changed;
    return changed;
  }

  @override
  Future<void> markDetected(
    String sessionId,
    String studentId, {
    int? rssi,
  }) async {
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];
      if (record.sessionId == sessionId && record.studentId == studentId) {
        _records[i] = AttendanceRecord(
          id: record.id,
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pendingUpdate,
          sessionId: sessionId,
          studentId: studentId,
          isPresent: true,
          detectedAt: DateTime.now(),
          rssi: rssi,
          recordStatus: AttendanceRecordStatus.present,
        );
      }
    }
  }

  @override
  Future<void> completeSession(String sessionId) async {
    for (var i = 0; i < _records.length; i++) {
      final record = _records[i];
      if (record.sessionId == sessionId &&
          record.recordStatus == AttendanceRecordStatus.unverified) {
        _records[i] = record.copyWith(isPresent: false);
      }
    }
    final index = _extraSessions.indexWhere((item) => item.id == sessionId);
    if (index >= 0) {
      final item = _extraSessions[index];
      _extraSessions[index] = AttendanceSession(
        id: item.id,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pendingUpdate,
        classId: item.classId,
        title: item.title,
        startedAt: item.startedAt,
        status: 'Completed',
        endedAt: DateTime.now(),
      );
    }
  }
}

class MockDeviceRepository implements DeviceRepository {
  final List<Device> _devices = [...seedDevices];
  @override
  Future<List<Device>> getDevices() async => List.unmodifiable(_devices);
  @override
  Stream<List<Device>> watchDevices() => _once(getDevices());
  @override
  Future<Device?> getStudentDevice(String id) async =>
      _devices.where((item) => item.ownerStudentId == id).firstOrNull;
  @override
  Stream<Device?> watchStudentDevice(String id) => _once(getStudentDevice(id));
  @override
  Future<Device> registerDevice(
    String studentId,
    String deviceName, {
    String? bleUuid,
  }) async {
    if (_devices.any((device) => device.ownerStudentId == studentId)) {
      throw const StudentAlreadyHasDeviceException();
    }
    final uuid = bleUuid?.trim().isNotEmpty == true
        ? bleUuid!.trim()
        : 'mock-${studentId.replaceAll('-', '')}';
    if (_devices.any((device) => device.address == uuid)) {
      throw const DuplicateBleUuidException();
    }
    final now = DateTime.now();
    final device = Device(
      id: 'device-${studentId.replaceAll('-', '')}',
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      name: deviceName.trim(),
      deviceModel: deviceName.trim(),
      address: uuid,
      ownerStudentId: studentId,
      isConnected: true,
      lastSeenAt: now,
      registeredAt: now,
    );
    _devices.add(device);
    return device;
  }
}

class MockSettingsRepository implements SettingsRepository {
  AppSettings _settings = seedSettings;
  @override
  Future<AppSettings> getSettings() async => _settings;
  @override
  Stream<AppSettings> watchSettings() => _once(getSettings());
  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    _settings = AppSettings(
      id: settings.id,
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pendingUpdate,
      soundEnabled: settings.soundEnabled,
      vibrationEnabled: settings.vibrationEnabled,
      scanDurationSeconds: settings.scanDurationSeconds,
      rssiThreshold: settings.rssiThreshold,
    );
    return _settings;
  }
}
