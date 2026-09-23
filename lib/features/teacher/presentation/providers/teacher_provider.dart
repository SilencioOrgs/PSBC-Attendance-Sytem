import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';

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
    state = true;
    ref.invalidate(teacherProvider);
  }
}
