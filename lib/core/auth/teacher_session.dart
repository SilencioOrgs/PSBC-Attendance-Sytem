import 'package:flutter/foundation.dart';

/// Process-local unlock state. It intentionally resets after an app restart.
final teacherSessionUnlocked = ValueNotifier<bool>(false);
