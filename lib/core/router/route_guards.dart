import '../auth/teacher_session.dart';

String? teacherRouteRedirect(TeacherSessionState session, String path) {
  if (!path.startsWith('/teacher')) return null;
  final isSetupOrUnlock = path == '/teacher/setup' || path == '/teacher/unlock';
  return switch (session) {
    TeacherSessionState.uninitialized => '/welcome',
    TeacherSessionState.setupRequired =>
      path == '/teacher/setup' ? null : '/teacher/setup',
    TeacherSessionState.locked =>
      path == '/teacher/unlock' ? null : '/teacher/unlock',
    TeacherSessionState.authenticated => isSetupOrUnlock ? '/teacher' : null,
  };
}
