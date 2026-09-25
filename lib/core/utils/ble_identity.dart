import 'package:uuid/uuid.dart';

/// Canonical UUID validation shared by student and teacher device flows.
String? normalizeBleIdentity(String value) {
  final normalized = value.trim().toLowerCase();
  if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
      .hasMatch(normalized)) {
    return null;
  }
  return normalized;
}

/// Creates a BLE attendance identity for a newly registered physical device.
///
/// Keep this distinct from [newDatabaseId], which identifies local DB rows.
String newBleServiceUuid() => const Uuid().v4();
