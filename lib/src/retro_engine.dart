import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

/// Retro Tuğla Konsolu: 10x20 nokta ekranda dört mini oyun.
/// 0 Yarış, 1 Yılan, 2 Atış, 3 Tuğla Kır. Hepsi kare kare, belirlenimli.

const int kW = 10;
const int kH = 20;

enum RetroGame { race, snake, shoot, breakout }

class RetroLevel {
  final ArcadeMeta meta;
  final RetroGame game;
  final int step; // bir adım kaç tik
  final int target; // 0 = hedefsiz
  const RetroLevel({required this.meta, required this.game, required this.step, required this.target});
}

RetroLevel generateRetroLevel(LevelSpec spec) {
  final m = ArcadeMeta.of(spec);
  final d = spec.difficulty.clamp(1, 10);
  final game = RetroGame.values[((spec.levelId - 1) % 4 + 4) % 4];
  final step = (13 - d).clamp(4, 12);
  final target = !m.goal
      ? 0
      : switch (game) {
          RetroGame.race => 15 + d * 4,
          RetroGame.snake => 8 + d * 2,
          RetroGame.shoot => 20 + d * 5,
          RetroGame.breakout => 0, // bütün tuğlalar
        };
  return RetroLevel(meta: m, game: game, step: step, target: target);
}

class RetroSim extends ArcadeSim {
  final RetroLevel level;
  late final SeededRandom r2;
  int timer = 0;
  int progressCount = 0;
  int lastEvent = 0; // 1 puan, 2 çarpma, 3 hamle

  // Yarış
  int lane = 0; // 0 sol, 1 sağ
  final List<(int, int)> cars = []; // (şerit, y üst)
  int carGap = 0;

  // Yılan
  List<int> body = [];
  int dir = 0, pendingDir = 0, food = -1;

  // Atış
  int gunX = 4;
  final Set<int> bricks = {};
  final List<(int, int)> bullets = [];
  int dropTimer = 0;

  // Tuğla kır
  int padX = 3;
  int bx = 4, by = 15, bdx = 1, bdy = -1;
  int bricksTotal = 0;

  RetroSim(this.level) : super(level.meta) {
    r2 = SeededRandom(mixSeed([level.meta.seed, 99]));
    _start();
  }

  RetroGame get game => level.game;

  void _start() {
    switch (game) {
      case RetroGame.race:
        cars.clear();
        lane = 0;
      case RetroGame.snake:
        body = [17 * kW + 4, 18 * kW + 4, 19 * kW + 4];
        dir = 0;
        pendingDir = 0;
        _food();
      case RetroGame.shoot:
        gunX = 4;
        bullets.clear();
        if (bricks.isEmpty) {
          for (var y = 0; y < 4; y++) {
            _brickRow(y);
          }
        }
      case RetroGame.breakout:
        padX = 3;
        bx = 4;
        by = 17;
        bdx = 1;
        bdy = -1;
        if (bricks.isEmpty) {
          for (var y = 1; y < 5; y++) {
            for (var x = 0; x < kW; x++) {
              bricks.add(y * kW + x);
            }
          }
          bricksTotal = bricks.length;
        }
    }
  }

  void _brickRow(int y) {
    for (var x = 0; x < kW; x++) {
      if (r2.chance(0.7)) bricks.add(y * kW + x);
    }
  }

  void _food() {
    for (var k = 0; k < 400; k++) {
      final c = r2.nextInt(kW * kH);
      if (!body.contains(c)) {
        food = c;
        return;
      }
    }
  }

  /// Ekrandaki dolu noktalar (boyama ve testler için).
  Set<int> pixels() {
    final p = <int>{};
    void put(int x, int y) {
      if (x >= 0 && x < kW && y >= 0 && y < kH) p.add(y * kW + x);
    }

    switch (game) {
      case RetroGame.race:
        for (final c in cars) {
          _car(c.$1, c.$2, put);
        }
        _car(lane, kH - 4, put);
        // Yol kenarı
        for (var y = 0; y < kH; y++) {
          if ((y + ticks ~/ level.step) % 3 != 0) {
            put(0, y);
            put(kW - 1, y);
          }
        }
      case RetroGame.snake:
        p.addAll(body);
        if (food >= 0) p.add(food);
      case RetroGame.shoot:
        p.addAll(bricks);
        for (final b in bullets) {
          put(b.$1, b.$2);
        }
        put(gunX, kH - 2);
        put(gunX - 1, kH - 1);
        put(gunX, kH - 1);
        put(gunX + 1, kH - 1);
      case RetroGame.breakout:
        p.addAll(bricks);
        for (var k = 0; k < 3; k++) {
          put(padX + k, kH - 1);
        }
        put(bx, by);
    }
    return p;
  }

  static void _car(int lane, int top, void Function(int, int) put) {
    final x0 = lane == 0 ? 2 : 5;
    // . X .
    // X X X
    // . X .
    // X . X
    put(x0 + 1, top);
    put(x0, top + 1);
    put(x0 + 1, top + 1);
    put(x0 + 2, top + 1);
    put(x0 + 1, top + 2);
    put(x0, top + 3);
    put(x0 + 2, top + 3);
  }

  int _horizontal(ArcadeInput i) {
    if (i.swipe == 1) return 1;
    if (i.swipe == 3) return -1;
    if (i.tap && i.hasPointer && game != RetroGame.snake) {
      if (i.x < kWorldW * 0.4) return -1;
      if (i.x > kWorldW * 0.6) return 1;
    }
    return 0;
  }

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    timer++;
    final h = _horizontal(input);
    switch (game) {
      case RetroGame.race:
        if (h != 0) {
          lane = h > 0 ? 1 : 0;
          lastEvent = 3;
        }
        if (timer >= level.step) {
          timer = 0;
          _raceStep();
        }
      case RetroGame.snake:
        var nd = -1;
        if (input.swipe >= 0) nd = input.swipe;
        if (input.dirX != 0) nd = input.dirX > 0 ? 1 : 3;
        if (input.dirY != 0) nd = input.dirY > 0 ? 2 : 0;
        if (input.tap && input.hasPointer && input.swipe < 0) {
          // Başın soluna/sağına dokununca döner.
          final hx = (body.first % kW + 0.5) * (kWorldW / kW);
          nd = (dir == 0 || dir == 2) ? (input.x < hx ? 3 : 1) : (input.y < 800 ? 0 : 2);
        }
        if (nd >= 0 && (nd + 2) % 4 != dir) pendingDir = nd;
        if (timer >= level.step) {
          timer = 0;
          _snakeStep();
        }
      case RetroGame.shoot:
        if (h != 0) gunX = (gunX + h).clamp(0, kW - 1);
        final fire = input.tap || input.swipe == 0 || input.down;
        if (fire && ticks % 5 == 0 && bullets.length < 4) bullets.add((gunX, kH - 2));
        _bullets();
        dropTimer++;
        if (dropTimer >= level.step * 16) {
          dropTimer = 0;
          _shootDrop();
        }
      case RetroGame.breakout:
        if (h != 0) padX = (padX + h).clamp(0, kW - 3);
        if (input.down && input.hasPointer && input.swipe < 0 && !input.tap) {
          final want = ((input.x / kWorldW) * kW).floor() - 1;
          if (want > padX) padX = (padX + 1).clamp(0, kW - 3);
          if (want < padX) padX = (padX - 1).clamp(0, kW - 3);
        }
        if (timer >= (level.step * 0.7).ceil()) {
          timer = 0;
          _ballStep();
        }
    }
    if (level.target > 0 && progressCount >= level.target) win();
    if (game == RetroGame.breakout && level.meta.goal && bricks.isEmpty) win();
  }

  // ---- Yarış
  void _raceStep() {
    for (var i = cars.length - 1; i >= 0; i--) {
      final c = cars[i];
      cars[i] = (c.$1, c.$2 + 1);
      if (cars[i].$2 >= kH) {
        cars.removeAt(i);
        progressCount++;
        score += 10;
        lastEvent = 1;
      }
    }
    for (final c in cars) {
      if (c.$1 == lane && c.$2 + 3 >= kH - 4 && c.$2 <= kH - 1) {
        lastEvent = 2;
        hit();
        if (!over) cars.clear();
        return;
      }
    }
    carGap--;
    if (carGap <= 0) {
      cars.add((r2.nextInt(2), -4));
      carGap = 6 + r2.nextInt(4);
    }
  }

  // ---- Yılan
  void _snakeStep() {
    dir = pendingDir;
    const dx = [0, 1, 0, -1], dy = [-1, 0, 1, 0];
    final hx = body.first % kW + dx[dir], hy = body.first ~/ kW + dy[dir];
    if (hx < 0 || hy < 0 || hx >= kW || hy >= kH || body.sublist(0, body.length - 1).contains(hy * kW + hx)) {
      lastEvent = 2;
      hit();
      if (!over) _start();
      return;
    }
    final nh = hy * kW + hx;
    body.insert(0, nh);
    if (nh == food) {
      progressCount++;
      score += 10;
      lastEvent = 1;
      _food();
    } else {
      body.removeLast();
    }
  }

  // ---- Atış
  void _bullets() {
    for (var i = bullets.length - 1; i >= 0; i--) {
      final b = bullets[i];
      final ny = b.$2 - 1;
      final cell = ny * kW + b.$1;
      if (ny < 0) {
        bullets.removeAt(i);
      } else if (bricks.remove(cell)) {
        bullets.removeAt(i);
        progressCount++;
        score += 5;
        lastEvent = 1;
      } else {
        bullets[i] = (b.$1, ny);
      }
    }
  }

  void _shootDrop() {
    final moved = {for (final c in bricks) c + kW};
    bricks
      ..clear()
      ..addAll(moved);
    _brickRow(0);
    if (bricks.any((c) => c ~/ kW >= kH - 2)) {
      lastEvent = 2;
      hit();
      if (!over) bricks.removeWhere((c) => c ~/ kW >= kH - 8);
    }
  }

  // ---- Tuğla kır
  void _ballStep() {
    var nx = bx + bdx, ny = by + bdy;
    if (nx < 0 || nx >= kW) {
      bdx = -bdx;
      nx = bx + bdx;
    }
    if (ny < 0) {
      bdy = -bdy;
      ny = by + bdy;
    }
    final target = ny * kW + nx;
    if (bricks.remove(target) || bricks.remove(ny * kW + bx)) {
      bdy = -bdy;
      progressCount++;
      score += 5;
      lastEvent = 1;
      return;
    }
    if (ny == kH - 1) {
      if (nx >= padX - 1 && nx <= padX + 3) {
        bdy = -1;
        // Kenara çarpınca o yöne, ortaya çarpınca rastgele: top döngüye girmez.
        if (nx <= padX - 1 || nx == padX) {
          bdx = -1;
        } else if (nx >= padX + 2) {
          bdx = 1;
        } else {
          bdx = r2.chance(0.5) ? 1 : -1;
        }
        lastEvent = 3;
        return;
      }
      lastEvent = 2;
      hit();
      if (!over) {
        bx = padX + 1;
        by = kH - 3;
        bdy = -1;
      }
      return;
    }
    bx = nx;
    by = ny;
  }

  @override
  double get progress {
    if (game == RetroGame.breakout && level.meta.goal) {
      return bricksTotal == 0 ? 0 : 1 - bricks.length / bricksTotal;
    }
    return level.target == 0 ? 0 : (progressCount / level.target).clamp(0, 1).toDouble();
  }

  @override
  String get goalText {
    if (game == RetroGame.breakout && level.meta.goal) return '${bricks.length}';
    return level.target == 0 ? '$progressCount' : '$progressCount/${level.target}';
  }

  @override
  Map<String, int> get stats => {
        'race_passed': game == RetroGame.race ? progressCount : 0,
        'snake_food': game == RetroGame.snake ? progressCount : 0,
        'bricks_hit': game == RetroGame.shoot || game == RetroGame.breakout ? progressCount : 0,
      };

  @override
  int get stars => lifeStars(this, 3);
}

/// Bot: her mini oyun için basit ama güvenilir bir oynayış.
ArcadeInput retroBot(ArcadeSim s) {
  final g = s as RetroSim;
  switch (g.game) {
    case RetroGame.race:
      // Kendi şeridinde yakın araba varsa öbür şeride geç.
      for (final c in g.cars) {
        if (c.$1 == g.lane && c.$2 >= kH - 12) {
          final other = 1 - g.lane;
          final blocked = g.cars.any((o) => o.$1 == other && o.$2 >= kH - 9);
          if (!blocked) return ArcadeInput(swipe: other == 1 ? 1 : 3);
        }
      }
      return ArcadeInput.idle;
    case RetroGame.snake:
      if (g.timer != g.level.step - 1) return ArcadeInput.idle;
      final d = _snakeDir(g);
      return d == null || d == g.pendingDir ? ArcadeInput.idle : ArcadeInput(swipe: d);
    case RetroGame.shoot:
      // En alttaki tuğlanın sütununa git, ateş et.
      var col = g.gunX, low = -1;
      for (final c in g.bricks) {
        final y = c ~/ kW, x = c % kW;
        if (y > low || (y == low && (x - g.gunX).abs() < (col - g.gunX).abs())) {
          low = y;
          col = x;
        }
      }
      if (col > g.gunX && g.ticks % 2 == 0) return const ArcadeInput(swipe: 1, down: true);
      if (col < g.gunX && g.ticks % 2 == 0) return const ArcadeInput(swipe: 3, down: true);
      return const ArcadeInput(down: true);
    case RetroGame.breakout:
      // Topun ineceği yere göre raket ortası.
      var want = g.bx;
      if (g.bdy > 0) {
        var x = g.bx, dx = g.bdx;
        for (var y = g.by; y < kH - 1; y++) {
          x += dx;
          if (x < 0 || x >= kW) {
            dx = -dx;
            x += 2 * dx;
          }
        }
        want = x;
      }
      final centre = g.padX + 1;
      if (want > centre && g.padX < kW - 3) return const ArcadeInput(swipe: 1);
      if (want < centre && g.padX > 0) return const ArcadeInput(swipe: 3);
      return ArcadeInput.idle;
  }
}

int? _snakeDir(RetroSim g) {
  const dx = [0, 1, 0, -1], dy = [-1, 0, 1, 0];
  final n = kW * kH;
  final blocked = List<bool>.filled(n, false);
  for (var i = 0; i < g.body.length - 1; i++) {
    blocked[g.body[i]] = true;
  }
  final first = List<int>.filled(n, -1);
  final q = <int>[];
  final head = g.body.first;
  for (var d = 0; d < 4; d++) {
    if ((d + 2) % 4 == g.dir) continue;
    final x = head % kW + dx[d], y = head ~/ kW + dy[d];
    if (x < 0 || y < 0 || x >= kW || y >= kH) continue;
    final c = y * kW + x;
    if (blocked[c] || first[c] >= 0) continue;
    first[c] = d;
    q.add(c);
  }
  for (var qi = 0; qi < q.length; qi++) {
    final c = q[qi];
    if (c == g.food) return first[c];
    for (var d = 0; d < 4; d++) {
      final x = c % kW + dx[d], y = c ~/ kW + dy[d];
      if (x < 0 || y < 0 || x >= kW || y >= kH) continue;
      final nc = y * kW + x;
      if (blocked[nc] || first[nc] >= 0) continue;
      first[nc] = first[c];
      q.add(nc);
    }
  }
  // Yem görünmüyorsa en çok boş alana açılan yön.
  int? best;
  var bestSpace = -1;
  for (var d = 0; d < 4; d++) {
    if ((d + 2) % 4 == g.dir) continue;
    final x = head % kW + dx[d], y = head ~/ kW + dy[d];
    if (x < 0 || y < 0 || x >= kW || y >= kH || blocked[y * kW + x]) continue;
    var space = 0;
    for (var k = 0; k < n; k++) {
      if (first[k] == d) space++;
    }
    if (space > bestSpace) {
      bestSpace = space;
      best = d;
    }
  }
  return best;
}
