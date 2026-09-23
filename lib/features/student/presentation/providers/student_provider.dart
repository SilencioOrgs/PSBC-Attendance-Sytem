import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';

final allStudentsProvider = StreamProvider<List<Student>>(
  (ref) => ref.watch(studentRepositoryProvider).watchStudents(),
);

final currentStudentProvider = StreamProvider<Student?>(
  (ref) => ref.watch(studentRepositoryProvider).watchCurrentStudent(),
);

final currentStudentClassProvider = StreamProvider<ClassSection?>((ref) {
  final studentRepository = ref.watch(studentRepositoryProvider);
  final classRepository = ref.watch(classRepositoryProvider);
  return studentRepository.watchCurrentStudent().asyncExpand(
    (student) => student == null
        ? Stream.value(null)
        : classRepository.watchClass(student.classId),
  );
});

final studentRegistrationControllerProvider =
    NotifierProvider<StudentRegistrationController, bool>(
      StudentRegistrationController.new,
    );

class StudentRegistrationController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> register({
    required String name,
    required String studentNumber,
    required String sectionCode,
  }) async {
    await ref
        .read(studentRepositoryProvider)
        .registerStudent(
          name: name,
          studentNumber: studentNumber,
          sectionCode: sectionCode,
        );
    state = true;
    ref.invalidate(currentStudentProvider);
    ref.invalidate(currentStudentClassProvider);
    ref.invalidate(allStudentsProvider);
  }
}
