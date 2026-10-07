import 'package:flutter/services.dart';

import '../storage/local_store.dart';

class TrainingFeedback {
  static const channel = MethodChannel('lightfuture/feedback');
  static void play(LocalStore store, {required bool correct}) {
    if (store.vibration) {
      if (correct) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    if (store.sound) _sound(correct);
  }

  static Future<void> _sound(bool correct) async {
    try {
      await channel.invokeMethod<void>('play', {'correct': correct});
    } on MissingPluginException {
      /* Headless and non-Android tests have no audio host. */
    } on PlatformException {
      /* Audio availability must not interrupt training. */
    }
  }
}
