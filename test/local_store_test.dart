import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/models/game_catalog.dart';
import 'package:light_future_demo/models/training_result.dart';
import 'package:light_future_demo/storage/local_store.dart';

TrainingResult record(int score, {int level = 1, bool completed = true}) =>
    TrainingResult(
      game: GameId.numberMemory,
      level: level,
      score: score,
      correct: 4,
      attempts: 5,
      seconds: 12,
      completed: completed,
      date: DateTime(2026, 10, 7),
    );

void main() {
  test(
    'records, separate difficulty bests and settings survive reload',
    () async {
      final backend = MemoryBackend(), store = LocalStore(MemoryBackend());
      final first = LocalStore(backend);
      await first.load();
      first.settings(soundOn: false, vibrationOn: false);
      expect(first.record(record(800)), isTrue);
      expect(first.record(record(700)), isFalse);
      expect(first.record(record(600, level: 2)), isTrue);
      first.selectLevel(GameId.numberMemory, 7);
      await first.saved;
      final second = LocalStore(backend);
      await second.load();
      expect(second.recent.length, 3);
      expect(second.best(GameId.numberMemory, 1)!.score, 800);
      expect(second.best(GameId.numberMemory, 2)!.score, 600);
      expect(second.lastLevel(GameId.numberMemory), 7);
      expect(second.sound, isFalse);
      expect(second.vibration, isFalse);
      first.dispose();
      second.dispose();
      store.dispose();
    },
  );

  test(
    'only latest twenty records are retained and incomplete attempts are not bests',
    () async {
      final backend = MemoryBackend(), store = LocalStore(MemoryBackend());
      await store.load();
      expect(store.record(record(999, completed: false)), isFalse);
      for (var i = 0; i < 25; i++) {
        store.record(record(i));
      }
      await store.saved;
      expect(store.recent.length, 20);
      expect(store.recent.first.score, 24);
      expect(store.recent.last.score, 5);
      backend.value = (store.backend as MemoryBackend).value;
      final reloaded = LocalStore(backend);
      await reloaded.load();
      expect(reloaded.recent.length, 20);
      expect(reloaded.best(GameId.numberMemory, 1)!.score, 24);
      store.dispose();
      reloaded.dispose();
    },
  );

  test('one malformed record does not discard good records', () async {
    final backend = MemoryBackend();
    backend.value = jsonEncode({
      'schemaVersion': 1,
      'recent': [
        {'game': 'unknown'},
        record(700).toJson(),
      ],
      'best': [],
      'levels': {},
    });
    final store = LocalStore(backend);
    await store.load();
    expect(store.recent.single.score, 700);
    store.dispose();
  });

  test(
    'clearing records preserves feedback settings after reopening',
    () async {
      final backend = MemoryBackend(), first = LocalStore(MemoryBackend());
      await first.load();
      first.settings(soundOn: false);
      first.record(record(700));
      first.clearRecords();
      await first.saved;
      backend.value = (first.backend as MemoryBackend).value;
      final second = LocalStore(backend);
      await second.load();
      expect(second.recent, isEmpty);
      expect(second.bestResults, isEmpty);
      expect(second.sound, isFalse);
      first.dispose();
      second.dispose();
    },
  );
}
