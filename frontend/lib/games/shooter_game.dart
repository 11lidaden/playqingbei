import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter/material.dart';

import 'game_controller.dart';

/// 射击达人 - 气球射击
///
/// 玩法：彩色气球从屏幕顶部飘落，点击击破收集金币。
/// 漏掉 3 个气球失败；收集够目标金币过关（目标随关卡递增）。
///
/// 点击命中双通道：
/// 1. 主通道：气球组件自带 TapCallbacks（Flame 内部命中，绕开坐标换算）
/// 2. 备通道：GameScreen 的 Listener 调 handleTap（屏幕坐标正向映射比较）
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

  /// 调试信息（点击坐标 / viewport 尺寸 / 命中距离）
  String _debugInfo = '';

  /// HUD 调试文本
  @override
  String get debugText => _debugInfo;

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

  /// 气球生成间隔（秒），随关卡和时间缩短
  double get _spawnInterval =>
      max(0.5, 0.8 - (level - 1) * 0.04 - _elapsed * 0.002);

  /// 气球下落速度（px/s），随关卡和时间加快
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

    // 检查漏掉（气球位置由各自 MoveEffect 驱动）
    for (final b in _balloons.toList()) {
      if (b.isMounted && b.position.y > _outY) {
        _onBalloonMissed(b);
      }
    }

    // 清理已移除的气球
    _balloons.removeWhere((b) => !b.isMounted);
  }

  void _spawnBalloon() {
    final colors = _BalloonColor.values;
    final color = colors[_random.nextInt(colors.length)];
    // 初始 y 错开（40~220 随机），避免堆叠
    final startY = 40 + _random.nextDouble() * 180;

    late final _Balloon balloon;
    balloon = _Balloon(
      color: color,
      onPopped: () => _onBalloonPopped(balloon),
      position: Vector2(
        40 + _random.nextDouble() * (gameWidth - 80),
        startY,
      ),
    );
    _balloons.add(balloon);
    add(balloon);

    // MoveEffect 驱动下落（独立于 game.update 的位置修改）
    final distance = _outY + 100 - startY;
    balloon.add(MoveEffect.by(
      Vector2(0, distance),
      EffectController(speed: _fallSpeed),
    ));
  }

  /// 气球被击破（TapCallbacks 主通道 / Listener 备通道都会走到这里）
  void _onBalloonPopped(_Balloon b) {
    if (isGameOver) return;
    if (!b.isMounted || !_balloons.contains(b)) return;
    b.pop();
    _balloons.remove(b);
    coins += 1;
    _debugInfo = 'POP! coins=' + coins.toString() + '/' + targetCoins.toString();
    _onCoinCollected();
  }

  /// 外部（Listener）调用：屏幕坐标点击（备用通道）
  void handleTap(Vector2 screenPoint) {
    if (isGameOver) return;
    // 正向映射：气球的 world 位置 → 屏幕坐标，直接与点击坐标比较
    final vpSize = camera.viewport.size;
    if (vpSize.x <= 0 || vpSize.y <= 0) {
      _debugInfo = 'tap=(' + screenPoint.x.toStringAsFixed(0) + ',' + screenPoint.y.toStringAsFixed(0) +
          ') vp=(0,0) vp未初始化';
      return;
    }
    final scale = min(vpSize.x / gameWidth, vpSize.y / gameHeight);
    final offsetX = (vpSize.x - gameWidth * scale) / 2;
    final offsetY = (vpSize.y - gameHeight * scale) / 2;

    // 找最近气球并记录距离（调试）
    double bestDist = double.infinity;
    _Balloon? nearest;
    for (final b in _balloons.reversed) {
      if (!b.isMounted) continue;
      final sx = offsetX + b.position.x * scale;
      final sy = offsetY + b.position.y * scale;
      final dist = (screenPoint - Vector2(sx, sy)).length;
      if (dist < bestDist) {
        bestDist = dist;
        nearest = b;
      }
    }
    final hitRadius = nearest == null ? 0.0 : nearest.size.x * 0.85 * scale;
    _debugInfo = 'tap=(' + screenPoint.x.toStringAsFixed(0) + ',' + screenPoint.y.toStringAsFixed(0) +
        ') vp=(' + vpSize.x.toStringAsFixed(0) + ',' + vpSize.y.toStringAsFixed(0) +
        ') scale=' + scale.toStringAsFixed(2) +
        ' near=' + (nearest == null ? '-' : bestDist.toStringAsFixed(0)) +
        ' hit<=' + hitRadius.toStringAsFixed(0);

    if (nearest != null && bestDist <= hitRadius) {
      _onBalloonPopped(nearest);
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

/// 气球组件：位置由 MoveEffect 驱动，点击由 TapCallbacks 内部命中
class _Balloon extends SpriteComponent with TapCallbacks {
  final _BalloonColor color;
  final VoidCallback onPopped;

  _Balloon({
    required this.color,
    required this.onPopped,
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
      sprite = await Sprite.load(name);
    } catch (_) {
      sprite = null;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPopped();
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

    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF87CEEB), Color(0xFFB8E6F2), Color(0xFFFFF8E1)],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawOval(Rect.fromLTWH(60, 110, 70, 36), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(88, 95, 50, 40), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(300, 180, 90, 42), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(330, 168, 55, 40), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(40, 300, 70, 34), cloudPaint);
    canvas.drawOval(Rect.fromLTWH(250, 320, 80, 38), cloudPaint);
  }
}
