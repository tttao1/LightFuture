import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/app.dart';

void main() {
  testWidgets('home starts the game and backgrounding pauses it', (
    tester,
  ) async {
    await tester.pumpWidget(const BrainTrainingDemo());
    expect(find.text('脑力训练'), findsOneWidget);
    expect(find.text('反应速度'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-training')),
      200,
    );
    await tester.tap(find.byKey(const Key('start-training')));
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 5 轮'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // A paused app does not paint frames. Assert its paused UI after returning
    // to the foreground, matching what a phone user actually sees.
    await tester.pump(const Duration(seconds: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('训练已暂停'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('continue-training')),
      150,
    );
    await tester.tap(find.byKey(const Key('continue-training')));
    await tester.pump();
    expect(find.text('准备开始'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('five successful rounds show results and can be replayed', (
    tester,
  ) async {
    await tester.pumpWidget(const BrainTrainingDemo());
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-training')),
      200,
    );
    await tester.tap(find.byKey(const Key('start-training')));
    await tester.pumpAndSettle();
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
    expect(find.text('100%'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('play-again')), 200);
    await tester.tap(find.byKey(const Key('play-again')));
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 5 轮'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screen and larger text have no layout exceptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: const BrainTrainingDemo(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-training')),
      200,
    );
    await tester.tap(find.byKey(const Key('start-training')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
  });
}
