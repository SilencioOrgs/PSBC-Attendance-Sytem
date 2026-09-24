/// Canonical UUID validation shared by student and teacher device flows.
String? normalizeBleIdentity(String value) {
  final normalized = value.trim().toLowerCase();
  if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
      .hasMatch(normalized)) {
    return null;
  }
  return normalized;
}
