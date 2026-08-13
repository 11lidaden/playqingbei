import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

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

  @override
  Future<void> onLoad() async {
    // 根据类型加载对应的精灵图 + 设置尺寸
    switch (obstacleType) {
      case RunnerObstacleType.crate:
        size = Vector2(52, 50);
        sprite = await Sprite.load('images/runner_crate.png');
        add(RectangleHitbox(
          size: Vector2(40, 42),
          position: Vector2(6, 8),
        ));
        break;
      case RunnerObstacleType.rock:
        size = Vector2(54, 40);
        sprite = await Sprite.load('images/runner_rock.png');
        add(RectangleHitbox(
          size: Vector2(42, 32),
          position: Vector2(6, 8),
        ));
        break;
      case RunnerObstacleType.pillar:
        size = Vector2(46, 80);
        sprite = await Sprite.load('images/runner_pillar.png');
        add(RectangleHitbox(
          size: Vector2(34, 70),
          position: Vector2(6, 10),
        ));
        break;
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