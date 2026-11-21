/// Retro Tuğla Konsolu: nokta ekranda dört klasik mini oyun.
/// Blok Oyunları merkez uygulamasının oyunu.
library;

import 'package:flutter/material.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/core/game_rules.dart';

import 'src/retro_engine.dart';
import 'src/retro_rules.dart';
import 'src/retro_view.dart';

export 'src/retro_engine.dart';
export 'src/retro_rules.dart';

final retroKonsolConfig = GameConfig(
  gameId: retroKonsolId,
  title: const ['Retro Konsol', 'Retro Console', 'Retro-Konsole', 'Consola Retro', 'Console Rétro'],
  tagline: const [
    'Nokta ekranda 4 klasik oyun',
    '4 classics on a dot screen',
    '4 Klassiker auf Punktbildschirm',
    '4 clásicos en pantalla de puntos',
    '4 classiques sur écran à points',
  ],
  seedColor: const Color(0xFF689F38),
  icon: Icons.videogame_asset_rounded,
  rules: RetroRules(),
  buildPlay: (ctx) => buildRetroStage(ctx, (ctx.generated as GeneratedLevel<RetroLevel>).puzzle),
  tutorial: const [
    TutorialStep(Icons.videogame_asset, [
      'Bölümler sırayla Yarış, Yılan, Atış ve Tuğla Kır oyunlarından oluşur.',
      'Levels rotate through Race, Snake, Shoot and Bricks.',
      'Die Level wechseln zwischen Rennen, Schlange, Schießen und Steine.',
      'Los niveles alternan Carrera, Serpiente, Disparo y Ladrillos.',
      'Les niveaux alternent Course, Serpent, Tir et Briques.',
    ]),
    TutorialStep(Icons.touch_app, [
      'Ekranın soluna ya da sağına dokunarak hareket et; her oyunun ipucu başta görünür.',
      'Tap the left or right side to move; each game shows a tip first.',
      'Tippe links oder rechts; jedes Spiel zeigt zuerst einen Tipp.',
      'Toca a la izquierda o derecha; cada juego muestra un consejo.',
      'Touchez à gauche ou à droite ; chaque jeu affiche une astuce.',
    ]),
  ],
);
