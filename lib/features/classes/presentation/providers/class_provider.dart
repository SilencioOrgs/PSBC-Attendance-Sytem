import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';

final classListProvider = StreamProvider<List<ClassSection>>(
  (ref) => ref.watch(classRepositoryProvider).watchClasses(),
);

final classByIdProvider = StreamProvider.family<ClassSection?, String>(
  (ref, classId) => ref.watch(classRepositoryProvider).watchClass(classId),
);

final classRosterProvider = StreamProvider.family<List<Student>, String>(
  (ref, classId) => ref.watch(classRepositoryProvider).watchStudents(classId),
);
