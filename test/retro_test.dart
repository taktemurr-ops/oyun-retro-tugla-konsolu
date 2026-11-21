import 'package:flutter_test/flutter_test.dart';
import 'package:oyun_retro_tugla_konsolu/oyun_retro_tugla_konsolu.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';

void main() {
  final rules = RetroRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('bölümler dört oyun arasında döner', () {
    final games = [for (var lv = 1; lv <= 4; lv++) rules.build(planner.spec(lv)).puzzle.game];
    expect(games.toSet().length, 4);
  });

  test('kampanya bölümleri bot tarafından bitirilir (her oyun, her zorluk)', () {
    for (final lv in [1, 2, 3, 4, 41, 42, 43, 44, 501, 502, 503, 504, 9997, 9998, 9999, 10000, 49997, 49998, 49999, 50000]) {
      final g = rules.build(planner.spec(lv));
      expect(g.attempts, lessThan(40), reason: 'bölüm $lv kolaylaştırıldı');
      final s = RetroSim(g.puzzle);
      final r = runBot(s, rules.bot, rules.maxTicks(g.puzzle));
      expect(r.won, isTrue, reason: 'bölüm $lv ${g.puzzle.game}: ${s.goalText}');
    }
  });

  test('girdi kaydı yeniden oynatılınca tur aynen geri gelir', () {
    for (final lv in [5, 6, 7, 8]) {
      final l = rules.build(planner.spec(lv)).puzzle;
      final a = RetroSim(l);
      final log = <List<int>>[];
      var last = ArcadeInput.idle;
      for (var t = 0; t < 1500 && !a.over; t++) {
        final i = rules.bot(a).quantized();
        if (!i.sameAs(last)) {
          log.add([a.ticks + 1, ...i.encode()]);
          last = i;
        }
        a.tick(i);
      }
      final b = RetroSim(l);
      replayLog(b, log, a.ticks);
      expect(b.score, a.score, reason: '$lv');
      expect(b.pixels(), a.pixels(), reason: '$lv');
    }
  });

  test('her kip üretilir', () {
    for (final m in rules.modes) {
      expect(rules.build(planner.spec(31, mode: m)).puzzle.meta.mode, m);
    }
  });
}
