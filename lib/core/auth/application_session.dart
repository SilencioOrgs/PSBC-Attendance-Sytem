import 'package:flutter/foundation.dart';

import '../../services/storage/app_database.dart';
import 'teacher_session.dart';

enum ApplicationEntry {
  uninitialized,
  welcome,
  student,
  teacherSetup,
  teacherLocked,
  teacher,
  attendanceOfficer,
}

/// Resolves the persisted local profiles once before routing and restores the last role.
class ApplicationSession extends ChangeNotifier {
  ApplicationSession({required this.database, required this.teacherSession}) {
    teacherSession.addListener(_teacherChanged);
  }

  final AppDatabase database;
  final TeacherSession teacherSession;
  ApplicationEntry entry = ApplicationEntry.uninitialized;
  String? currentStudentId;

  Future<void> initialize({
    required bool teacherPinExists,
    bool attendanceAccessExists = false,
  }) async {
    final teacher = await database.teacherDao.getTeacherOrNull();
    final student = await database.studentDao.getCurrent();
    currentStudentId = student?.id;
    if (teacher == null && student == null) {
      entry = attendanceAccessExists
          ? ApplicationEntry.attendanceOfficer
          : ApplicationEntry.welcome;
    } else if (teacher == null) {
      final prefs = await database.appSessionDao.getPreferences();
      entry =
          attendanceAccessExists && prefs?.lastActiveRole == 'attendanceOfficer'
          ? ApplicationEntry.attendanceOfficer
          : ApplicationEntry.student;
      await _saveRole(
        entry == ApplicationEntry.attendanceOfficer
            ? 'attendanceOfficer'
            : 'student',
      );
    } else if (student == null) {
      final prefs = await database.appSessionDao.getPreferences();
      entry =
          attendanceAccessExists && prefs?.lastActiveRole == 'attendanceOfficer'
          ? ApplicationEntry.attendanceOfficer
          : teacherPinExists
          ? ApplicationEntry.teacherLocked
          : ApplicationEntry.teacherSetup;
    } else {
      final prefs = await database.appSessionDao.getPreferences();
      final lastRole = prefs?.lastActiveRole;
      if (lastRole == 'attendanceOfficer' && attendanceAccessExists) {
        entry = ApplicationEntry.attendanceOfficer;
      } else if (lastRole == 'student') {
        entry = ApplicationEntry.student;
      } else {
        entry = teacherPinExists
            ? ApplicationEntry.teacherLocked
            : ApplicationEntry.teacherSetup;
      }
    }
    notifyListeners();
  }

  String get initialLocation => switch (entry) {
    ApplicationEntry.uninitialized => '/welcome',
    ApplicationEntry.welcome => '/welcome',
    ApplicationEntry.student => '/student',
    ApplicationEntry.teacherSetup => '/teacher/setup',
    ApplicationEntry.teacherLocked => '/teacher/unlock',
    ApplicationEntry.teacher => '/teacher',
    ApplicationEntry.attendanceOfficer => '/attendance-officer',
  };

  String? redirect(String path) {
    if (entry == ApplicationEntry.uninitialized) return '/welcome';
    if (entry == ApplicationEntry.welcome) {
      return path == '/welcome' ||
              path == '/student/setup' ||
              path == '/teacher/setup' ||
              path == '/attendance-access/import'
          ? null
          : '/welcome';
    }
    if (path == '/roles' || path == '/attendance-access/import') return null;
    if (entry == ApplicationEntry.attendanceOfficer) {
      if (path.startsWith('/attendance-officer')) return null;
      return '/attendance-officer';
    }
    if (entry == ApplicationEntry.student) {
      if (path.startsWith('/student')) return null;
      return '/student';
    }
    if (entry == ApplicationEntry.teacherSetup) {
      return path == '/teacher/setup' || path == '/student/setup'
          ? null
          : '/teacher/setup';
    }
    if (entry == ApplicationEntry.teacherLocked) {
      return path == '/teacher/unlock' || path == '/student/setup'
          ? null
          : '/teacher/unlock';
    }
    if (entry == ApplicationEntry.teacher) {
      return path.startsWith('/student') ? '/teacher' : null;
    }
    return null;
  }

  Future<void> selectStudent() async {
    final student = await database.studentDao.getCurrent();
    if (student == null) {
      throw StateError('No student profile is registered on this device.');
    }
    currentStudentId = student.id;
    entry = ApplicationEntry.student;
    await _saveRole('student');
    notifyListeners();
  }

  Future<void> selectTeacher() async {
    final teacher = await database.teacherDao.getTeacherOrNull();
    if (teacher == null) {
      entry = ApplicationEntry.teacherSetup;
    } else {
      entry = teacherSession.state == TeacherSessionState.authenticated
          ? ApplicationEntry.teacher
          : teacherSession.state == TeacherSessionState.setupRequired
          ? ApplicationEntry.teacherSetup
          : ApplicationEntry.teacherLocked;
    }
    await _saveRole('teacher');
    notifyListeners();
  }

  Future<void> selectAttendanceOfficer() async {
    if ((await database.attendanceAccessDao.getAll()).isEmpty) {
      throw StateError('No attendance access has been imported.');
    }
    entry = ApplicationEntry.attendanceOfficer;
    await _saveRole('attendanceOfficer');
    notifyListeners();
  }

  Future<void> studentRegistered(String studentId) async {
    currentStudentId = studentId;
    entry = ApplicationEntry.student;
    await _saveRole('student');
    notifyListeners();
  }

  Future<void> _saveRole(String role) => database.appSessionDao.savePreferences(
    lastActiveRole: role,
    activeStudentId: currentStudentId,
  );

  void _teacherChanged() {
    if (entry == ApplicationEntry.teacherSetup ||
        entry == ApplicationEntry.teacherLocked ||
        entry == ApplicationEntry.teacher) {
      entry = switch (teacherSession.state) {
        TeacherSessionState.setupRequired => ApplicationEntry.teacherSetup,
        TeacherSessionState.locked => ApplicationEntry.teacherLocked,
        TeacherSessionState.authenticated => ApplicationEntry.teacher,
        TeacherSessionState.uninitialized => entry,
      };
      notifyListeners();
    }
  }

  @override
  void dispose() {
    teacherSession.removeListener(_teacherChanged);
    super.dispose();
  }
}
