import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter/material.dart';

import 'runner_player.dart';

/// 障碍物类型
enum RunnerObstacleType {
  crate,
  rock,
  pillar,
}

/// 跑酷障碍物 - 使用 AI 生成的精灵图
class RunnerObstacle extends SpriteComponent with CollisionCallbacks {
  final RunnerObstacleType obstacleType;
  final double Function() speedProvider;
  final VoidCallback onHit;

  RunnerObstacle({
    required super.position,
    required this.obstacleType,
    required this.speedProvider,
    required this.onHit,
  }) : super(anchor: Anchor.bottomCenter);

  Color _fallbackColor = const Color(0xFF888888);

  @override
  Future<void> onLoad() async {
    // 注意：Flame 的 Images 默认 prefix 就是 assets/images/，
    // 这里只传文件名，不能带 images/ 前缀
    String imgPath;
    switch (obstacleType) {
      case RunnerObstacleType.crate:
        size = Vector2(52, 50);
        imgPath = 'runner_crate.png';
        _fallbackColor = const Color(0xFF8B5A2B);
        add(RectangleHitbox(
          size: Vector2(40, 42),
          position: Vector2(6, 8),
        ));
        break;
      case RunnerObstacleType.rock:
        size = Vector2(54, 40);
        imgPath = 'runner_rock.png';
        _fallbackColor = const Color(0xFF666666);
        add(RectangleHitbox(
          size: Vector2(42, 32),
          position: Vector2(6, 8),
        ));
        break;
      case RunnerObstacleType.pillar:
        size = Vector2(46, 80);
        imgPath = 'runner_pillar.png';
        _fallbackColor = const Color(0xFFCE82FF);
        add(RectangleHitbox(
          size: Vector2(34, 70),
          position: Vector2(6, 10),
        ));
        break;
    }
    try {
      sprite = await Sprite.load(imgPath);
    } catch (_) {
      sprite = null;
    }
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = _fallbackColor,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= speedProvider() * dt;
    if (position.x < -80) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is RunnerPlayer) {
      onHit();
    }
  }
}