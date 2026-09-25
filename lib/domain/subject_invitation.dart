import 'dart:convert';

import 'models.dart';

class SubjectInvitationOffering {
  const SubjectInvitationOffering({
    required this.id,
    required this.subject,
    required this.sectionCode,
    required this.gradeLevel,
    required this.sectionLabel,
    required this.room,
    required this.scheduleDays,
    required this.startMinutesOfDay,
    required this.endMinutesOfDay,
  });

  final String id;
  final String subject;
  final String sectionCode;
  final int gradeLevel;
  final String sectionLabel;
  final String room;
  final Set<Weekday> scheduleDays;
  final int startMinutesOfDay;
  final int endMinutesOfDay;

  Map<String, Object?> toJson() => {
    'id': id,
    'subject': subject,
    'sectionCode': sectionCode,
    'gradeLevel': gradeLevel,
    'sectionLabel': sectionLabel,
    'room': room,
    'scheduleDays': scheduleDays.map((day) => day.name).toList()..sort(),
    'startMinutesOfDay': startMinutesOfDay,
    'endMinutesOfDay': endMinutesOfDay,
  };

  factory SubjectInvitationOffering.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('Invalid subject details.');
    }
    final daysValue = value['scheduleDays'];
    if (daysValue is! List<Object?>) {
      throw const FormatException('Invalid subject schedule days.');
    }
    final days = <Weekday>{};
    for (final item in daysValue) {
      if (item is! String || !Weekday.values.any((day) => day.name == item)) {
        throw const FormatException('Invalid subject schedule day.');
      }
      if (!days.add(Weekday.values.byName(item))) {
        throw const FormatException('Duplicate subject schedule day.');
      }
    }
    final offering = SubjectInvitationOffering(
      id: _requiredString(value, 'id'),
      subject: _requiredString(value, 'subject'),
      sectionCode: _requiredString(value, 'sectionCode'),
      gradeLevel: _requiredInt(value, 'gradeLevel'),
      sectionLabel: _requiredString(value, 'sectionLabel'),
      room: _requiredString(value, 'room'),
      scheduleDays: days,
      startMinutesOfDay: _requiredInt(value, 'startMinutesOfDay'),
      endMinutesOfDay: _requiredInt(value, 'endMinutesOfDay'),
    );
    if (offering.gradeLevel < 1 ||
        days.isEmpty ||
        offering.startMinutesOfDay < 0 ||
        offering.startMinutesOfDay >= 1440 ||
        offering.endMinutesOfDay < 1 ||
        offering.endMinutesOfDay >= 1440 ||
        offering.endMinutesOfDay <= offering.startMinutesOfDay) {
      throw const FormatException('Invalid subject schedule.');
    }
    return offering;
  }
}

class SubjectInvitation {
  const SubjectInvitation({
    required this.teacherId,
    required this.teacherName,
    required this.offerings,
  });
  static const type = 'classattend.subject_invitation';
  static const version = 1;

  final String teacherId;
  final String teacherName;
  final List<SubjectInvitationOffering> offerings;

  String encode() => jsonEncode({
    'type': type,
    'version': version,
    'teacher': {'id': teacherId, 'name': teacherName},
    'offerings': offerings.map((offering) => offering.toJson()).toList(),
  });

  factory SubjectInvitation.decode(String raw) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException(
        'This QR code is not a valid ClassAttend subject invitation.',
      );
    }
    if (decoded is! Map<String, Object?> ||
        decoded['type'] != type ||
        decoded['version'] != version) {
      throw const FormatException('This QR code format is not supported.');
    }
    final teacher = decoded['teacher'];
    final offeringsValue = decoded['offerings'];
    if (teacher is! Map<String, Object?> ||
        offeringsValue is! List<Object?> ||
        offeringsValue.isEmpty ||
        offeringsValue.length > 30) {
      throw const FormatException('The subject invitation is incomplete.');
    }
    final offerings = offeringsValue
        .map(SubjectInvitationOffering.fromJson)
        .toList(growable: false);
    final ids = offerings.map((offering) => offering.id).toSet();
    final subjects = offerings
        .map((offering) => offering.subject.trim().toLowerCase())
        .toSet();
    if (ids.length != offerings.length || subjects.length != offerings.length) {
      throw const FormatException(
        'The invitation contains duplicate subjects.',
      );
    }
    return SubjectInvitation(
      teacherId: _requiredString(teacher, 'id'),
      teacherName: _requiredString(teacher, 'name'),
      offerings: offerings,
    );
  }
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key.');
  }
  return value.trim();
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('Missing $key.');
  return value;
}
