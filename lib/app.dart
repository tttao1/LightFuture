import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/theme.dart';
import 'pages/shell_page.dart';
import 'storage/local_store.dart';

class BrainTrainingApp extends StatefulWidget {
  const BrainTrainingApp({super.key, this.store});
  final LocalStore? store;
  @override
  State<BrainTrainingApp> createState() => _BrainTrainingAppState();
}

class _BrainTrainingAppState extends State<BrainTrainingApp> {
  late final LocalStore _store;
  late final Future<void> _loaded;
  @override
  void initState() {
    super.initState();
    _store = widget.store ?? LocalStore(PreferencesBackend());
    _loaded = _store.load();
  }

  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '脑力训练',
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    debugShowCheckedModeBanner: false,
    theme: trainingTheme(),
    home: FutureBuilder<void>(
      future: _loaded,
      builder: (context, snapshot) =>
          snapshot.connectionState == ConnectionState.done
          ? ShellPage(store: _store)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
}
