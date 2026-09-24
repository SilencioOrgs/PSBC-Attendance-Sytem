import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';

final appSettingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSettings(),
);

final settingsControllerProvider = NotifierProvider<SettingsController, bool>(
  SettingsController.new,
);

class SettingsController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> save(AppSettings settings) async {
    state = true;
    try {
      await ref.read(settingsRepositoryProvider).saveSettings(settings);
      ref.invalidate(appSettingsProvider);
    } finally {
      state = false;
    }
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    state = true;
    try {
      await ref
          .read(teacherAuthServiceProvider)
          .changePin(currentPin: currentPin, newPin: newPin);
    } finally {
      state = false;
    }
  }

  Future<void> logout() async {
    state = true;
    try {
      await ref.read(teacherAuthServiceProvider).logout();
    } finally {
      state = false;
    }
  }
}
