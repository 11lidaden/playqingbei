import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'runner_coin.dart';
import 'runner_obstacle.dart';
import 'runner_player.dart';

/// 跑酷大冒险 - 主游戏
///
/// 玩法：角色自动向右奔跑，点击屏幕跳跃，躲避障碍物，收集金币。
/// 基于 Flame 引擎，固定分辨率 480x854（竖屏），适配各种手机。
class RunnerGame extends FlameGame with HasCollisionDetection {
  /// 游戏逻辑分辨率（FixedResolutionViewport 自动缩放适配屏幕）
  static const double gameWidth = 480;
  static const double gameHeight = 854;

  /// 地面所在的 Y 坐标
  static const double groundY = 690;

  /// 游戏结束回调（true=成功通关，false=失败）
  final void Function(bool success)? onFinished;

  late final RunnerPlayer player;
  final Random _random = Random();

  /// 得分（金币）
  int score = 0;

  /// 奔跑距离（米，1 单位 = 20px）
  int get distanceMeters => (distance / 20).floor();

  /// 世界滚动速度（px/s），随时间平滑递增
  double _speed = 200;
  double distance = 0;
  double _elapsed = 0;
  bool isGameOver = false;

  /// 难度曲线：起始 200，每秒 +8，上限 600（约 50s 加到满速）
  double get speed => min(600, _speed + _elapsed * 8);

  double _spawnAccumulator = 0;

  /// 当前障碍生成间隔（秒），随速度缩短
  double get _spawnInterval {
    // 速度 200→1.6s，速度 600→0.7s，线性插值
    return (1.6 - (speed - 200) * (1.6 - 0.7) / (600 - 200)).clamp(0.7, 1.6);
  }

  RunnerGame({this.onFinished});

  @override
  Future<void> onLoad() async {
    // 固定分辨率视口，逻辑坐标始终 480x854
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // 背景（渐变天空 + 视差山丘 + 云朵）
    await add(_ParallaxBackground());

    // 地面
    await add(_Ground());

    // 玩家
    player = RunnerPlayer(
      position: Vector2(110, groundY),
    );
    await add(player);
  }


  void _spawnObstacle() {
    // 随机障碍类型：0=木箱(地面)，1=石头(地面)，2=高柱(必须跳过)
    final type = _random.nextInt(3);
    final pos = Vector2(gameWidth + 60, groundY);
    final obstacle = RunnerObstacle(
      position: pos,
      obstacleType: RunnerObstacleType.values[type],
      speedProvider: () => speed,
      onHit: _onPlayerHitObstacle,
    );
    add(obstacle);

    // 偶尔在障碍上方放一枚金币（鼓励跳跃）
    if (_random.nextDouble() < 0.5) {
      final coin = RunnerCoin(
        position: Vector2(
          gameWidth + 80 + _random.nextInt(40),
          groundY - 90 - _random.nextInt(60),
        ),
        onCollected: _onCoinCollected,
      );
      add(coin);
    }
  }

  void _onPlayerHitObstacle() {
    if (isGameOver) return;
    isGameOver = true;
    pauseEngine();
    overlays.add('gameOver');
  }

  void _onCoinCollected() {
    score += 10;
  }

  /// 重新开始
  void restart() {
    // 清理所有障碍和金币（直接从组件树里清，不必维护冗余列表）
    for (final child in children) {
      if (child is RunnerObstacle) child.removeFromParent();
      if (child is RunnerCoin) child.removeFromParent();
    }

    score = 0;
    distance = 0;
    _elapsed = 0;
    _speed = 200;
    _spawnAccumulator = 0;
    isGameOver = false;

    player.reset();

    overlays.remove('gameOver');
    resumeEngine();
  }

  /// 玩家选择"返回"：上报结果
  void quit(bool success) {
    onFinished?.call(success);
  }

  @override
  void update(double dt) {
    if (isGameOver) {
      super.update(dt);
      return;
    }

    _elapsed += dt;
    distance += speed * dt;

    // 障碍物生成：按速度动态调整间隔
    _spawnAccumulator += dt;
    if (_spawnAccumulator >= _spawnInterval) {
      _spawnAccumulator = 0;
      _spawnObstacle();
    }

    super.update(dt);
  }

  @override
  void onRemove() {
    super.onRemove();
  }
}

/// 地面（草地 + 泥土），带滚动条纹
class _Ground extends PositionComponent {
  _Ground() : super(position: Vector2(0, RunnerGame.groundY), size: Vector2(RunnerGame.gameWidth, RunnerGame.gameHeight - RunnerGame.groundY));

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    // 泥土
    canvas.drawRect(rect, Paint()..color = const Color(0xFF8B5A2B));
    // 草地
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 18),
      Paint()..color = const Color(0xFF58CC02),
    );
    // 草地上的小纹理
    final paint = Paint()..color = const Color(0xFF3FA302);
    for (var i = 0.0; i < size.x; i += 40) {
      canvas.drawRect(Rect.fromLTWH(i, 4, 18, 3), paint);
    }
    // 泥土纹理
    final dirtPaint = Paint()..color = const Color(0xFF6F4518);
    for (var i = 0.0; i < size.x; i += 34) {
      canvas.drawRect(Rect.fromLTWH(i + 8, 34, 14, 3), dirtPaint);
    }
  }
}

/// 视差背景：渐变天空 + 远山 + 云朵
class _ParallaxBackground extends PositionComponent {
  final double _cloudSpeed = 30;
  double _offset = 0;

  _ParallaxBackground() : super(position: Vector2.zero(), size: Vector2(RunnerGame.gameWidth, RunnerGame.gameHeight));

  @override
  void update(double dt) {
    // 云层缓慢移动（游戏静止时也飘）
    _offset = (_offset + _cloudSpeed * dt) % RunnerGame.gameWidth;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // 天空渐变
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF87CEEB), Color(0xFFB8E6F2), Color(0xFFFFF8E1)],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // 远山（静态两层）
    final mountainPaint = Paint()..color = const Color(0xFF7BC67E);
    final path = Path()
      ..moveTo(0, RunnerGame.groundY)
      ..lineTo(0, RunnerGame.groundY - 120)
      ..lineTo(120, RunnerGame.groundY - 40)
      ..lineTo(240, RunnerGame.groundY - 130)
      ..lineTo(360, RunnerGame.groundY - 50)
      ..lineTo(w, RunnerGame.groundY - 110)
      ..lineTo(w, RunnerGame.groundY)
      ..close();
    canvas.drawPath(path, mountainPaint);

    // 云朵（视差移动）
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.9);
    for (var i = -1; i < 3; i++) {
      final x = i * w + _offset;
      _drawCloud(canvas, x, 120, 0.8, cloudPaint);
      _drawCloud(canvas, (x + w * 0.6) % (w * 1.5) - w * 0.5, 210, 0.6, cloudPaint);
    }
  }

  void _drawCloud(Canvas canvas, double x, double y, double scale, Paint paint) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale);
    canvas.drawOval(Rect.fromLTWH(-30, -15, 60, 30), paint);
    canvas.drawOval(Rect.fromLTWH(-15, -30, 45, 40), paint);
    canvas.drawOval(Rect.fromLTWH(5, -20, 40, 35), paint);
    canvas.restore();
  }
}
