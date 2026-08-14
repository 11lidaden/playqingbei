import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_controller.dart';

/// 射击达人 - 气球射击
///
/// 玩法：彩色气球从屏幕顶部飘落，点击击破收集金币。
/// 漏掉 3 个气球失败；收集够目标金币过关（目标随关卡递增）。
/// 与跑酷一致：金币单局计数，重跑清零。
class ShooterGame extends FlameGame with HasCollisionDetection implements GameController {
  static const double gameWidth = 480;
  static const double gameHeight = 854;

  /// 气球落出屏幕的 Y 判定（超出即算漏掉）
  static const double _outY = gameHeight + 30;

  /// 漏掉气球数上限（3 个失败）
  static const int _maxMiss = 3;

  /// 游戏结束回调（true=成功通关，false=失败）
  final void Function(bool success)? onFinished;

  final int level;
  final Random _random = Random();

  /// 已收集金币数（每个气球 = 1 金币）
  int coins = 0;

  /// 已漏掉的气球数
  int _missed = 0;

  double _elapsed = 0;
  double _spawnAccumulator = 0;
  bool isGameOver = false;
  bool hasWon = false;

  final List<_Balloon> _balloons = [];

  /// 过关所需金币 = 8 + 关卡×2（与跑酷一致）
  @override
  int get targetCoins => 8 + level * 2;

  /// HUD 右侧副信息（剩余机会）
  @override
  String get statLabel => '剩余机会';
  @override
  String get statValue => '${_maxMiss - _missed}';

  /// 气球生成间隔（秒），随关卡和时间缩短。
  /// 起步 0.8s（比旧版 1.6s 快一倍），开局立即有气球可点。
  double get _spawnInterval =>
      max(0.5, 0.8 - (level - 1) * 0.04 - _elapsed * 0.002);

  /// 气球下落速度（px/s），随关卡和时间加快。
  /// 起步 100px/s（旧版 70 太慢，看起来像没动静）。
  double get _fallSpeed => 100 + (level - 1) * 8 + _elapsed * 2.5;

  ShooterGame({this.onFinished, this.level = 1});

  @override
  Future<void> onLoad() async {
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    await add(_SkyBackground());

    // 开局预生成 2 个气球：一进游戏就有东西可点
    _spawnBalloon();
    _spawnBalloon();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _elapsed += dt;

    // 生成气球
    _spawnAccumulator += dt;
    if (_spawnAccumulator >= _spawnInterval) {
      _spawnAccumulator = 0;
      _spawnBalloon();
    }

    // 移动气球 & 检测漏掉
    for (final b in _balloons) {
      b.position.y += _fallSpeed * dt;
      if (b.position.y > _outY) {
        _onBalloonMissed(b);
      }
    }

    // 清理已移除的气球
    _balloons.removeWhere((b) => !b.isMounted);
  }

  void _spawnBalloon() {
    final colors = _BalloonColor.values;
    final color = colors[_random.nextInt(colors.length)];
    final balloon = _Balloon(
      color: color,
      // 初始 y=40：屏幕顶部可见范围（旧版 -60 在屏幕外，开局看不到）
      position: Vector2(
        40 + _random.nextDouble() * (gameWidth - 80),
        40,
      ),
    );
    _balloons.add(balloon);
    add(balloon);
  }

  /// 外部（Listener）调用：屏幕坐标点击
  void handleTap(Vector2 screenPoint) {
    if (isGameOver) return;
    final world = _screenToWorld(screenPoint);
    _tryPop(world);
  }

  /// 屏幕坐标 → 游戏世界坐标。
  /// 优先用 viewport.globalToLocal；若结果异常（NaN/越界）则用
  /// FixedResolutionViewport 的等比缩放居中算法手动兜底。
  Vector2 _screenToWorld(Vector2 screenPoint) {
    try {
      final world = camera.viewport.globalToLocal(screenPoint);
      final valid = world.x.isFinite && world.y.isFinite &&
          world.x >= -50 && world.x <= gameWidth + 50 &&
          world.y >= -50 && world.y <= gameHeight + 50;
      if (valid) return world;
    } catch (_) {
      // 忽略，走兜底
    }
    // 兜底：等比缩放居中（FixedResolutionViewport 的算法）
    final vpSize = camera.viewport.size;
    final scale = min(vpSize.x / gameWidth, vpSize.y / gameHeight);
    final gameW = gameWidth * scale;
    final gameH = gameHeight * scale;
    final offsetX = (vpSize.x - gameW) / 2;
    final offsetY = (vpSize.y - gameH) / 2;
    return Vector2(
      (screenPoint.x - offsetX) / scale,
      (screenPoint.y - offsetY) / scale,
    );
  }

  void _tryPop(Vector2 world) {
    // 找距离最近的气球（重叠时破最贴近点击位置的）
    _Balloon? nearest;
    var bestDist = double.infinity;
    for (final b in _balloons) {
      final dist = (world - b.position).length;
      if (dist < bestDist) {
        bestDist = dist;
        nearest = b;
      }
    }
    if (nearest != null && bestDist <= nearest.size.x * 0.62) {
      nearest.pop();
      _balloons.remove(nearest);
      coins += 1;
      _onCoinCollected();
    }
  }

  void _onCoinCollected() {
    if (isGameOver) return;
    if (coins >= targetCoins) {
      isGameOver = true;
      hasWon = true;
      pauseEngine();
      overlays.add('gameWin');
    }
  }

  void _onBalloonMissed(_Balloon b) {
    if (isGameOver) return;
    b.removeFromParent();
    _balloons.remove(b);
    _missed += 1;
    if (_missed >= _maxMiss) {
      isGameOver = true;
      hasWon = false;
      pauseEngine();
      overlays.add('gameOver');
    }
  }

  /// 重新开始（金币清零）
  @override
  void restart() {
    for (final b in _balloons) {
      b.removeFromParent();
    }
    _balloons.clear();

    coins = 0;
    _missed = 0;
    _elapsed = 0;
    _spawnAccumulator = 0;
    isGameOver = false;
    hasWon = false;

    // 重开也预生成 2 个，避免开局空窗
    _spawnBalloon();
    _spawnBalloon();

    overlays.remove('gameOver');
    overlays.remove('gameWin');
    resumeEngine();
  }

  /// 玩家选择"返回"：上报结果
  @override
  void quit(bool success) {
    onFinished?.call(success);
  }

  @override
  void onRemove() {
    super.onRemove();
  }
}

/// 气球颜色
enum _BalloonColor { red, blue, green, yellow }

/// 气球组件
class _Balloon extends SpriteComponent {
  final _BalloonColor color;

  _Balloon({
    required this.color,
    required super.position,
  }) : super(size: Vector2(72, 96), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final name = switch (color) {
      _BalloonColor.red => 'shooter_balloon_red.png',
      _BalloonColor.blue => 'shooter_balloon_blue.png',
      _BalloonColor.green => 'shooter_balloon_green.png',
      _BalloonColor.yellow => 'shooter_balloon_yellow.png',
    };
    try {
      // Flame Images 默认前缀是 assets/images/，只传文件名
      sprite = await Sprite.load(name);
    } catch (_) {
      sprite = null;
    }
  }

  /// 击破：播放缩小消失动画后移除
  void pop() {
    add(SequenceEffect([
      ScaleEffect.to(Vector2.all(1.4), EffectController(duration: 0.08)),
      OpacityEffect.fadeOut(EffectController(duration: 0.12)),
      RemoveEffect(),
    ]));
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      // 降级：纯色圆
      final c = switch (color) {
        _BalloonColor.red => const Color(0xFFEB4655),
        _BalloonColor.blue => const Color(0xFF468CEB),
        _BalloonColor.green => const Color(0xFF5AC364),
        _BalloonColor.yellow => const Color(0xFFF5CD32),
      };
      canvas.drawOval(
        Rect.fromLTWH(size.x * 0.1, 0, size.x * 0.8, size.y * 0.7),
        Paint()..color = c,
      );
    }
  }
}

/// 背景：渐变天空 + 云朵
class _SkyBackground extends PositionComponent {
  _SkyBackground()
      : super(position: Vector2.zero(), size: Vector2(ShooterGame.gameWidth, ShooterGame.gameHeight));

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 天空渐变（淡蓝→浅黄）
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF87CEEB), Color(0xFFB8E6F2), Color(0xFFFFF8E1)],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // 云朵
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawOval(Rect.fromLTWH(60, 110, 70, 36), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(88, 95, 50, 40), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(300, 180, 90, 42), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(330, 168, 55, 40), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(40, 300, 70, 34), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(250, 320, 80, 38), cloudPaint);
  }
}
