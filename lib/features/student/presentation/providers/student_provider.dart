import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';

final allStudentsProvider = StreamProvider<List<Student>>(
  (ref) => ref.watch(studentRepositoryProvider).watchStudents(),
);

final currentStudentProvider = StreamProvider<Student?>(
  (ref) => ref.watch(studentRepositoryProvider).watchCurrentStudent(),
);

final currentStudentOfferingsProvider = StreamProvider<List<ClassSection>>((
  ref,
) {
  final studentRepository = ref.watch(studentRepositoryProvider);
  final classRepository = ref.watch(classRepositoryProvider);
  return studentRepository.watchCurrentStudent().asyncExpand(
    (student) => student == null
        ? Stream.value(const <ClassSection>[])
        : classRepository.watchStudentOfferings(student.id),
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
    String? sectionCode,
  }) async {
    final student = await ref
        .read(studentRepositoryProvider)
        .registerStudent(
          name: name,
          studentNumber: studentNumber,
          sectionCode: sectionCode,
        );
    await ref.read(applicationSessionProvider).studentRegistered(student.id);
    state = true;
    ref.invalidate(currentStudentProvider);
    ref.invalidate(currentStudentOfferingsProvider);
    ref.invalidate(allStudentsProvider);
  }
}
