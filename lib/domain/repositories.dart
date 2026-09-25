import 'models.dart';
import 'subject_invitation.dart';

/// User-facing repository validation failures shared across feature workflows.
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

class NoActiveAttendanceSessionException extends RepositoryException {
  const NoActiveAttendanceSessionException()
    : super('There is no attendance session to resume.');
}

class ActiveAttendanceSessionException extends RepositoryException {
  const ActiveAttendanceSessionException(this.sessionId)
    : super(
        'Finish or cancel the active attendance session before continuing.',
      );

  final String sessionId;
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
    : super(
        'This subject already exists for the selected teacher and section.',
      );
}

class DuplicateEnrollmentException extends RepositoryException {
  const DuplicateEnrollmentException()
    : super('This student is already enrolled in that subject.');
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
  Stream<ClassSection?> watchClassByCode(String sectionCode);
  Future<List<ClassSection>> getStudentOfferings(String studentId);
  Stream<List<ClassSection>> watchStudentOfferings(String studentId);
  Future<List<Student>> getStudents(String classId);
  Stream<List<Student>> watchStudents(String classId);
  Future<ClassSection> createClass({
    required int gradeLevel,
    required String sectionLabel,
    required String subject,
    required String room,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
    Set<Weekday> scheduleDays = const {},
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
    String? sectionCode,
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

abstract interface class EnrollmentRepository {
  Future<int> addFromInvitation({
    required String studentId,
    required SubjectInvitation invitation,
    required Set<String> selectedOfferingIds,
  });
}

abstract interface class AttendanceRepository {
  Future<AttendanceSession> startSession(
    String classOfferingId, {
    bool manualOverride = false,
  });
  Future<AttendanceSession?> getTodaySession();
  Stream<AttendanceSession?> watchTodaySession();
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
  Future<void> finishScan(String sessionId);
  Future<void> resumeScan(String sessionId);
  Future<void> cancelSession(String sessionId);
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
  Future<Device> replaceDevice(
    String studentId,
    String deviceName, {
    required String bleUuid,
  });
  Future<void> removeDevice(String studentId);
}

abstract interface class SettingsRepository {
  Future<AppSettings> getSettings();
  Stream<AppSettings> watchSettings();
  Future<AppSettings> saveSettings(AppSettings settings);
}
