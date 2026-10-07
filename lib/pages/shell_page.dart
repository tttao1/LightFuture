import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/game_catalog.dart';
import '../models/training_result.dart';
import '../storage/local_store.dart';
import '../widgets/common.dart';
import 'game_intro_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.store});
  final LocalStore store;
  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _page = 0;
  Ability? _filter;
  void _open(GameDefinition game) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GameIntroPage(game: game, store: widget.store),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    body: ContentFrame(
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => IndexedStack(
          index: _page,
          children: [
            Offstage(
              offstage: _page != 0,
              child: _Home(
                store: widget.store,
                open: _open,
                category: (ability) => setState(() {
                  _filter = ability;
                  _page = 1;
                }),
              ),
            ),
            Offstage(
              offstage: _page != 1,
              child: _Library(
                open: _open,
                filter: _filter,
                changed: (filter) => setState(() => _filter = filter),
              ),
            ),
            Offstage(
              offstage: _page != 2,
              child: _LocalProfile(store: widget.store),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _page,
      onDestinationSelected: (index) {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _page = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: '训练',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: '我的',
        ),
      ],
    ),
  );
}

class _Home extends StatelessWidget {
  const _Home({
    required this.store,
    required this.open,
    required this.category,
  });
  final LocalStore store;
  final ValueChanged<GameDefinition> open;
  final ValueChanged<Ability> category;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(), games = availableGames;
    final recommended =
        games[(now.year * 372 + now.month * 31 + now.day) % games.length];
    final recentIds = store.recent.map((r) => r.game).toSet().take(4).toList();
    final quick = store.recent.isEmpty
        ? gameById(GameId.numberMemory)
        : gameById(store.recent.first.game);
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            const Icon(Icons.bubble_chart_rounded, color: primary, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '脑力训练',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const TrainingBadge('完全离线', color: success),
          ],
        ),
        const SizedBox(height: 26),
        Text('给大脑一点新挑战', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          '${games.length} 个训练项目 · 6 类能力 · 10 个等级',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 22),
        Material(
          color: const Color(0xFF293A71),
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            key: const Key('today-recommendation'),
            borderRadius: BorderRadius.circular(26),
            onTap: () => open(recommended),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日推荐',
                    style: TextStyle(
                      color: Color(0xFFD5D0FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Icon(
                    gameIcon(recommended.id),
                    size: 52,
                    color: const Color(0xFFC8C7FF),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    recommended.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommended.summary,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Text(
                        '开始挑战',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('quick-start'),
          onPressed: () => open(quick),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('快速开始 · ${quick.name}'),
        ),
        const SizedBox(height: 26),
        Text('训练分类', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) => GridView.count(
            crossAxisCount: box.maxWidth >= 520 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: MediaQuery.textScalerOf(context).scale(1) > 1.2
                ? 0.88
                : 1.05,
            children: Ability.values
                .map(
                  (ability) => Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      key: Key('category-${ability.name}'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => category(ability),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              categoryIcon(ability),
                              color: categoryColor(ability),
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ability.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${games.where((g) => g.ability == ability).length} 个项目',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (recentIds.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text('最近玩过', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...recentIds.map((id) => _GameCard(game: gameById(id), open: open)),
        ],
        const SizedBox(height: 16),
        const Text(
          '无需登录 · 所有题目和记录都在本机',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _Library extends StatefulWidget {
  const _Library({
    required this.open,
    required this.filter,
    required this.changed,
  });
  final ValueChanged<GameDefinition> open;
  final Ability? filter;
  final ValueChanged<Ability?> changed;
  @override
  State<_Library> createState() => _LibraryState();
}

class _LibraryState extends State<_Library> {
  String _search = '';
  @override
  Widget build(BuildContext context) {
    final games = availableGames
        .where(
          (g) =>
              (widget.filter == null || g.ability == widget.filter) &&
              (g.name.contains(_search) || g.summary.contains(_search)),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text('找到你的训练', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('按能力选择，或搜索喜欢的玩法。', style: TextStyle(color: muted)),
        const SizedBox(height: 20),
        TextField(
          key: const Key('game-search'),
          onChanged: (value) => setState(() => _search = value.trim()),
          decoration: InputDecoration(
            hintText: '搜索训练名称',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('全部'),
              selected: widget.filter == null,
              onSelected: (_) => widget.changed(null),
            ),
            ...Ability.values.map(
              (a) => ChoiceChip(
                label: Text(a.label),
                selected: a == widget.filter,
                onSelected: (_) => widget.changed(a),
                selectedColor: categoryColor(a).withAlpha(30),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('共 ${games.length} 个训练', style: const TextStyle(color: muted)),
        const SizedBox(height: 12),
        if (games.isEmpty) const Surface(child: Text('没有匹配的训练，换个关键词试试。')),
        ...games.map((game) => _GameCard(game: game, open: widget.open)),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.open});
  final GameDefinition game;
  final ValueChanged<GameDefinition> open;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('game-${game.id.name}'),
        onTap: () => open(game),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor(game.ability).withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  gameIcon(game.id),
                  color: categoryColor(game.ability),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.summary,
                      style: const TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Level 1–10',
                      style: TextStyle(color: primary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LocalProfile extends StatelessWidget {
  const _LocalProfile({required this.store});
  final LocalStore store;
  Future<void> _clear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除本机训练记录？'),
        content: const Text('最佳成绩和最近记录会清空，音效与振动设置会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    if (confirmed == true) store.clearRecords();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(22),
    children: [
      Text('我的训练', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text('成绩只保存在这台手机上。', style: TextStyle(color: muted)),
      const SizedBox(height: 22),
      Surface(
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          spacing: 20,
          runSpacing: 16,
          children: [
            Metric('${store.recent.length}', '最近记录'),
            Metric('${store.bestResults.length}', '等级纪录'),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Surface(
        padding: 4,
        child: Column(
          children: [
            SwitchListTile(
              key: const Key('sound-setting'),
              title: const Text('训练音效'),
              subtitle: const Text('正确与错误的本地提示音'),
              value: store.sound,
              onChanged: (value) => store.settings(soundOn: value),
            ),
            SwitchListTile(
              key: const Key('vibration-setting'),
              title: const Text('触觉反馈'),
              value: store.vibration,
              onChanged: (value) => store.settings(vibrationOn: value),
            ),
          ],
        ),
      ),
      if (store.saveFailed) ...[
        const SizedBox(height: 12),
        const Text(
          '本机记录暂未保存成功，当前成绩仍可查看。',
          style: TextStyle(color: Colors.deepOrange),
        ),
      ],
      const SizedBox(height: 24),
      Text('最佳成绩', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (store.bestResults.isEmpty)
        const Surface(child: Text('完成一次训练后，这里会出现同等级最佳成绩。')),
      ...store.bestResults.map((result) => _RecordCard(result)),
      const SizedBox(height: 22),
      Text('最近 20 次训练', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (store.recent.isEmpty)
        const Surface(child: Text('还没有训练记录，从首页开始第一项挑战吧。')),
      ...store.recent.map((result) => _RecordCard(result)),
      const SizedBox(height: 12),
      TextButton.icon(
        key: const Key('clear-records'),
        onPressed: () => _clear(context),
        icon: const Icon(Icons.delete_outline_rounded),
        label: const Text('清除本机训练记录'),
      ),
      const SizedBox(height: 16),
      const Text(
        '脑力训练 1.0.0\n离线运行 · 原创规则与图形\n保持专注，记录每一次进步。',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 12, height: 1.8),
      ),
    ],
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard(this.result);
  final TrainingResult result;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Surface(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${gameById(result.game).name} · Level ${result.level}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            '${result.score} 分 · ${(result.accuracy * 100).round()}% · ${formatSeconds(result.seconds)}',
          ),
          const SizedBox(height: 5),
          Text(
            '${result.date.month}/${result.date.day} ${result.date.hour.toString().padLeft(2, '0')}:${result.date.minute.toString().padLeft(2, '0')}'
            '${result.completed ? '' : ' · 未完成'}',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
