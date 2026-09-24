import 'package:flutter/foundation.dart';

import '../../services/auth/teacher_pin_service.dart';

enum TeacherSessionState { uninitialized, setupRequired, locked, authenticated }

/// In-memory teacher session state observed by the router and Riverpod UI.
/// The authenticated state is deliberately never persisted across app launches.
class TeacherSession extends ChangeNotifier {
  TeacherSession({this.state = TeacherSessionState.uninitialized});

  TeacherSessionState state;

  Future<void> initialize(TeacherPinService pinService) async {
    state = await pinService.hasPin()
        ? TeacherSessionState.locked
        : TeacherSessionState.setupRequired;
    notifyListeners();
  }

  void authenticate() => _setState(TeacherSessionState.authenticated);

  void lock() => _setState(TeacherSessionState.locked);

  void setupRequired() => _setState(TeacherSessionState.setupRequired);

  void _setState(TeacherSessionState value) {
    if (state == value) return;
    state = value;
    notifyListeners();
  }
}
