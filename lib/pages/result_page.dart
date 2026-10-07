import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/game_catalog.dart';
import '../models/training_result.dart';
import '../storage/local_store.dart';
import '../widgets/common.dart';
import 'game_intro_page.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.result,
    required this.isBest,
    required this.store,
  });
  final TrainingResult result;
  final bool isBest;
  final LocalStore store;
  @override
  Widget build(BuildContext context) {
    final best = store.best(result.game, result.level);
    return Scaffold(
      appBar: AppBar(title: const Text('本次成绩')),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.emoji_events_rounded, size: 68, color: primary),
            const SizedBox(height: 16),
            Text(
              '训练完成',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(result.evaluation, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Surface(
              child: Column(
                children: [
                  const Text('本次得分', style: TextStyle(color: muted)),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: result.score.toDouble()),
                    duration: const Duration(milliseconds: 650),
                    builder: (context, value, child) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${value.round()}',
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    '满分 1000',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  if (isBest) ...[
                    const SizedBox(height: 14),
                    const TrainingBadge('同等级新纪录', color: success),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 26,
                    runSpacing: 18,
                    alignment: WrapAlignment.center,
                    children: [
                      Metric('${(result.accuracy * 100).round()}%', '正确率'),
                      Metric(formatSeconds(result.seconds), '用时'),
                      Metric('${result.level}', '难度等级'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${gameById(result.game).name} · 训练详情',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('正确 ${result.correct} / ${result.attempts} 次'),
                  const SizedBox(height: 8),
                  ...result.metrics.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${entry.key.replaceAll('毫秒', '时间')}：${entry.value}${entry.key.endsWith('毫秒') && entry.value != '—' ? ' ms' : ''}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    best == null
                        ? '最佳成绩：暂无已完成纪录'
                        : '该等级最佳：${best.score} 分 · ${formatSeconds(best.seconds)}',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            if (store.saveFailed) ...[
              const SizedBox(height: 12),
              const Text(
                '本机记录暂未保存成功。',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('play-again'),
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => trainingScreen(
                    gameById(result.game),
                    result.level,
                    store,
                  ),
                ),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('再练一次'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('back-home'),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
