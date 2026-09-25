# ClassAttend Paete

ClassAttend is an offline-first Flutter app for teachers to manage class rosters, take BLE-assisted attendance, review manual changes, retain attendance history, and export PDF or CSV reports. Student setup creates a local student profile and a BLE attendance identity that can be shared with the teacher. There is no backend or cloud account.

## Main flows

### Teacher

1. On first launch, create a teacher PIN. Later launches require the PIN to unlock the teacher area.
2. Create a class offering with a subject, section, room, weekdays, and start/end times. The same section can have multiple subjects.
3. Add students to each offering. A student number identifies one student across offerings; register one BLE device for that student and use **Replace device** only when the physical phone changes.
4. Optionally share selected offerings as a versioned offline subject QR. It contains teacher/offering display and schedule data, not credentials. A student scanning it stores local enrollment only; it does not update the teacher's separate offline database. The teacher still adds the student and BLE service UUID to each applicable roster.
5. Start attendance. The selected offering defines the schedule and roster. Scans only accept a registered BLE UUID when its owner is enrolled in that offering.
5. Review results. Detected students are Present; the rest remain Not Detected until the teacher saves. Manual Present and Manual Absent changes are retained as manual statuses.
6. Confirm the save rule to convert remaining Not Detected students to Absent. The session and its records are committed together. History links to session details and exports.

### Student device registration

1. Create one local student profile. On restart, the app loads that profile without student credentials; if teacher and student profiles coexist, startup restores the last selected role. Teacher access still requires the PIN.
2. Register this phone once. Its permanent BLE service UUID is stored in the Drift device row and reused for foreground and background advertising, across app and screen restarts.
3. Add subjects by scanning a teacher's offline QR invitation and confirming selected offerings. Enrollment is many-to-many; the profile and device stay the same for every subject.
4. Enable **Background Attendance** to start Android's connected-device foreground service. The ongoing notification remains while the service is active. The service advertises the stored UUID, not a session or subject identity.

## Offline architecture

- `core/` contains routing, theme, shared utilities, and provider setup.
- `features/` contains feature screens, providers/controllers, and Drift-backed repositories.
- `domain/` contains shared domain models and repository contracts.
- `services/` contains the production BLE service, secure PIN storage, and the Drift database/DAOs.
- Riverpod is the app's state-management and dependency-injection layer. An application bootstrap loads local teacher/student profiles and the last role before GoRouter selects the initial route. Teacher authentication state remains separate and PIN-protected.
- SQLite/Drift is the local source of truth. Students, devices, offerings, enrollments, attendance sessions, and records persist locally. Schema migrations preserve existing data; offering identity is teacher + section + subject.
- Production startup injects `ProductionBleService`. BLE mocks are confined to `test/`.

## BLE behavior and Android permissions

The student device advertises its registered service UUID. The teacher scans advertisements and compares the advertised service UUID against locally registered device UUIDs; device names, list order, and platform peripheral addresses do not determine attendance. Duplicate advertisements update the same student's detection record. Unknown or non-enrolled devices are ignored as attendance.

Android declares legacy Bluetooth permissions through API 30, Android 12+ scan/connect/advertise permissions, connected-device foreground-service permissions, notification permission, camera access for QR scanning, and an optional BLE hardware feature. Runtime advertising permission and notification permission are requested after the student explicitly enables background attendance while the app is visible.

Background advertising is owned by an Android foreground service and its status is reported from native service/advertiser state. On one Android 13 student phone, enabling attendance showed the foreground service, ongoing notification, and active Android BLE advertiser; the advertiser remained active after returning to the launcher. Screen-lock and ordinary app-restart recovery have not been verified. Android Force Stop, Bluetooth shutdown, permission revocation, and some manufacturer battery/task controls can stop advertising. Teacher scanning ends on timeout, explicit stop, or Bluetooth/permission failure; review state is persisted.

## Reports

Session, class attendance, student attendance, and class roster reports use typed data loaded from local repositories. Each supported report can be generated as PDF or CSV from the relevant session, class, or student screen. Save uses the Android native document picker; share attaches the generated file to the Android share sheet. Cancellation is not reported as success. Automated tests verify generated PDF/CSV bytes and the export coordination path; native Android picker and share-sheet interaction still needs device verification.

PDF output is intended for printing and paginates attendance tables. CSV is UTF-8 with a byte-order mark and RFC-style quoting for spreadsheet compatibility. Internal database IDs and BLE UUIDs are omitted from reports.

## Run and test

Install Flutter/Dart for the SDK constraint in `pubspec.yaml`, then run:

```sh
flutter pub get
dart run build_runner build
flutter run
```

Run static analysis, automated tests, and an Android debug build with:

```sh
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

## Two-phone BLE verification

The required two-phone BLE test could not be performed: one physical Android 13 phone is connected, and a second teacher phone is not available in this environment. Student background advertising was partially verified on the connected phone while the app was minimized, but screen-lock, restart recovery, and teacher-side discovery/matching remain unverified. Use two Android phones for the full procedure below; a successful build does not verify radio behavior.

**Phone A — student**

1. Create the student profile, register Phone A, and record its BLE Service UUID as UUID A.
2. From Phone B, create several offerings and share a subjects QR. Scan it on Phone A and confirm selected subjects.
3. Enable Background Attendance while ClassAttend is visible. Grant Bluetooth advertise and notification permissions. Wait until the screen reports Active and the ongoing notification appears.
4. Lock the screen and minimize the app. Confirm the notification remains and the student status remains active. Force Stop is outside the supported lifecycle.
5. Restart the app at least three times. Open Device and verify its stored BLE Service UUID is still exactly UUID A; confirm the background status reflects the native service.

**Phone B — teacher**

1. Create a teacher PIN and matching subject offerings. For the test student, manually add the same student number and UUID A to each intended teacher roster; the offline QR does not transfer student identity to Phone B.
2. Grant scan/connect permissions and enable Bluetooth. At a scheduled time, select one offering and start attendance while Phone A's background service is active.
3. Confirm only the matched enrolled student changes to Present and a detection time is recorded. Repeated advertisements must not create duplicate students/records. An unregistered phone and a registered student outside this offering must not be marked present.
4. Select another subject for which the student is enrolled and scan again. Confirm the same UUID A is accepted for that offering. Select an offering with no enrollment and confirm it is ignored.
5. Stop the scan early or let it time out. Confirm undetected students remain Not Detected during review, manual status changes persist, and save confirmation turns remaining Not Detected into Absent.

Also exercise Bluetooth disabled before and during scanning, denied and revoked permissions, beacon stopped, unknown nearby devices, early scan stop, scan timeout, leaving the scanner screen, app restart during review, Bluetooth being turned off during student advertising, and Android Force Stop. Verify service recovery and native save/share on target devices.
## Known limitations

- Student foreground-service advertising, its ongoing notification, and advertiser persistence while the app is minimized were runtime-observed on one Android 13 phone. Screen-lock and restart recovery remain unverified. Teacher-side discovery and matching were not runtime-tested because a second physical Android phone is unavailable.
- Subject QR imports offerings to the student's local database only. The teacher must also add the student identity and permanent UUID to their local rosters; there is no cloud sync or remote revocation.
- Android Force Stop, Bluetooth being turned off, permission revocation, and manufacturer battery/task-killer behavior can stop background advertising.
- The Android application ID is retained for existing local installations. Release builds still require a production signing configuration before distribution.
