import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/attendance/presentation/screens/attendance_screens.dart';
import '../../features/classes/presentation/screens/class_screens.dart';
import '../../features/classes/presentation/screens/class_creation_screen.dart';
import '../../features/device/presentation/screens/device_screens.dart';
import '../../features/settings/presentation/screens/teacher_settings_screen.dart';
import '../../features/student/presentation/screens/student_screens.dart';
import '../../features/teacher/presentation/screens/teacher_home_screen.dart';
import '../../features/teacher/presentation/screens/teacher_setup_screen.dart';
import '../../features/teacher/presentation/screens/teacher_unlock_screen.dart';
import '../auth/teacher_session.dart';
import 'route_guards.dart';
import 'route_names.dart';
import 'welcome_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Creates the two independent stateful role shells and all pre-shell routes.
GoRouter createAppRouter({TeacherSession? session}) {
  final teacherSession =
      session ?? TeacherSession(state: TeacherSessionState.setupRequired);
  final initialLocation = switch (teacherSession.state) {
    TeacherSessionState.uninitialized => '/welcome',
    TeacherSessionState.setupRequired => '/teacher/setup',
    TeacherSessionState.locked => '/teacher/unlock',
    TeacherSessionState.authenticated => '/teacher',
  };
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: teacherSession,
    redirect: (context, state) =>
        teacherRouteRedirect(teacherSession.state, state.uri.path),
    routes: [
      GoRoute(
        path: '/welcome',
        name: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/teacher/setup',
        name: AppRoutes.teacherSetup,
        builder: (context, state) => const TeacherSetupScreen(),
      ),
      GoRoute(
        path: '/teacher/unlock',
        name: AppRoutes.teacherUnlock,
        builder: (context, state) => const TeacherUnlockScreen(),
      ),
      GoRoute(
        path: '/student/setup',
        name: AppRoutes.studentSetup,
        builder: (context, state) => const StudentSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _RoleNavigationShell(
          navigationShell: navigationShell,
          isTeacher: true,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher',
                name: AppRoutes.teacherHome,
                builder: (context, state) => const TeacherHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/classes',
                name: AppRoutes.teacherClasses,
                builder: (context, state) => const TeacherClassesScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: AppRoutes.teacherClassCreate,
                    builder: (context, state) => const ClassCreationScreen(),
                  ),
                  GoRoute(
                    path: ':classId',
                    name: AppRoutes.teacherClassDetails,
                    builder: (context, state) => ClassDetailsScreen(
                      classId: state.pathParameters['classId'] ?? '',
                    ),
                    routes: [
                      GoRoute(
                        path: 'students',
                        name: AppRoutes.teacherStudentList,
                        builder: (context, state) => StudentListScreen(
                          classId: state.pathParameters['classId'] ?? '',
                        ),
                      ),
                      GoRoute(
                        path: 'edit',
                        name: AppRoutes.teacherClassEdit,
                        builder: (context, state) => ClassEditLoaderScreen(
                          classId: state.pathParameters['classId'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/attendance',
                name: AppRoutes.teacherAttendance,
                builder: (context, state) => const AttendanceHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teacher/settings',
                name: AppRoutes.teacherSettings,
                builder: (context, state) => const TeacherSettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'device-status',
                    name: AppRoutes.teacherDeviceStatus,
                    builder: (context, state) => const DeviceStatusScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _RoleNavigationShell(
          navigationShell: navigationShell,
          isTeacher: false,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student',
                name: AppRoutes.studentHome,
                builder: (context, state) => const StudentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/attendance',
                name: AppRoutes.studentAttendance,
                builder: (context, state) => const MyAttendanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/device',
                name: AppRoutes.studentDevice,
                builder: (context, state) => const DeviceRegistrationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/profile',
                name: AppRoutes.studentProfile,
                builder: (context, state) => const StudentProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/scanner/:sessionId',
        name: AppRoutes.bleScanner,
        builder: (context, state) => BleScannerScreen(
          sessionId: state.pathParameters['sessionId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/teacher/results/:sessionId',
        name: AppRoutes.attendanceResults,
        builder: (context, state) => AttendanceResultsScreen(
          sessionId: state.pathParameters['sessionId'] ?? '',
        ),
      ),
    ],
  );
}

class _RoleNavigationShell extends StatelessWidget {
  const _RoleNavigationShell({
    required this.navigationShell,
    required this.isTeacher,
  });

  final StatefulNavigationShell navigationShell;
  final bool isTeacher;

  @override
  Widget build(BuildContext context) {
    final destinations = isTeacher
        ? const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.bluetooth_outlined),
              selectedIcon: Icon(Icons.bluetooth),
              label: 'Device',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
