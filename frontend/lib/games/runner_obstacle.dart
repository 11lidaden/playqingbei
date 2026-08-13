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
    // 根据类型加载对应的精灵图 + 设置尺寸
    String imgPath;
    switch (obstacleType) {
      case RunnerObstacleType.crate:
        size = Vector2(52, 50);
        imgPath = 'images/runner_crate.png';
        _fallbackColor = const Color(0xFF8B5A2B);
        add(RectangleHitbox(
          size: Vector2(40, 42),
          position: Vector2(6, 8),
        ));
        break;
      case RunnerObstacleType.rock:
        size = Vector2(54, 40);
        imgPath = 'images/runner_rock.png';
        _fallbackColor = const Color(0xFF666666);
        add(RectangleHitbox(
          size: Vector2(42, 32),
          position: Vector2(6, 8),
        ));
        break;
      case RunnerObstacleType.pillar:
        size = Vector2(46, 80);
        imgPath = 'images/runner_pillar.png';
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