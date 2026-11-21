import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';

import 'retro_engine.dart';

const retroKonsolId = 'oyun-retro-tugla-konsolu';

class RetroRules extends ArcadeRules<RetroLevel> {
  @override
  String get gameId => retroKonsolId;

  @override
  List<String> get optionalMechanics => const [];

  @override
  List<GameStat> get gameStats => const [
        GameStat('race_passed', 'Geçilen araba', 'Cars passed', scale: 40),
        GameStat('snake_food', 'Yılan yemi', 'Snake food', scale: 20),
        GameStat('bricks_hit', 'Vurulan tuğla', 'Bricks hit', scale: 60),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('race_passed', 'race_passed', [20, 50, 120]),
        MissionTemplate('bricks_hit', 'bricks_hit', [40, 100, 250]),
      ];

  @override
  RetroLevel generate(LevelSpec spec) => generateRetroLevel(spec);

  @override
  ArcadeMeta metaOf(RetroLevel l) => l.meta;

  @override
  ArcadeSim createSim(RetroLevel l) => RetroSim(l);

  @override
  ArcadeInput bot(ArcadeSim sim) => retroBot(sim);
}
