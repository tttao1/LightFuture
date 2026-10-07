import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_future_demo/games/shared/challenge.dart';
import 'package:light_future_demo/games/shared/challenge_factory.dart';
import 'package:light_future_demo/games/spatial/spatial_rules.dart';
import 'package:light_future_demo/models/game_catalog.dart';

void main() {
  test('catalog contains 24 unique games with four in each ability', () {
    expect(availableGames.length, 24);
    expect(availableGames.map((g) => g.id).toSet(), GameId.values.toSet());
    for (final ability in Ability.values) {
      expect(availableGames.where((g) => g.ability == ability).length, 4);
    }
  });
  test('known maze routes and disconnected targets have correct distances', () {
    expect(shortestPath(4, {})!.length - 1, 6);
    expect(shortestPath(4, {1, 4}), isNull);
    expect(shortestPath(3, {1, 4})!.length - 1, 4);
    expect(neighbors(3, 4), [2, 7]);
  });
  test('every generated maze is connected with a valid shortest witness', () {
    for (var level = 1; level <= 10; level++) {
      for (var seed = 0; seed < 40; seed++) {
        final question =
            createChallenge(GameId.path, level, Random(seed)) as PathChallenge;
        final witness = shortestPath(question.size, question.obstacles)!;
        expect(witness.first, 0);
        expect(witness.last, question.size * question.size - 1);
        expect(witness.length - 1, question.shortest);
        expect(witness.every((p) => !question.obstacles.contains(p)), isTrue);
        for (var i = 1; i < witness.length; i++) {
          expect(
            neighbors(witness[i - 1], question.size),
            contains(witness[i]),
          );
        }
      }
    }
  });
  test('every block puzzle covers the board once with connected pieces', () {
    for (var level = 1; level <= 10; level++) {
      for (var seed = 0; seed < 40; seed++) {
        final question =
            createChallenge(GameId.blocks, level, Random(seed))
                as BlockChallenge;
        final cells = question.solutions.expand((piece) => piece).toList();
        expect(cells.length, question.size * question.size);
        expect(cells.toSet().length, cells.length);
        expect(
          cells.every(
            (p) =>
                p.x >= 0 &&
                p.y >= 0 &&
                p.x < question.size &&
                p.y < question.size,
          ),
          isTrue,
        );
        for (var i = 0; i < question.pieces.length; i++) {
          expect(cellCode(question.pieces[i]), cellCode(question.solutions[i]));
          final piece = question.solutions[i]
              .map((p) => p.y * question.size + p.x)
              .toSet();
          final visited = <int>{piece.first}, queue = <int>[piece.first];
          while (queue.isNotEmpty) {
            for (final next in neighbors(queue.removeLast(), question.size)) {
              if (piece.contains(next) && visited.add(next)) queue.add(next);
            }
          }
          expect(visited, piece);
        }
      }
    }
  });
  test(
    'mirrored rotation distractors cannot be confused with a valid rotation',
    () {
      for (final level in [1, 5, 10]) {
        final question =
            createChallenge(GameId.rotation, level, Random(4))
                as ChoiceChallenge;
        final cells = question.reference!.cells!;
        final reflected = cells.map((p) => Cell(-p.x, p.y)).toList();
        for (var turn = 0; turn < 4; turn++) {
          expect(
            cellCode(rotateCells(cells, turn)),
            isNot(cellCode(reflected)),
          );
        }
        expect(
          question.options[question.correctIndex].visual!.mirrored,
          isFalse,
        );
        for (var i = 0; i < question.options.length; i++) {
          if (i != question.correctIndex) {
            expect(question.options[i].visual!.mirrored, isTrue);
          }
        }
      }
    },
  );
}
