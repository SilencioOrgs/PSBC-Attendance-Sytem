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

class StudentAlreadyHasDeviceException extends RepositoryException {
  const StudentAlreadyHasDeviceException()
    : super('A device is already registered for this student.');
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
}

abstract interface class AttendanceRepository {
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
  Future<void> finalizeScan(String sessionId, Set<String> detectedStudentIds);
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
