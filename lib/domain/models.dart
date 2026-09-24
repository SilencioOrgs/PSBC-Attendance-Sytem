/// Synchronization lifecycle for locally persisted records.
enum SyncStatus { synced, pendingCreate, pendingUpdate, pendingDelete }

enum AttendanceSessionStatus { scanning, review, completed, cancelled }

enum AttendanceRecordStatus {
  present,
  absent,
  notDetected,
  manualPresent,
  manualAbsent,
}

class Teacher {
  const Teacher({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.name,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String name;
}

class Student {
  const Student({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.name,
    required this.studentNumber,
    required this.classId,
    required this.gradeLevel,
    required this.deviceRegistered,
    this.sectionCode = '',
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String name;
  final String studentNumber;
  final String classId;
  final String gradeLevel;
  final bool deviceRegistered;
  final String sectionCode;
}

class ClassSection {
  const ClassSection({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.name,
    required this.subject,
    required this.room,
    required this.schedule,
    required this.studentCount,
    this.gradeLevel = 0,
    this.sectionLabel = '',
    this.sectionCode = '',
    this.scheduleStart,
    this.scheduleEnd,
    this.bleBeaconId = '',
    this.teacherId = '',
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String name;
  final String subject;
  final String room;
  final String schedule;
  final int studentCount;
  final int gradeLevel;
  final String sectionLabel;
  final String sectionCode;
  final DateTime? scheduleStart;
  final DateTime? scheduleEnd;
  final String bleBeaconId;
  final String teacherId;
}

class Enrollment {
  const Enrollment({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.studentId,
    required this.classId,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String studentId;
  final String classId;
}

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.classId,
    required this.title,
    required this.startedAt,
    required this.status,
    this.date,
    this.endedAt,
    this.scanDurationSeconds = 0,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String classId;
  final String title;
  final DateTime startedAt;

  /// Presentation label retained for the existing screens.
  final AttendanceSessionStatus status;
  final DateTime? date;
  final DateTime? endedAt;
  final int scanDurationSeconds;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.sessionId,
    required this.studentId,
    required this.isPresent,
    required this.detectedAt,
    this.rssi,
    this.recordStatus,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String sessionId;
  final String studentId;
  final bool isPresent;
  final DateTime? detectedAt;
  final int? rssi;
  final AttendanceRecordStatus? recordStatus;

  AttendanceRecord copyWith({
    bool? isPresent,
    DateTime? detectedAt,
    int? rssi,
  }) => AttendanceRecord(
    id: id,
    updatedAt: DateTime.now(),
    syncStatus: SyncStatus.pendingUpdate,
    sessionId: sessionId,
    studentId: studentId,
    isPresent: isPresent ?? this.isPresent,
    detectedAt: detectedAt ?? this.detectedAt,
    rssi: rssi ?? this.rssi,
    recordStatus: (isPresent ?? this.isPresent)
        ? AttendanceRecordStatus.manualPresent
        : AttendanceRecordStatus.manualAbsent,
  );
}

class Device {
  const Device({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.name,
    required this.bleUuid,
    required this.ownerStudentId,
    this.deviceModel = '',
    this.registeredAt,
    this.rssi,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String name;

  /// The UUID placed in the device's BLE service UUID advertisement.
  final String bleUuid;
  final String? ownerStudentId;
  final String deviceModel;
  final DateTime? registeredAt;
  final int? rssi;
}

class AppSettings {
  const AppSettings({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.scanDurationSeconds,
    this.rssiThreshold = -75,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final int scanDurationSeconds;
  final int rssiThreshold;
}

class BleScanUpdate {
  const BleScanUpdate({
    required this.progress,
    required this.discoveredDevices,
    required this.isComplete,
    required this.unknownDeviceCount,
  });
  final double progress;
  final List<Device> discoveredDevices;
  final bool isComplete;
  final int unknownDeviceCount;
}

enum BleAvailability {
  unknown,
  ready,
  poweredOff,
  permissionDenied,
  unsupported,
}

/// Runtime state of the student attendance advertisement.
enum BleAdvertisingState {
  unknown,
  stopped,
  active,
  bluetoothOff,
  permissionRequired,
  unsupported,
}
