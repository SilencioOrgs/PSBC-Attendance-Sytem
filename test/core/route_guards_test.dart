import 'package:attendance_system_paete/core/auth/teacher_session.dart';
import 'package:attendance_system_paete/core/router/route_guards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('teacher routes follow setup, locked, and authenticated states', () {
    expect(
      teacherRouteRedirect(TeacherSessionState.setupRequired, '/teacher'),
      '/teacher/setup',
    );
    expect(
      teacherRouteRedirect(TeacherSessionState.setupRequired, '/teacher/setup'),
      isNull,
    );
    expect(
      teacherRouteRedirect(TeacherSessionState.locked, '/teacher/settings'),
      '/teacher/unlock',
    );
    expect(
      teacherRouteRedirect(TeacherSessionState.locked, '/teacher/unlock'),
      isNull,
    );
    expect(
      teacherRouteRedirect(
        TeacherSessionState.authenticated,
        '/teacher/unlock',
      ),
      '/teacher',
    );
    expect(
      teacherRouteRedirect(
        TeacherSessionState.authenticated,
        '/teacher/classes',
      ),
      isNull,
    );
  });

  test('student setup does not require the teacher session', () {
    expect(
      teacherRouteRedirect(TeacherSessionState.locked, '/student/setup'),
      isNull,
    );
  });
}
