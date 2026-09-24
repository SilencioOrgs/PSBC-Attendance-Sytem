# ClassAttend Paete

ClassAttend is an offline-first Flutter app for teachers to manage class rosters, take BLE-assisted attendance, review manual changes, retain attendance history, and export PDF or CSV reports. Student setup creates a local student profile and a BLE attendance identity that can be shared with the teacher. There is no backend or cloud account.

## Main flows

### Teacher

1. On first launch, create a teacher PIN. Later launches require the PIN to unlock the teacher area.
2. Create a class, then add its students.
3. Open a student in the roster and register that student's BLE device code. Use **Replace device** when a student changes phones; removing or replacing a registration revokes the old identity immediately.
4. Start attendance. The app scans for registered BLE service UUIDs and only accepts a match when the device owner is enrolled in the selected class.
5. Review results. Detected students are Present; the rest remain Not Detected until the teacher saves. Manual Present and Manual Absent changes are retained as manual statuses.
6. Confirm the save rule to convert remaining Not Detected students to Absent. The session and its records are committed together. History links to session details and exports.

### Student device registration

1. Choose student setup and enter the student's profile and section code.
2. Register the device to generate and persist a 128-bit BLE service UUID.
3. Share the displayed device code with the teacher through an in-person or otherwise trusted channel. On the teacher's device, open the matching student in the class roster and enter the code. This association works offline and does not require a cloud service.
4. Start the attendance beacon when asked. Keep the app open in the foreground and the device unlocked while advertising is needed. The UI reports the live advertising state separately from registration.

The student profile can be set up before the teacher has created a matching local class. The section code is stored on the student device; it does not silently create teacher, class, or enrollment records there.

## Offline architecture

- `core/` contains routing, theme, shared utilities, and provider setup.
- `features/` contains feature screens, providers/controllers, and Drift-backed repositories.
- `domain/` contains shared domain models and repository contracts.
- `services/` contains the production BLE service, secure PIN storage, and the Drift database/DAOs.
- Riverpod is the app's state-management and dependency-injection layer. GoRouter applies the initialized teacher session to route guards.
- SQLite/Drift is the local source of truth. The database is not cleared on logout. Schema migrations preserve existing class and attendance data.
- Production startup injects `ProductionBleService`. BLE mocks are confined to `test/`.

## BLE behavior and Android permissions

The student device advertises its registered service UUID. The teacher scans advertisements and compares the advertised service UUID against locally registered device UUIDs; device names, list order, and platform peripheral addresses do not determine attendance. Duplicate advertisements update the same student's detection record. Unknown or non-enrolled devices are ignored as attendance.

Android declares legacy Bluetooth permissions through API 30, Android 12+ scan/connect/advertise permissions, and an optional BLE hardware feature. Runtime authorization is requested by the BLE platform manager. If Bluetooth is turned off, permission is denied/revoked, or the device lacks BLE support, scanning/advertising reports the corresponding unavailable state.

Advertising is stopped when the app enters the paused, hidden, or detached lifecycle state. Background and lock-screen advertising is not claimed by this implementation. Return to the student device screen and start the beacon again after foregrounding the app. A teacher scan ends on timeout, explicit stop, or a Bluetooth/permission state failure. Review state is persisted, so a scan can be reviewed or resumed after reopening the app.

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

BLE runtime testing could not be performed in the current development environment because no physical Android phones or Android emulator were available. Use two Android phones for the following manual test; do not infer radio behavior from a successful build.

**Phone A — student**

1. Install the app, choose student setup, create a profile and section code, register this phone, and copy its device code.
2. Confirm the device screen says Registered, grant advertise permission, and start the beacon. Confirm it says Beacon Active.
3. Repeat with the app backgrounded/phone locked: the app should report the beacon stopped after lifecycle transition. Foreground and unlock Phone A, then start the beacon again.

**Phone B — teacher**

1. Create a teacher PIN, class, and matching student roster record. Open that student and enter Phone A's device code.
2. Grant scan/connect permissions and enable Bluetooth. Start attendance with both phones nearby and Phone A's beacon active.
3. Confirm only the matched enrolled student changes to Present and a detection time is recorded. Repeated advertisements must not create duplicate students/records. An unregistered phone and a registered student outside this class must not be marked present.
4. Stop the scan early or let it time out. Confirm undetected students remain Not Detected during review, manual status changes persist, and save confirmation turns remaining Not Detected into Absent.
5. Open session history/details, export PDF and CSV, save through the native picker, and share each format. Reopen the app and confirm the finalized session and report data remain.

Also exercise Bluetooth disabled before and during scanning, denied and revoked permissions, beacon stopped, unknown nearby devices, early scan stop, scan timeout, leaving the scanner screen, app restart during review, and active-scan logout. For logout during an active session, the app should stop scanning and require review/cancel handling rather than silently finalizing or deleting data. Verify the document picker returns a saved location and that the Android share sheet receives an attached file.

## Known limitations

- Physical-device BLE discovery/advertising and native Android save/share have not been runtime-tested in this environment.
- Student and teacher devices exchange the UUID manually; enrollment and device association are local and offline, with no QR import, cloud sync, or remote revocation.
- Advertising is foreground-only and stops on app lifecycle backgrounding. Keep the student app visible and the phone unlocked during attendance.
- The Android application ID is retained for existing local installations. Release builds still require a production signing configuration before distribution.
