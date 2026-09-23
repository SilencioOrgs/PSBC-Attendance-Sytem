import 'models.dart';

/// User-facing repository validation failures shared by mock and Drift stores.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class InvalidSectionCodeException extends RepositoryException {
  const InvalidSectionCodeException()
    : super('Enter a section such as GRADE12-STEM A.');
}

class ClassSectionNotFoundException extends RepositoryException {
  const ClassSectionNotFoundException()
    : super('That grade and section is not available.');
}

class DuplicateStudentNumberException extends RepositoryException {
  const DuplicateStudentNumberException()
    : super('That student number is already registered.');
}

class DuplicateBleUuidException extends RepositoryException {
  const DuplicateBleUuidException()
    : super('That BLE device is already registered.');
}

class InvalidBleUuidException extends RepositoryException {
  const InvalidBleUuidException()
    : super(
        'Enter the device sharing code exactly as shown on the student device.',
      );
}

class StudentAlreadyHasDeviceException extends RepositoryException {
  const StudentAlreadyHasDeviceException()
    : super('A device is already registered for this student.');
}

class EmptyClassRosterException extends RepositoryException {
  const EmptyClassRosterException()
    : super('Add students to this class before starting attendance.');
}

class ClassValidationException extends RepositoryException {
  const ClassValidationException()
    : super('Enter a class section, subject, and room.');
}

class DuplicateClassException extends RepositoryException {
  const DuplicateClassException()
    : super('A class with this grade and section already exists.');
}

abstract interface class TeacherRepository {
  Future<Teacher> getTeacher();
  Stream<Teacher> watchTeacher();
  Future<Teacher> setupTeacher({required String name, required String pin});
}

abstract interface class ClassRepository {
  Future<List<ClassSection>> getClasses();
  Stream<List<ClassSection>> watchClasses();
  Future<ClassSection?> getClass(String classId);
  Stream<ClassSection?> watchClass(String classId);
  Future<ClassSection?> getClassByCode(String sectionCode);
  Future<List<Student>> getStudents(String classId);
  Stream<List<Student>> watchStudents(String classId);
  Future<ClassSection> createClass({
    required int gradeLevel,
    required String sectionLabel,
    required String subject,
    required String room,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
  });
  Future<ClassSection> updateClass(ClassSection section);
  Future<void> deleteClass(String classId);
}

abstract interface class StudentRepository {
  Future<List<Student>> getStudents();
  Stream<List<Student>> watchStudents();
  Future<Student?> getStudent(String studentId);
  Stream<Student?> watchStudent(String studentId);
  Future<Student?> getCurrentStudent();
  Stream<Student?> watchCurrentStudent();
  Future<Student> registerStudent({
    required String name,
    required String studentNumber,
    required String sectionCode,
  });
  Future<Student> addStudentToClass({
    required String name,
    required String studentNumber,
    required String classId,
    String? bleUuid,
  });
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    required String studentNumber,
  });
  Future<void> removeStudentFromClass({
    required String studentId,
    required String classId,
  });
}

abstract interface class AttendanceRepository {
  Future<AttendanceSession> startSession(String classId);
  Future<AttendanceSession> getTodaySession();
  Stream<AttendanceSession> watchTodaySession();
  Future<List<AttendanceSession>> getSessions();
  Stream<List<AttendanceSession>> watchSessions();
  Future<AttendanceSession?> getSession(String sessionId);
  Stream<AttendanceSession?> watchSession(String sessionId);
  Future<List<AttendanceRecord>> getRecords(String sessionId);
  Stream<List<AttendanceRecord>> watchRecords(String sessionId);
  Future<List<AttendanceRecord>> getStudentRecords(String studentId);
  Stream<List<AttendanceRecord>> watchStudentRecords(String studentId);
  Future<AttendanceRecord> toggleStatus(String sessionId, String studentId);
  Future<void> markDetected(String sessionId, String studentId, {int? rssi});
  Future<void> completeSession(String sessionId);
}

abstract interface class DeviceRepository {
  Future<List<Device>> getDevices();
  Stream<List<Device>> watchDevices();
  Future<Device?> getStudentDevice(String studentId);
  Stream<Device?> watchStudentDevice(String studentId);
  Future<Device> registerDevice(
    String studentId,
    String deviceName, {
    String? bleUuid,
  });
}

abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Stream<AppSettings> watchSettings();
  Future<AppSettings> saveSettings(AppSettings settings);
}
