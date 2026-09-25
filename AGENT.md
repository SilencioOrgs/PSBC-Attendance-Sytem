AGENT.md — ClassAttend Engineering Standards

This document is mandatory for every AI coding agent working on this repository.

Read this file completely before modifying code.

The purpose of this project is to build a reliable offline-first Flutter attendance application for teachers and students.

The application is not a UI prototype.

All functionality must be implemented as real application behavior with persistent local state, predictable architecture, testable business logic, and honest Android/BLE behavior.

1. ENGINEERING ROLE

You are a senior Flutter, Dart, Android, BLE, database, and mobile UX engineer.

Write production-quality code that another engineer can understand without reconstructing your reasoning.

Prefer:

typed code

immutable state

repository abstractions

Riverpod

Drift

small focused services

testable business rules

explicit application states

predictable navigation

offline-first behavior

Do not create demo-quality shortcuts.

Do not use temporary hacks as permanent architecture.

2. NON-NEGOTIABLE RULES

2.1 State management

Riverpod is the only application state-management solution.

Do NOT introduce:

Provider

Bloc

Cubit

GetX

Redux

MobX

ad-hoc global mutable state

setState is acceptable only for strictly local presentation state that does not belong in application state.

2.2 Persistence

Drift/SQLite is the local source of truth for persistent application data.

Important data must not exist only in:

widget state

provider memory

static variables

singleton fields

temporary caches

A Flutter restart must not destroy persistent user state.

2.3 Offline-first

Core application functionality must work without internet.

Do not add a backend dependency for:

student enrollment

subject enrollment

BLE attendance

attendance history

teacher/student profiles

QR enrollment must work entirely phone-to-phone without a server.

2.4 No fake production data

All mock/demo/seed data belongs in:

lib/mock/
test/
integration_test/
tool/

Production feature code must never depend on fake attendance or random BLE discovery.

Never expose:

Load demo data

Dummy data

Simulate BLE

Fake attendance

Developer role preview

Sample classes

through normal production navigation.

2.5 No raw service access from widgets

Screens must not directly access:

Drift database

BLE package APIs

secure storage

Android MethodChannels

PDF generators

CSV generators

native file APIs

Preferred flow:

Screen
  ↓
Riverpod Provider / Notifier
  ↓
Application / Controller
  ↓
Domain Service / Repository Interface
  ↓
Implementation

2.6 Domain purity

Domain code must not depend on Flutter UI APIs.

Domain should contain:

entities

value objects

enums

repository interfaces

business rules

use-case contracts

No Flutter widget imports in domain.

3. TARGET ARCHITECTURE

Keep the repository's existing general architecture rather than performing a destructive full rewrite.

Target:

lib/
│
├── core/
│   ├── auth/
│   ├── router/
│   ├── session/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── services/
│   ├── ble/
│   ├── storage/
│   ├── auth/
│   ├── background/
│   └── export/
│
├── features/
│   │
│   ├── authentication/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── student/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── classes/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── enrollments/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── devices/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── attendance/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── reports/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── settings/
│       ├── domain/
│       ├── data/
│       └── presentation/
│
└── mock/

Do not move files only for naming purposes.

Move code when responsibility is actually wrong.

4. CORE DOMAIN MODEL

The product has four fundamentally different concepts.

They must never be confused.

Student identity

Who the student is.

Student

Device identity

Which phone belongs to that student.

Device
    ↓
BLE Service UUID

Subject enrollment

Which subjects/classes the student belongs to.

Student
    ↓
Enrollment
    ↓
Class Offering

Attendance session

A specific attendance event for one subject.

Class Offering
    ↓
Attendance Session
    ↓
Attendance Record

5. CRITICAL IDENTITY RULE

One student phone has ONE permanent BLE attendance identity.

Example:

Student:
Asnor Sumdad

Device:
Phone A

BLE UUID:
12345678-....

That same BLE UUID is used for:

CPE1

Database Systems

Programming

any other enrolled subject

Do NOT create:

CPE1 → UUID A
Database → UUID B
Programming → UUID C

That architecture is forbidden.

6. BLE UUID LIFECYCLE

Generate the BLE UUID exactly once.

Initial registration:

No device
    ↓
Generate UUID
    ↓
Persist UUID

Later:

App restart
    ↓
Load existing device
    ↓
Use existing UUID

The UUID must NOT change because of:

app restart

provider rebuild

screen rebuild

opening Device screen

changing subject

adding subject

removing subject

starting beacon

stopping beacon

backgrounding app

editing student name

The UUID may change only when:

device is explicitly replaced

student profile is explicitly reset

app/database data is deliberately cleared

7. STUDENT MODEL

A Student must represent student identity, not a single class.

Do NOT treat:

Student.classId

as the authoritative subject relationship.

Student membership is represented by Enrollment records.

Example:

Student A
  ├── Enrollment → CPE1
  ├── Enrollment → Database
  └── Enrollment → Programming

A student may have many subjects.

8. DEVICE MODEL

A Device belongs to one student.

Preferred fields:

id
studentId
bleUuid
deviceModel
registeredAt
updatedAt
syncStatus

bleUuid must be unique.

A single active BLE identity must not belong to multiple students.

Do not use:

MAC address

IMEI

serial number

device array index

random display name

as the primary attendance identity.

9. CLASS OFFERING MODEL

The current physical database table may remain named ClassSections if changing the SQL table name would create unnecessary migration risk.

However, at the domain/business level, treat it as:

ClassOffering

A ClassOffering represents one subject being taught.

Example:

Teacher A
  |
  ├── CPE1
  ├── Database Systems
  └── Programming

The section is not globally unique.

This must be valid:

GRADE12-STEM A + CPE1
GRADE12-STEM A + Database Systems
GRADE12-STEM A + Programming

Do not make sectionCode alone unique.

Use an appropriate offering uniqueness rule, such as a teacher + section + subject combination, with explicit duplicate validation.

10. ENROLLMENT MODEL

Use the existing Enrollment relationship as the authoritative student-subject relationship.

Unique relationship:

studentId + classOfferingId

A student cannot be enrolled twice in the same offering.

The same student can enroll in many different offerings.

11. SCHEDULE MODEL

Recurring schedules must be represented structurally.

A schedule should contain:

days
startTime
endTime

Example:

CPE1
Monday
09:30–10:30

Do not store recurring schedules only as a formatted display string.

Prefer structured storage such as:

scheduleDays
startMinutes
endMinutes

or an equivalent typed representation.

Existing data must be migrated safely.

12. ATTENDANCE WINDOW

Attendance is subject-specific and time-specific.

A teacher cannot accidentally scan an unrelated subject at an arbitrary time.

Before starting an attendance session:

Current date/time
        ↓
Selected ClassOffering
        ↓
Schedule Policy
        ↓
Allowed?

Default policy may use:

early grace = 10 minutes
late grace = 15 minutes

Example:

CPE1:
09:30–10:30

Allowed window:

09:20–10:45

Outside this window:

Do not start the normal attendance scan.

13. ATTENDANCE OVERRIDE

A teacher may explicitly choose:

Start Anyway

when outside the schedule.

This must be intentional and clearly marked.

The session should record:

manualOverride = true

Never bypass schedule rules silently.

14. ATTENDANCE SESSION

Every session must belong to exactly one class offering.

Conceptually:

AttendanceSession
    ↓
classOfferingId

Therefore the session inherently knows:

teacher

subject

section

schedule

enrolled students

Do not create generic attendance sessions detached from a subject.

15. BLE ATTENDANCE MATCHING

The scanner must match:

Detected BLE Service UUID
        ↓
Registered Device
        ↓
Student
        ↓
Enrollment
        ↓
Current ClassOffering
        ↓
Attendance Record

A student is present only if:

their BLE UUID is detected

that BLE UUID belongs to a known device

the device belongs to a student

that student is enrolled in the active class offering

Otherwise ignore the device for attendance.

16. CROSS-SUBJECT PROTECTION

If Student A is enrolled in:

CPE1
Database

and Teacher scans CPE1:

Student A may be marked present for CPE1.

The Database enrollment must have no effect.

Likewise:

Student BLE active
+
Teacher opens Database outside Database's schedule

must not create attendance.

17. STUDENT PROFILE PERSISTENCE

Students do NOT have passwords.

Students do NOT have PINs.

Students should register once on the device.

After registration:

Close app
↓
Open app
↓
Student Home

No repeated setup.

No repeated login.

No repeated student profile creation.

18. TEACHER + STUDENT ON THE SAME PHONE

The application must support a single physical device containing both:

Teacher profile
Student profile

Teacher authentication remains PIN-protected.

Student does not require a password.

Persist:

lastActiveRole
activeStudentId
activeTeacherId if needed

Startup behavior:

If only teacher exists:
→ Teacher unlock

If only student exists:
→ Student Home

If both exist:
→ restore the last active role

Switching to teacher:
→ require teacher PIN

Switching to student:
→ open existing student profile

Do not delete or recreate either profile.

19. APPLICATION SESSION

Create an application-level session/bootstrap layer responsible for deciding:

uninitialized
teacherSetupRequired
teacherLocked
teacherAuthenticated
studentAvailable
studentActive

Do not make the router assume a teacher-only world.

Startup must load persistent state before choosing the initial route.

20. STUDENT SUBJECT ENROLLMENT

Students initially create only:

name

student number

They can then add subjects.

Subject enrollment comes from teacher-created QR codes.

The student must not need a teacher class already stored on the student's phone.

21. TEACHER MULTI-SUBJECT QR

Teacher can generate one QR containing multiple subject offerings.

Example:

Teacher A:

CPE1
Monday 09:30–10:30

Database Systems
Tuesday 13:00–14:00

Programming
Wednesday 15:00–16:00

The QR payload must be:

versioned

typed

structured

validated

offline

safe to parse

Do not put raw database rows into the QR.

22. STUDENT QR FLOW

Student:

My Subjects
    ↓
Add Subject
    ↓
Scan Teacher QR
    ↓
Preview subjects
    ↓
Select subjects
    ↓
Add

After scanning, show:

Teacher name

Subject
Section
Schedule
Room

Allow:

Select All

or individual selections.

Do not insert records before confirmation.

23. DUPLICATE SUBJECT ENROLLMENT

If a subject is already enrolled:

Do not duplicate it.

Show a clear message.

If the QR contains:

one existing subject

two new subjects

only add the new ones.

24. QR SECURITY MODEL

A QR code is an offline enrollment invitation.

It is not cryptographic proof of identity.

Do not put:

teacher PIN

private credentials

unnecessary secrets

inside the QR.

The student should preview and approve imported subjects.

25. STUDENT DEVICE BACKGROUND ATTENDANCE

Student background attendance is independent of subject.

The student should be able to:

Register once
↓
Enable Background Attendance
↓
Keep beacon active
↓
Put phone away

The student must not have to:

Start CPE1 beacon
Stop CPE1 beacon
Start Database beacon
Stop Database beacon

The beacon identity is device-level.

The teacher's active subject determines whether it counts.

26. BACKGROUND BLE ARCHITECTURE

Do not tie persistent advertising to Flutter widget lifecycle.

Current behavior that stops advertising on:

paused
hidden
detached

must not control the persistent student beacon.

Preferred architecture:

Student UI
    ↓
Student Background Attendance Controller
    ↓
Background Attendance Service
    ↓
Android Foreground Service
    ↓
BLE Peripheral Advertising

The Android foreground service owns the long-running advertising operation.

Flutter only controls and observes it.

27. ANDROID BACKGROUND RULES

Do not promise unlimited background operation.

Support:

app minimized

screen locked

normal background usage

Subject to Android and OEM limitations.

The service must be started from an explicit student action while the app is visible.

Use the current Android target SDK and documented foreground-service requirements.

28. BACKGROUND SERVICE STATE

The UI must reflect actual service state.

Valid states include:

inactive
starting
active
bluetoothOff
permissionRequired
unsupported
error

Do not display:

Active

merely because the user pressed the button.

29. FOREGROUND SERVICE NOTIFICATION

When background attendance is active, show an ongoing Android notification such as:

ClassAttend

Background attendance active

Your device is available for classroom attendance.

Do not hide the fact that BLE advertising is operating.

30. FORCE-STOP LIMITATION

Do not claim that attendance survives an Android Force Stop.

Document that:

force-stop may terminate background operation

OEM battery management may interrupt the service

Bluetooth being disabled stops advertising

The UI must reflect actual state.

31. TEACHER SCANNER

The teacher scanner is currently working.

Do not rewrite it unnecessarily.

Preserve:

scan progress

device counts

detected students

unknown device count

attendance review

manual attendance

save attendance

Only integrate:

schedule validation

subject-specific roster

permanent student BLE identity

32. ATTENDANCE STATUS

Keep these statuses distinct:

present
notDetected
manualPresent
manualAbsent
absent

notDetected must not silently become absent.

The teacher must explicitly finalize attendance.

33. SHARED UI

Use the existing reusable components.

Prefer:

AppTopBar

StatusPill

SectionCard

PersonListTile

MetricStatCard

BleRadarIndicator

OfflineStatusChip

PrimaryActionButton

SecondaryActionButton

AppEmptyState

AppErrorState

AppLoading

AppDialog

AppBottomSheet

Do not duplicate near-identical components between screens.

34. RESPONSIVE UI

No fixed desktop-style widths copied from screenshots.

Use:

SafeArea

LayoutBuilder

MediaQuery

Flexible

Expanded

Wrap

Test narrow phones around 360px and larger/tablet layouts.

35. DATABASE MIGRATIONS

Never delete user data to solve schema changes.

Whenever changing Drift schema:

increment schemaVersion

create migration

preserve existing data

regenerate Drift code

test migration

Existing:

teachers

students

devices

enrollments

classes

attendance sessions

attendance records

must remain intact.

36. CODE QUALITY

Before a file is considered complete:

no analyzer errors

no unresolved TODO

no dead imports

no unnecessary !

no raw exception text in UI

no business logic in build()

no direct database access from widgets

no direct BLE package usage from widgets

no duplicated UUID generation

no hidden state mutation

no fake production data

37. TESTING

At minimum test:

Session

teacher persistence

student persistence

teacher + student coexistence

last active role

Student

registration

restart

profile reset

multiple enrollments

Device

UUID generated once

UUID persisted

UUID survives restart

UUID survives subject changes

device replacement

Classes

multiple subjects for same section

duplicate offering prevention

schedule days

Attendance

within schedule

too early

too late

wrong day

override

subject-specific roster

same student across multiple subjects

manual status

finalization

BLE

advertisement UUID matching

unknown device

duplicate discovery

permission denial

Bluetooth disabled

advertising state

QR

payload generation

parsing

duplicate subject

invalid payload

38. VERIFICATION REQUIREMENT

Run:

flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug

Do not finish with:

compilation errors

analyzer errors

failing tests

broken generated Drift code

39. PHYSICAL BLE TEST

A feature involving BLE is not considered verified by compilation alone.

Use two physical Android devices.

Student phone:

register student

enable background attendance

lock screen

Teacher phone:

select active subject

start attendance

Verify:

Student BLE detected
↓
Student matched
↓
Correct subject enrollment
↓
Present

Repeat after student app restart.

40. FINAL PRODUCT MODEL

The final architecture must represent:

TEACHER
   |
   └── Class Offerings
          ├── CPE1
          ├── Database
          └── Programming


STUDENT
   |
   └── One Device
          └── One permanent BLE UUID

STUDENT
   |
   └── Enrollments
          ├── CPE1
          ├── Database
          └── Programming


CLASS OFFERING
   |
   └── Attendance Session
          |
          └── Attendance Records

The key rule is:

ONE STUDENT PHONE
=
ONE PERMANENT BLE IDENTITY

ONE STUDENT
=
MANY SUBJECT ENROLLMENTS

ONE ATTENDANCE SESSION
=
ONE SUBJECT
+
ONE SCHEDULE WINDOW
+
ONE ROSTER

The student's beacon can be active continuously.

The teacher decides when and for which subject that beacon counts.

41. DEVELOPMENT PROCESS

Work in phases.

After each phase:

dart format .
flutter analyze

After database changes:

flutter test

Before finishing:

flutter analyze
flutter test
flutter build apk --debug

Never accumulate unresolved errors across phases.

Do not move on while the current phase has broken compilation.

42. CHANGE DISCIPLINE

Do not perform unrelated rewrites.

Do not change:

PDF/CSV reporting

existing teacher UI

existing manual attendance UI

working scanner visuals

unless required for the new architecture.

Every file change must have a reason.

At the end, provide a concise change report.