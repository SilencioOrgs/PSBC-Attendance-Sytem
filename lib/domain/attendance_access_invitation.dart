import 'dart:convert';
import 'dart:io';

import 'subject_invitation.dart';

/// An offline, attendance-only capability and the roster snapshot needed to
/// use it on a device that has never enrolled the students locally.
class AttendanceAccessStudent {
  const AttendanceAccessStudent({
    required this.id,
    required this.name,
    required this.studentNumber,
    this.bleUuid,
    this.deviceName,
  });

  final String id;
  final String name;
  final String studentNumber;
  final String? bleUuid;
  final String? deviceName;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'studentNumber': studentNumber,
    if (bleUuid != null) 'bleUuid': bleUuid,
    if (deviceName != null) 'deviceName': deviceName,
  };

  factory AttendanceAccessStudent.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Invalid attendance roster entry.');
    }
    final uuid = value['bleUuid'];
    final deviceName = value['deviceName'];
    if (uuid != null && (uuid is! String || uuid.trim().isEmpty) ||
        deviceName != null &&
            (deviceName is! String || deviceName.trim().isEmpty)) {
      throw const FormatException('Invalid attendance device details.');
    }
    return AttendanceAccessStudent(
      id: _requiredString(value, 'id'),
      name: _requiredString(value, 'name'),
      studentNumber: _requiredString(value, 'studentNumber'),
      bleUuid: uuid as String?,
      deviceName: deviceName as String?,
    );
  }
}

/// One selected class offering and the global roster identities enrolled in it.
class AttendanceAccessOffering {
  const AttendanceAccessOffering({
    required this.offering,
    required this.rosterStudentIds,
  });

  final SubjectInvitationOffering offering;
  final List<String> rosterStudentIds;

  Map<String, Object?> toJson() => {
    ...offering.toJson(),
    'rosterStudentIds': rosterStudentIds,
  };

  factory AttendanceAccessOffering.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Invalid attendance subject details.');
    }
    final rosterValue = value['rosterStudentIds'];
    if (rosterValue is! List<Object?>) {
      throw const FormatException('Invalid attendance subject roster.');
    }
    final rosterStudentIds = rosterValue
        .map((id) {
          if (id is! String || id.trim().isEmpty) {
            throw const FormatException('Invalid attendance subject roster.');
          }
          return id.trim();
        })
        .toList(growable: false);
    if (rosterStudentIds.toSet().length != rosterStudentIds.length) {
      throw const FormatException(
        'The attendance subject has duplicate students.',
      );
    }
    return AttendanceAccessOffering(
      offering: SubjectInvitationOffering.fromJson(
        value,
        allowNoSchedule: true,
      ),
      rosterStudentIds: rosterStudentIds,
    );
  }
}

class AttendanceAccessInvitation {
  AttendanceAccessInvitation({
    required this.invitationId,
    required this.issuedAt,
    required this.teacherId,
    required this.teacherName,
    required this.roster,
    SubjectInvitationOffering? offering,
    List<AttendanceAccessOffering>? offerings,
    this.role = 'attendance',
  }) : offerings =
           offerings ??
           (offering == null
               ? const <AttendanceAccessOffering>[]
               : [
                   AttendanceAccessOffering(
                     offering: offering,
                     rosterStudentIds: roster
                         .map((student) => student.id)
                         .toList(),
                   ),
                 ]) {
    if (this.offerings.isEmpty) {
      throw ArgumentError('An attendance invitation must include an offering.');
    }
  }

  static const type = 'classattend.attendance_access';
  static const version = 2;
  static const maxOfferingCount = 30;
  static const maxRosterSize = 1000;
  static const maxJsonLength = 1000000;

  final String invitationId;
  final DateTime issuedAt;
  final String role;
  final String teacherId;
  final String teacherName;
  final List<AttendanceAccessOffering> offerings;
  final List<AttendanceAccessStudent> roster;

  /// Compatibility accessor for callers presenting a single offering.
  SubjectInvitationOffering get offering => offerings.first.offering;

  String encode() => jsonEncode({
    'type': type,
    'version': version,
    'invitationId': invitationId,
    'issuedAt': issuedAt.toUtc().toIso8601String(),
    'role': role,
    'teacher': {'id': teacherId, 'name': teacherName},
    'offerings': offerings.map((item) => item.toJson()).toList(),
    'roster': roster.map((student) => student.toJson()).toList(),
  });

  factory AttendanceAccessInvitation.decode(String raw) {
    if (raw.length > maxJsonLength) {
      throw const FormatException('The attendance QR is too large.');
    }
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Invalid attendance QR.');
    }
    if (decoded is! Map<String, Object?> || decoded['type'] != type) {
      throw const FormatException('This QR is not for attendance access.');
    }
    final payloadVersion = decoded['version'];
    if (payloadVersion != 1 && payloadVersion != version) {
      throw const FormatException(
        'This attendance QR is not supported by this app version.',
      );
    }
    if (decoded['role'] != 'attendance') {
      throw const FormatException('This QR is not for attendance access.');
    }
    final teacher = decoded['teacher'];
    final rosterValue = decoded['roster'];
    if (teacher is! Map<String, Object?> ||
        rosterValue is! List<Object?> ||
        (payloadVersion == 1 && rosterValue.isEmpty) ||
        rosterValue.length > maxRosterSize) {
      throw const FormatException('The attendance QR is incomplete.');
    }
    final issuedAtValue = decoded['issuedAt'];
    final issuedAt = issuedAtValue is String
        ? DateTime.tryParse(issuedAtValue)
        : null;
    if (issuedAt == null) {
      throw const FormatException('The attendance QR issue date is invalid.');
    }
    final roster = rosterValue
        .map(AttendanceAccessStudent.fromJson)
        .toList(growable: false);
    final ids = roster.map((student) => student.id).toSet();
    if (ids.length != roster.length) {
      throw const FormatException('The attendance roster has duplicate IDs.');
    }
    final offerings = payloadVersion == 1
        ? [
            AttendanceAccessOffering(
              offering: SubjectInvitationOffering.fromJson(
                decoded['offering'],
                allowNoSchedule: true,
              ),
              rosterStudentIds: roster.map((student) => student.id).toList(),
            ),
          ]
        : (decoded['offerings'] is List<Object?>
              ? (decoded['offerings'] as List<Object?>)
                    .map(AttendanceAccessOffering.fromJson)
                    .toList(growable: false)
              : throw const FormatException(
                  'The attendance QR is incomplete.',
                ));
    if (offerings.isEmpty || offerings.length > maxOfferingCount) {
      throw const FormatException(
        'The attendance QR must include between 1 and 30 subjects.',
      );
    }
    final offeringIds = offerings.map((item) => item.offering.id).toSet();
    if (offeringIds.length != offerings.length) {
      throw const FormatException('The attendance QR has duplicate subjects.');
    }
    final referencedStudentIds = <String>{};
    for (final item in offerings) {
      if (item.rosterStudentIds.any((id) => !ids.contains(id))) {
        throw const FormatException(
          'The attendance subject roster is invalid.',
        );
      }
      referencedStudentIds.addAll(item.rosterStudentIds);
    }
    if (referencedStudentIds.length != roster.length) {
      throw const FormatException(
        'The attendance QR contains unused students.',
      );
    }
    final uuids = roster
        .map((student) => student.bleUuid?.trim().toLowerCase())
        .whereType<String>()
        .toSet();
    if (uuids.length !=
        roster.where((student) => student.bleUuid != null).length) {
      throw const FormatException(
        'The attendance QR has duplicate BLE devices.',
      );
    }
    return AttendanceAccessInvitation(
      invitationId: _requiredString(decoded, 'invitationId'),
      issuedAt: issuedAt.toUtc(),
      teacherId: _requiredString(teacher, 'id'),
      teacherName: _requiredString(teacher, 'name'),
      offerings: offerings,
      roster: roster,
    );
  }
}

/// QR transport frames keep realistic rosters within camera-readable symbols.
/// Each frame is independently typed and bounded before it is accumulated.
class AttendanceAccessQrFrame {
  const AttendanceAccessQrFrame({
    required this.invitationId,
    required this.index,
    required this.total,
    required this.data,
  });

  static const type = 'classattend.attendance_access_frame';
  static const version = 1;
  static const frameDataLength = 900;
  static const maxFrames = 300;

  final String invitationId;
  final int index;
  final int total;
  final String data;

  String encode() => jsonEncode({
    'type': type,
    'version': version,
    'invitationId': invitationId,
    'index': index,
    'total': total,
    'data': data,
  });

  factory AttendanceAccessQrFrame.decode(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Invalid attendance QR.');
    }
    if (decoded is! Map<String, Object?> || decoded['type'] != type) {
      throw const FormatException('This QR is not an attendance-access QR.');
    }
    if (decoded['version'] != version) {
      throw const FormatException(
        'This attendance QR is not supported by this app version.',
      );
    }
    final index = decoded['index'];
    final total = decoded['total'];
    final data = decoded['data'];
    if (index is! int ||
        total is! int ||
        total < 1 ||
        total > maxFrames ||
        index < 0 ||
        index >= total ||
        data is! String ||
        data.isEmpty ||
        data.length > frameDataLength) {
      throw const FormatException('The attendance QR frame is invalid.');
    }
    return AttendanceAccessQrFrame(
      invitationId: _requiredString(decoded, 'invitationId'),
      index: index,
      total: total,
      data: data,
    );
  }

  static List<AttendanceAccessQrFrame> createFrames(
    AttendanceAccessInvitation invitation,
  ) {
    final raw = invitation.encode();
    AttendanceAccessInvitation.decode(raw);
    final compressed = gzip.encode(utf8.encode(raw));
    final encoded = base64Url.encode(compressed);
    final total = (encoded.length / frameDataLength).ceil();
    if (total > maxFrames) {
      throw const FormatException('The class roster is too large to share.');
    }
    return List.generate(total, (index) {
      final start = index * frameDataLength;
      final end = (start + frameDataLength).clamp(0, encoded.length).toInt();
      return AttendanceAccessQrFrame(
        invitationId: invitation.invitationId,
        index: index,
        total: total,
        data: encoded.substring(start, end),
      );
    }, growable: false);
  }

  static AttendanceAccessInvitation decodeFrames(
    List<AttendanceAccessQrFrame> frames,
  ) {
    if (frames.isEmpty) throw const FormatException('Invalid attendance QR.');
    final first = frames.first;
    if (frames.length != first.total ||
        frames.any(
          (frame) =>
              frame.invitationId != first.invitationId ||
              frame.total != first.total,
        )) {
      throw const FormatException('The attendance QR set is incomplete.');
    }
    final ordered = List<AttendanceAccessQrFrame>.of(frames)
      ..sort((a, b) => a.index.compareTo(b.index));
    for (var index = 0; index < ordered.length; index++) {
      if (ordered[index].index != index) {
        throw const FormatException('The attendance QR set is incomplete.');
      }
    }
    try {
      final compressed = base64Url.decode(
        ordered.map((frame) => frame.data).join(),
      );
      final raw = utf8.decode(gzip.decode(compressed));
      return AttendanceAccessInvitation.decode(raw);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid attendance QR.');
    }
  }
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key.');
  }
  return value.trim();
}

/// Stable roster identity shared by every offering in one attendance grant.
String attendanceAccessStudentId(String sourceStudentId) =>
    'attendance:$sourceStudentId';

/// IDs written by earlier builds included the local offering ID.
String legacyAttendanceAccessStudentId(
  String localOfferingId,
  String sourceStudentId,
) => 'attendance:$localOfferingId:$sourceStudentId';
