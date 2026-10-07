import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/game_catalog.dart';
import '../models/training_result.dart';

abstract interface class StoreBackend {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesBackend implements StoreBackend {
  static const _channel = MethodChannel('lightfuture/storage');
  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');
  @override
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', {'data': value});
}

class MemoryBackend implements StoreBackend {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String data) async => value = data;
}

class LocalStore extends ChangeNotifier {
  LocalStore(this.backend);
  final StoreBackend backend;
  final List<TrainingResult> _recent = [];
  final Map<String, TrainingResult> _best = {};
  final Map<GameId, int> _levels = {};
  bool sound = true, vibration = true, ready = false, saveFailed = false;
  Future<void> _writes = Future.value();
  bool _closed = false;
  List<TrainingResult> get recent => List.unmodifiable(_recent);
  List<TrainingResult> get bestResults => List.unmodifiable(_best.values);
  int lastLevel(GameId id) => _levels[id] ?? 1;
  TrainingResult? best(GameId id, int level) => _best['${id.name}:$level:1'];
  Future<void> get saved => _writes;

  Future<void> load() async {
    if (ready) return;
    try {
      final raw = await backend.read();
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['schemaVersion'] != 1) {
          throw const FormatException('Unsupported version');
        }
        sound = data['sound'] as bool? ?? true;
        vibration = data['vibration'] as bool? ?? true;
        for (final item in data['recent'] as List? ?? const []) {
          try {
            _recent.add(
              TrainingResult.fromJson(Map<String, dynamic>.from(item as Map)),
            );
          } catch (_) {
            /* Discard a broken record while retaining other records. */
          }
          if (_recent.length == 20) break;
        }
        for (final item in data['best'] as List? ?? const []) {
          try {
            final result = TrainingResult.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
            if (result.betterThan(_best[result.key])) {
              _best[result.key] = result;
            }
          } catch (_) {
            /* Isolate individual malformed records. */
          }
        }
        for (final entry in (data['levels'] as Map? ?? const {}).entries) {
          try {
            final id = GameId.values.byName(entry.key as String);
            final level = entry.value as int;
            if (level >= 1 && level <= 10) _levels[id] = level;
          } catch (_) {
            /* Unknown game IDs from a newer version are ignored. */
          }
        }
      }
    } catch (_) {
      saveFailed = true;
    }
    ready = true;
    if (!_closed) notifyListeners();
  }

  bool record(TrainingResult result) {
    final isBest = result.betterThan(_best[result.key]);
    if (isBest) _best[result.key] = result;
    _recent.insert(0, result);
    if (_recent.length > 20) _recent.removeRange(20, _recent.length);
    _levels[result.game] = result.level;
    _save();
    return isBest;
  }

  void selectLevel(GameId game, int level) {
    if (level < 1 || level > 10) return;
    _levels[game] = level;
    _save();
  }

  void settings({bool? soundOn, bool? vibrationOn}) {
    sound = soundOn ?? sound;
    vibration = vibrationOn ?? vibration;
    _save();
  }

  void clearRecords() {
    _recent.clear();
    _best.clear();
    _levels.clear();
    _save();
  }

  void _save() {
    final snapshot = jsonEncode({
      'schemaVersion': 1,
      'sound': sound,
      'vibration': vibration,
      'recent': _recent.map((r) => r.toJson()).toList(),
      'best': _best.values.map((r) => r.toJson()).toList(),
      'levels': _levels.map((id, level) => MapEntry(id.name, level)),
    });
    _writes = _writes.then((_) async {
      try {
        await backend.write(snapshot);
        saveFailed = false;
      } catch (_) {
        saveFailed = true;
      }
      if (!_closed) notifyListeners();
    });
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
