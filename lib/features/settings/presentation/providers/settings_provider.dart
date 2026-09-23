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
    await ref.read(settingsRepositoryProvider).saveSettings(settings);
    state = !state;
    ref.invalidate(appSettingsProvider);
  }
}
