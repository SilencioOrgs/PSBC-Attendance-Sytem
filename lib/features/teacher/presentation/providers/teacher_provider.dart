import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models.dart';
import '../../../../core/auth/teacher_session.dart';
import '../../../../core/providers/repository_providers.dart';

final teacherProvider = StreamProvider<Teacher>(
  (ref) => ref.watch(teacherRepositoryProvider).watchTeacher(),
);

final teacherSetupControllerProvider =
    NotifierProvider<TeacherSetupController, bool>(TeacherSetupController.new);

class TeacherSetupController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> complete({required String name, required String pin}) async {
    await ref
        .read(teacherRepositoryProvider)
        .setupTeacher(name: name, pin: pin);
    teacherSessionUnlocked.value = true;
    state = true;
    ref.invalidate(teacherProvider);
  }
}

final teacherPinUnlockProvider =
    NotifierProvider<TeacherPinUnlockController, bool>(
      TeacherPinUnlockController.new,
    );

class TeacherPinUnlockController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<bool> unlock(String pin) async {
    final allowed = await ref.read(teacherPinServiceProvider).verifyPin(pin);
    state = allowed;
    if (allowed) teacherSessionUnlocked.value = true;
    return allowed;
  }
}
