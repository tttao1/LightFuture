import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/app.dart';
import 'package:light_future_demo/games/shared/challenge.dart';
import 'package:light_future_demo/games/shared/session_controller.dart';
import 'package:light_future_demo/models/game_catalog.dart';
import 'package:light_future_demo/pages/training_page.dart';
import 'package:light_future_demo/storage/local_store.dart';

Future<LocalStore> testStore() async {
  final store = LocalStore(MemoryBackend());
  await store.load();
  store.settings(soundOn: false, vibrationOn: false);
  await store.saved;
  return store;
}

Future<void> visibleTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> openReaction(WidgetTester tester, LocalStore store) async {
  await tester.pumpWidget(BrainTrainingApp(store: store));
  await tester.pumpAndSettle();
  await tester.tap(find.text('训练'));
  await tester.pumpAndSettle();
  await visibleTap(tester, find.byKey(const Key('game-reactionSpeed')));
  await tester.pumpAndSettle();
  await visibleTap(tester, find.byKey(const Key('start-training')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'reaction still works and foregrounding shows a resumable pause',
    (tester) async {
      final store = await testStore();
      await openReaction(tester, store);
      expect(find.text('第 1 / 5 轮'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('训练已暂停'), findsOneWidget);
      await visibleTap(tester, find.byKey(const Key('continue-training')));
      expect(find.text('准备开始'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      store.dispose();
    },
  );

  testWidgets('five reaction rounds persist a result and can be replayed', (
    tester,
  ) async {
    final store = await testStore();
    await openReaction(tester, store);
    await tester.pump(const Duration(seconds: 8));
    for (var i = 0; i < 5; i++) {
      expect(find.text('立即点击'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('reaction-pad')));
      await tester.tap(find.byKey(const Key('reaction-pad')));
      await tester.pump(const Duration(milliseconds: 1100));
      if (i < 4) await tester.pump(const Duration(seconds: 5));
    }
    await tester.pumpAndSettle();
    expect(find.text('本次成绩'), findsOneWidget);
    expect(store.recent.single.game, GameId.reactionSpeed);
    expect(store.recent.single.correct, 5);
    await store.saved;
    await visibleTap(tester, find.byKey(const Key('play-again')));
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 5 轮'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    store.dispose();
  });

  testWidgets('number memory hides the answer and accepts all five rounds', (
    tester,
  ) async {
    final store = await testStore();
    final game = gameById(GameId.numberMemory);
    final controller = SessionController(
      game,
      1,
      nowMicros: () => tester.binding.clock.now().microsecondsSinceEpoch,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TrainingPage(
          game: game,
          level: 1,
          store: store,
          controller: controller,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3100));
    for (var round = 0; round < 5; round++) {
      final challenge = controller.challenge! as NumberChallenge;
      expect(find.byKey(const Key('memory-preview')), findsOneWidget);
      await tester.pump(challenge.preview + const Duration(milliseconds: 150));
      expect(find.byKey(const Key('memory-preview')), findsNothing);
      for (final digit in challenge.answer.split('')) {
        await visibleTap(tester, find.byKey(Key('digit-$digit')));
      }
      await visibleTap(tester, find.byKey(const Key('submit-answer')));
      await tester.pump(const Duration(milliseconds: 1100));
    }
    await tester.pumpAndSettle();
    expect(find.text('本次成绩'), findsOneWidget);
    expect(store.recent.single.correct, 5);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('Schulte requires the sequence and records incorrect taps', (
    tester,
  ) async {
    final store = await testStore();
    final game = gameById(GameId.schulte);
    final controller = SessionController(
      game,
      1,
      nowMicros: () => tester.binding.clock.now().microsecondsSinceEpoch,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TrainingPage(
          game: game,
          level: 1,
          store: store,
          controller: controller,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 3100));
    await visibleTap(tester, find.byKey(const Key('schulte-2')));
    expect(find.text('下一目标：1'), findsOneWidget);
    for (var number = 1; number <= 9; number++) {
      await visibleTap(tester, find.byKey(Key('schulte-$number')));
    }
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(store.recent.single.correct, 9);
    expect(store.recent.single.attempts, 10);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('all three tabs work on a small screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await testStore();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: BrainTrainingApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('训练'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('训练音效'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}
