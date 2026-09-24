import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';
import '../../../device/presentation/providers/device_provider.dart';
import '../../../student/presentation/providers/student_provider.dart';

final classListProvider = StreamProvider<List<ClassSection>>(
  (ref) => ref.watch(classRepositoryProvider).watchClasses(),
);

final classByIdProvider = StreamProvider.family<ClassSection?, String>(
  (ref, classId) => ref.watch(classRepositoryProvider).watchClass(classId),
);

final classRosterProvider = StreamProvider.family<List<Student>, String>(
  (ref, classId) => ref.watch(classRepositoryProvider).watchStudents(classId),
);

final classCreationControllerProvider =
    NotifierProvider<ClassCreationController, bool>(
      ClassCreationController.new,
    );

class ClassCreationController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<ClassSection> create({
    required int gradeLevel,
    required String sectionLabel,
    required String subject,
    required String room,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
  }) async {
    state = true;
    try {
      return await ref
          .read(classRepositoryProvider)
          .createClass(
            gradeLevel: gradeLevel,
            sectionLabel: sectionLabel,
            subject: subject,
            room: room,
            scheduleStart: scheduleStart,
            scheduleEnd: scheduleEnd,
          );
    } finally {
      state = false;
      ref.invalidate(classListProvider);
    }
  }

  Future<ClassSection> update(ClassSection section) async {
    state = true;
    try {
      return await ref.read(classRepositoryProvider).updateClass(section);
    } finally {
      state = false;
      ref.invalidate(classListProvider);
      ref.invalidate(classByIdProvider(section.id));
    }
  }
}

final classRemovalControllerProvider =
    NotifierProvider<ClassRemovalController, bool>(ClassRemovalController.new);

class ClassRemovalController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> remove(String classId) async {
    state = true;
    try {
      await ref.read(classRepositoryProvider).deleteClass(classId);
    } finally {
      state = false;
      ref.invalidate(classListProvider);
      ref.invalidate(classByIdProvider(classId));
    }
  }
}

final studentManagementControllerProvider =
    NotifierProvider<StudentManagementController, bool>(
      StudentManagementController.new,
    );

class StudentManagementController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> add(
    String classId,
    String name,
    String studentNumber, {
    String? bleUuid,
  }) async {
    state = true;
    try {
      await ref
          .read(studentRepositoryProvider)
          .addStudentToClass(
            name: name,
            studentNumber: studentNumber,
            classId: classId,
            bleUuid: bleUuid,
          );
    } finally {
      state = false;
      ref.invalidate(classRosterProvider(classId));
      ref.invalidate(classByIdProvider(classId));
    }
  }

  Future<void> update(
    String classId,
    String studentId,
    String name,
    String studentNumber,
  ) async {
    state = true;
    try {
      await ref
          .read(studentRepositoryProvider)
          .updateStudent(
            studentId: studentId,
            name: name,
            studentNumber: studentNumber,
          );
    } finally {
      state = false;
      ref.invalidate(classRosterProvider(classId));
      ref.invalidate(classByIdProvider(classId));
    }
  }

  Future<void> remove(String classId, String studentId) async {
    state = true;
    try {
      await ref
          .read(studentRepositoryProvider)
          .removeStudentFromClass(studentId: studentId, classId: classId);
    } finally {
      state = false;
      ref.invalidate(classRosterProvider(classId));
      ref.invalidate(classByIdProvider(classId));
    }
  }

  Future<void> registerDevice(
    String classId,
    String studentId, {
    required String deviceName,
    required String bleUuid,
  }) async {
    state = true;
    try {
      await ref
          .read(deviceRepositoryProvider)
          .registerDevice(studentId, deviceName, bleUuid: bleUuid);
    } finally {
      state = false;
      _refreshStudent(classId, studentId);
    }
  }

  Future<void> replaceDevice(
    String classId,
    String studentId, {
    required String deviceName,
    required String bleUuid,
  }) async {
    state = true;
    try {
      await ref
          .read(deviceRepositoryProvider)
          .replaceDevice(studentId, deviceName, bleUuid: bleUuid);
    } finally {
      state = false;
      _refreshStudent(classId, studentId);
    }
  }

  Future<void> removeDevice(String classId, String studentId) async {
    state = true;
    try {
      await ref.read(deviceRepositoryProvider).removeDevice(studentId);
    } finally {
      state = false;
      _refreshStudent(classId, studentId);
    }
  }

  void _refreshStudent(String classId, String studentId) {
    ref.invalidate(classRosterProvider(classId));
    ref.invalidate(classByIdProvider(classId));
    ref.invalidate(allStudentsProvider);
    ref.invalidate(deviceListProvider);
  }
}
