import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/models/game_catalog.dart';
import 'package:light_future_demo/models/training_result.dart';
import 'package:light_future_demo/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('lightfuture/storage');
  test(
    'native JSON storage protocol writes and reopens Unicode records',
    () async {
      String? saved;
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            methods.add(call.method);
            if (call.method == 'read') return saved;
            if (call.method == 'write') {
              saved = (call.arguments as Map)['data'] as String;
              return null;
            }
            throw MissingPluginException();
          });
      try {
        final first = LocalStore(PreferencesBackend());
        await first.load();
        first.record(
          TrainingResult(
            game: GameId.schulte,
            level: 1,
            score: 800,
            correct: 9,
            attempts: 9,
            seconds: 15,
            completed: true,
            metrics: const {'反馈': '全部完成'},
          ),
        );
        await first.saved;
        final second = LocalStore(PreferencesBackend());
        await second.load();
        expect(second.recent.single.metrics['反馈'], '全部完成');
        expect(methods, ['read', 'write', 'read']);
        first.dispose();
        second.dispose();
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
  test(
    'native write failure retains the visible result and reports failure',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'read') return null;
            throw PlatformException(code: 'save_failed');
          });
      try {
        final store = LocalStore(PreferencesBackend());
        await store.load();
        store.record(
          TrainingResult(
            game: GameId.numberMemory,
            level: 1,
            score: 600,
            correct: 3,
            attempts: 5,
            seconds: 10,
            completed: true,
          ),
        );
        await store.saved;
        expect(store.recent.length, 1);
        expect(store.saveFailed, isTrue);
        store.dispose();
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
}
