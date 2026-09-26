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

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

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
    this.deviceRegistered = false,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String name;
  final String studentNumber;

  /// A roster projection only; enrollment remains the source of membership.
  final bool deviceRegistered;
}

class ClassOffering {
  const ClassOffering({
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
    this.scheduleDays = const {},
    this.startMinutesOfDay,
    this.endMinutesOfDay,
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
  final Set<Weekday> scheduleDays;
  final int? startMinutesOfDay;
  final int? endMinutesOfDay;
  final String bleBeaconId;
  final String teacherId;
}

/// Compatibility alias while existing class feature names are migrated.
typedef ClassSection = ClassOffering;

class Enrollment {
  const Enrollment({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    required this.studentId,
    required this.classOfferingId,
  });
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String studentId;
  final String classOfferingId;

  @Deprecated('Use classOfferingId.')
  String get classId => classOfferingId;
}

class AttendanceAccessGrant {
  const AttendanceAccessGrant({
    required this.invitationId,
    required this.sourceTeacherId,
    required this.sourceOfferingId,
    required this.localOfferingId,
    required this.subject,
    required this.sectionCode,
    required this.payload,
    required this.grantedAt,
  });

  final String invitationId;
  final String sourceTeacherId;
  final String sourceOfferingId;
  final String localOfferingId;
  final String subject;
  final String sectionCode;
  final String payload;
  final DateTime grantedAt;
}

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.updatedAt,
    required this.syncStatus,
    String? classId,
    String? classOfferingId,
    required this.title,
    required this.startedAt,
    required this.status,
    this.date,
    this.endedAt,
    this.scanDurationSeconds = 0,
    this.manualOverride = false,
  }) : classOfferingId = classOfferingId ?? classId ?? '';
  final String id;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String classOfferingId;
  @Deprecated('Use classOfferingId.')
  String get classId => classOfferingId;
  final String title;
  final DateTime startedAt;

  /// Presentation label retained for the existing screens.
  final AttendanceSessionStatus status;
  final DateTime? date;
  final DateTime? endedAt;
  final int scanDurationSeconds;
  final bool manualOverride;
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
