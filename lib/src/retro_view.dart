import 'package:flutter/material.dart';
import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/arcade.dart';

import 'retro_engine.dart';

// Kendi LCD paletimiz: zeytin yeşili ekran, koyu noktalar.
const _screen = Color(0xFF9DAF8A);
const _off = Color(0xFF8FA07C);
const _on = Color(0xFF1F2A1A);
const _frame = Color(0xFF2E3A33);

const _names = [
  ['YARIŞ', 'RACE'],
  ['YILAN', 'SNAKE'],
  ['ATIŞ', 'SHOOT'],
  ['TUĞLA KIR', 'BRICKS'],
];

void paintRetro(Canvas c, ArcadeSim sim, ArcadePalette p, double t) {
  final s = sim as RetroSim;
  const cell = 62.0;
  const left = 40.0, top = 210.0;
  final screen = Rect.fromLTWH(left - 16, top - 16, kW * cell + 32, kH * cell + 32);
  c.drawRRect(RRect.fromRectAndRadius(screen.inflate(14), const Radius.circular(26)), Paint()..color = _frame);
  c.drawRRect(RRect.fromRectAndRadius(screen, const Radius.circular(12)), Paint()..color = _screen);
  final px = s.pixels();
  final blink = s.shield > 0 && (s.ticks ~/ 8).isOdd;
  for (var y = 0; y < kH; y++) {
    for (var x = 0; x < kW; x++) {
      final on = px.contains(y * kW + x);
      final r = Rect.fromLTWH(left + x * cell, top + y * cell, cell, cell).deflate(5);
      final col = on ? (blink ? _on.withValues(alpha: 0.45) : _on) : _off;
      c.drawRect(r, Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6);
      c.drawRect(r.deflate(12), Paint()..color = col);
    }
  }
  // Yan panel
  const sx = left + kW * cell + 40;
  final pw = kWorldW - sx - 18;
  final name = _names[s.game.index];
  paintText(c, name[0], Offset(sx + pw / 2, top + 30), 40, Colors.white);
  paintText(c, name[1], Offset(sx + pw / 2, top + 80), 26, Colors.white60);
  paintText(c, '${s.score}', Offset(sx + pw / 2, top + 200), 52, const Color(0xFFFFE082));
  paintText(c, '♥' * s.lives, Offset(sx + pw / 2, top + 290), 40, const Color(0xFFEF9A9A));
  paintText(c, '◀', Offset(sx + pw / 2 - 60, top + kH * cell - 80), 70, Colors.white24);
  paintText(c, '▶', Offset(sx + pw / 2 + 60, top + kH * cell - 80), 70, Colors.white24);
}

Sfx? retroSound(ArcadeSim sim) => switch ((sim as RetroSim).lastEvent) {
      1 => Sfx.coin,
      2 => Sfx.lose,
      3 => Sfx.tap,
      _ => null,
    };

Widget buildRetroStage(PlayContext ctx, RetroLevel level) => ArcadeStage(
      ctx: ctx,
      create: () => RetroSim(level),
      paint: paintRetro,
      sound: retroSound,
      howTo: switch (level.game) {
        RetroGame.race => const [
            'Ekranın soluna/sağına dokun ya da kaydır: şerit değiştir. Arabalara çarpma!',
            'Tap or swipe left/right to change lanes. Avoid the cars!',
            'Links/rechts tippen oder wischen: Spur wechseln.',
            'Toca o desliza a los lados para cambiar de carril.',
            'Touchez ou glissez à gauche/droite pour changer de voie.',
          ],
        RetroGame.snake => const [
            'Kaydırarak yılanı yönlendir, yemi ye, kendine çarpma.',
            'Swipe to steer, eat the food, don\'t bite yourself.',
            'Wischen zum Lenken, Futter fressen.',
            'Desliza para girar y come.',
            'Glissez pour tourner et mangez.',
          ],
        RetroGame.shoot => const [
            'Sola/sağa dokun: topu kaydır. Parmağın ekrandayken ateş eder.',
            'Tap left/right to move. Hold to fire.',
            'Links/rechts tippen zum Bewegen, halten zum Feuern.',
            'Toca a los lados para moverte, mantén para disparar.',
            'Touchez à gauche/droite, maintenez pour tirer.',
          ],
        RetroGame.breakout => const [
            'Raketi sürükle ya da sola/sağa dokun. Topu düşürme, bütün tuğlaları kır.',
            'Drag the paddle or tap the sides. Break every brick.',
            'Schläger ziehen oder seitlich tippen. Alle Steine zerstören.',
            'Arrastra la pala o toca los lados. Rompe todos los ladrillos.',
            'Glissez la raquette ou touchez les côtés. Cassez toutes les briques.',
          ],
      },
    );
