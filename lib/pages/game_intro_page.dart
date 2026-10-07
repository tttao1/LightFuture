import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/game_catalog.dart';
import '../storage/local_store.dart';
import '../widgets/common.dart';
import 'reaction_page.dart';
import 'training_page.dart';

Widget trainingScreen(GameDefinition game, int level, LocalStore store) =>
    game.id == GameId.reactionSpeed
    ? ReactionTrainingPage(game: game, level: level, store: store)
    : TrainingPage(game: game, level: level, store: store);

class GameIntroPage extends StatefulWidget {
  const GameIntroPage({super.key, required this.game, required this.store});
  final GameDefinition game;
  final LocalStore store;
  @override
  State<GameIntroPage> createState() => _GameIntroPageState();
}

class _GameIntroPageState extends State<GameIntroPage> {
  late int _level;
  @override
  void initState() {
    super.initState();
    _level = widget.store.lastLevel(widget.game.id);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game, best = widget.store.best(widget.game.id, _level);
    return Scaffold(
      appBar: AppBar(title: Text(game.name)),
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              gameIcon(game.id),
              size: 68,
              color: categoryColor(game.ability),
            ),
            const SizedBox(height: 16),
            Text(
              game.summary,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('怎么玩', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(game.instructions),
                  const SizedBox(height: 12),
                  Text(
                    '每局 ${game.rounds == 1 ? '一个完整挑战' : '${game.rounds} 轮'} · 可随时暂停',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '选择难度',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TrainingBadge('Level $_level'),
                    ],
                  ),
                  Slider(
                    key: const Key('difficulty-slider'),
                    value: _level.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: 'Level $_level',
                    onChanged: (value) =>
                        setState(() => _level = value.round()),
                  ),
                  Text(
                    _level <= 3
                        ? '轻松热身，熟悉训练方式。'
                        : _level <= 6
                        ? '增加数量与干扰，保持专注。'
                        : '更复杂的题目和更紧凑的时间。',
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              best == null
                  ? '该等级还没有纪录'
                  : '该等级最佳：${best.score} 分 · ${formatSeconds(best.seconds)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('start-training'),
              onPressed: () {
                widget.store.selectLevel(game.id, _level);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => trainingScreen(game, _level, widget.store),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('开始训练'),
            ),
          ],
        ),
      ),
    );
  }
}
