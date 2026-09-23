String normalizeTeacherPin(String raw) => raw.trim();

bool isValidTeacherPin(String raw) =>
    RegExp(r'^\d{4,6}$').hasMatch(normalizeTeacherPin(raw));
