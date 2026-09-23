import '../domain/models.dart';

/// Fixed date keeps mock sessions stable and internally consistent.
final DateTime mockNow = DateTime(2026, 9, 23, 8, 30);
const String seedTeacherPin = '2468';

final Teacher seedTeacher = Teacher(
  id: 'teacher-01',
  updatedAt: DateTime(2026, 9, 1),
  syncStatus: SyncStatus.synced,
  name: 'Alex Rivera',
);

final List<ClassSection> seedClasses = [
  ClassSection(
    id: 'stem-a',
    updatedAt: DateTime(2026, 9, 1),
    syncStatus: SyncStatus.synced,
    name: 'Grade 12 - STEM A',
    subject: 'General Physics 2',
    room: 'Room 204',
    schedule: 'Today, 8:00 AM - 9:30 AM',
    studentCount: 35,
    gradeLevel: 12,
    sectionLabel: 'STEM A',
    sectionCode: 'GRADE12-STEM A',
    scheduleStart: DateTime(2026, 9, 23, 8),
    scheduleEnd: DateTime(2026, 9, 23, 9, 30),
    bleBeaconId: 'beacon-stem-a',
    teacherId: 'teacher-01',
  ),
  ClassSection(
    id: 'stem-b',
    updatedAt: DateTime(2026, 9, 1),
    syncStatus: SyncStatus.synced,
    name: 'Grade 12 - STEM B',
    subject: 'Earth and Life Science',
    room: 'Room 206',
    schedule: 'Today, 10:00 AM - 11:30 AM',
    studentCount: 32,
    gradeLevel: 12,
    sectionLabel: 'STEM B',
    sectionCode: 'GRADE12-STEM B',
    scheduleStart: DateTime(2026, 9, 23, 10),
    scheduleEnd: DateTime(2026, 9, 23, 11, 30),
    bleBeaconId: 'beacon-stem-b',
    teacherId: 'teacher-01',
  ),
  ClassSection(
    id: 'humss-a',
    updatedAt: DateTime(2026, 9, 1),
    syncStatus: SyncStatus.synced,
    name: 'Grade 11 - HUMSS A',
    subject: 'Oral Communication',
    room: 'Room 105',
    schedule: 'Today, 1:00 PM - 2:30 PM',
    studentCount: 30,
    gradeLevel: 11,
    sectionLabel: 'HUMSS A',
    sectionCode: 'GRADE11-HUMSS A',
    scheduleStart: DateTime(2026, 9, 23, 13),
    scheduleEnd: DateTime(2026, 9, 23, 14, 30),
    bleBeaconId: 'beacon-humss-a',
    teacherId: 'teacher-01',
  ),
];

const List<String> seedStudentNames = [
  'Maria Santos',
  'Juan Dela Cruz',
  'Angela Reyes',
  'Miguel Garcia',
  'Sofia Mendoza',
  'Gabriel Flores',
  'Isabella Ramos',
  'Noah Aquino',
  'Camila Torres',
  'Liam Castillo',
  'Zoe Navarro',
  'Ethan Bautista',
  'Mia Villanueva',
  'Lucas Fernandez',
  'Chloe Rivera',
  'Daniel Cruz',
  'Ava Morales',
  'Mateo Gonzales',
  'Ella Perez',
  'Nathaniel Lim',
  'Grace Tan',
  'Adrian Ramos',
  'Hannah Flores',
  'Joshua Reyes',
  'Leah Santiago',
  'David Mendoza',
  'Mikaela Garcia',
  'Samuel Torres',
  'Andrea Castillo',
  'Rafael Navarro',
  'Nicole Bautista',
  'Christian Villanueva',
  'Patricia Fernandez',
  'Enzo Morales',
  'Bea Gonzales',
];

final List<Student> seedStemAStudents = List<Student>.generate(
  seedStudentNames.length,
  (index) => Student(
    id: 'student-${(index + 1).toString().padLeft(2, '0')}',
    updatedAt: DateTime(2026, 9, 1),
    syncStatus: SyncStatus.synced,
    name: seedStudentNames[index],
    studentNumber: '2026-${(12001 + index).toString()}',
    classId: 'stem-a',
    gradeLevel: 'Grade 12',
    deviceRegistered: index < 32,
  ),
);

const List<String> _otherClassStudentNames = [
  'Paolo Garcia',
  'Yasmin Reyes',
  'Marco Santos',
  'Lara Castillo',
  'Andre Lim',
  'Janelle Cruz',
  'Vincent Tan',
  'Kyla Mendoza',
  'Roberto Flores',
  'Mara Aquino',
  'Elijah Ramos',
  'Nina Torres',
  'Tristan Navarro',
  'Rhea Bautista',
  'Joaquin Perez',
  'Celine Santiago',
  'Kurt Villanueva',
  'Amara Morales',
  'Dylan Fernandez',
  'Tessa Gonzales',
  'Patrick Rivera',
  'Maya Dela Cruz',
  'Louis Garcia',
  'Arielle Reyes',
  'Gabriel Santos',
  'Bianca Lim',
  'Emilio Cruz',
  'Nadine Tan',
  'Paula Mendoza',
  'Rico Flores',
  'Diana Aquino',
  'Felix Ramos',
  'Iris Torres',
  'Ramon Navarro',
  'Tina Bautista',
];

final List<Student> seedStudents = [
  ...seedStemAStudents,
  for (var index = 0; index < 32; index++)
    Student(
      id: 'stem-b-${(index + 1).toString().padLeft(2, '0')}',
      updatedAt: DateTime(2026, 9, 1),
      syncStatus: SyncStatus.synced,
      name: _otherClassStudentNames[index],
      studentNumber: '2026-${(13001 + index).toString()}',
      classId: 'stem-b',
      gradeLevel: 'Grade 12',
      deviceRegistered: index < 27,
    ),
  for (var index = 0; index < 30; index++)
    Student(
      id: 'humss-a-${(index + 1).toString().padLeft(2, '0')}',
      updatedAt: DateTime(2026, 9, 1),
      syncStatus: SyncStatus.synced,
      name: _otherClassStudentNames[index + 5],
      studentNumber: '2026-${(14001 + index).toString()}',
      classId: 'humss-a',
      gradeLevel: 'Grade 11',
      deviceRegistered: index < 24,
    ),
];

final List<Enrollment> seedEnrollments = [
  for (final student in seedStudents)
    Enrollment(
      id: 'enrollment-${student.id}',
      updatedAt: DateTime(2026, 9, 1),
      syncStatus: SyncStatus.synced,
      studentId: student.id,
      classId: student.classId,
    ),
];

final AttendanceSession seedTodaySession = AttendanceSession(
  id: 'session-stem-a-20260923',
  updatedAt: DateTime(2026, 9, 23, 8, 30),
  syncStatus: SyncStatus.synced,
  classId: 'stem-a',
  title: 'Morning attendance',
  startedAt: DateTime(2026, 9, 23, 8),
  status: 'Completed',
  date: DateTime(2026, 9, 23),
  endedAt: DateTime(2026, 9, 23, 8, 1),
  scanDurationSeconds: 60,
);

final List<AttendanceSession> seedHistoricalSessions = [
  AttendanceSession(
    id: 'session-stem-a-20260922',
    updatedAt: DateTime(2026, 9, 22, 15),
    syncStatus: SyncStatus.synced,
    classId: 'stem-a',
    title: 'Afternoon attendance',
    startedAt: DateTime(2026, 9, 22, 14),
    status: 'Completed',
    date: DateTime(2026, 9, 22),
    endedAt: DateTime(2026, 9, 22, 14, 2),
    scanDurationSeconds: 120,
  ),
  AttendanceSession(
    id: 'session-stem-b-20260922',
    updatedAt: DateTime(2026, 9, 22, 11),
    syncStatus: SyncStatus.synced,
    classId: 'stem-b',
    title: 'Science attendance',
    startedAt: DateTime(2026, 9, 22, 10),
    status: 'Completed',
    date: DateTime(2026, 9, 22),
    endedAt: DateTime(2026, 9, 22, 10, 1),
    scanDurationSeconds: 60,
  ),
];

final List<AttendanceRecord> seedAttendanceRecords = List.generate(
  seedStemAStudents.length,
  (index) => AttendanceRecord(
    id: 'record-${(index + 1).toString().padLeft(2, '0')}',
    updatedAt: DateTime(2026, 9, 23, 8, 30),
    syncStatus: SyncStatus.synced,
    sessionId: seedTodaySession.id,
    studentId: seedStemAStudents[index].id,
    isPresent: index < 32,
    detectedAt: index < 32 ? DateTime(2026, 9, 23, 8, 3 + (index % 20)) : null,
  ),
);

final List<AttendanceRecord> seedHistoricalRecords = [
  ..._historicalRecordsFor(seedHistoricalSessions[0], seedStemAStudents, 30),
  ..._historicalRecordsFor(
    seedHistoricalSessions[1],
    seedStudents.where((student) => student.classId == 'stem-b').toList(),
    29,
  ),
];

List<AttendanceRecord> _historicalRecordsFor(
  AttendanceSession session,
  List<Student> students,
  int presentCount,
) => List<AttendanceRecord>.generate(
  students.length,
  (index) => AttendanceRecord(
    id: 'record-history-${session.id}-$index',
    updatedAt: session.updatedAt,
    syncStatus: SyncStatus.synced,
    sessionId: session.id,
    studentId: students[index].id,
    isPresent: index < presentCount,
    detectedAt: index < presentCount ? DateTime(2026, 9, 22, 14, 5) : null,
  ),
);

final List<Device> seedDevices = List.generate(
  32,
  (index) => Device(
    id: 'device-${(index + 1).toString().padLeft(2, '0')}',
    updatedAt: DateTime(2026, 9, 23, 8, 30),
    syncStatus: SyncStatus.synced,
    name: 'ClassAttend ${seedStudentNames[index].split(' ').first}',
    address: 'D2:8A:40:10:${(index + 1).toString().padLeft(2, '0')}:A1',
    ownerStudentId: seedStemAStudents[index].id,
    isConnected: index < 28,
    lastSeenAt: DateTime(2026, 9, 23, 8, 30),
  ),
);

final AppSettings seedSettings = AppSettings(
  id: 'settings-local',
  updatedAt: DateTime(2026, 9, 1),
  syncStatus: SyncStatus.synced,
  soundEnabled: true,
  vibrationEnabled: true,
  scanDurationSeconds: 8,
  rssiThreshold: -75,
);
