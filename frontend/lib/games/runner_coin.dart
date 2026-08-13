import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import 'runner_game.dart';
import 'runner_player.dart';

/// 跑酷金币 - 使用 AI 生成的精灵图
class RunnerCoin extends SpriteComponent with CollisionCallbacks {
  final VoidCallback onCollected;
  bool _collected = false;
  double _phase = 0;

  RunnerCoin({
    required super.position,
    required this.onCollected,
  }) : super(size: Vector2.all(32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    try {
      // 注意：Flame 的 Images 默认 prefix 就是 assets/images/，
      // 这里只传文件名，不能带 images/ 前缀
      sprite = await Sprite.load('runner_coin.png');
    } catch (_) {
      sprite = null;
    }
    add(CircleHitbox(radius: 14));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 3;

    if (!_collected) {
      final game = findGame();
      if (game is RunnerGame) {
        position.x -= game.speed * dt;
      }
    }

    if (position.x < -40) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      // 叠加呼吸缩放
      final scale = 1 + sin(_phase) * 0.08;
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(scale, scale);
      canvas.translate(-size.x / 2, -size.y / 2);
      super.render(canvas);
      canvas.restore();
    } else {
      // 降级渲染：金色圆 + 描边
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 - 1,
        Paint()..color = const Color(0xFFFFD700),
      );
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 - 1,
        Paint()
          ..color = const Color(0xFFFFA500)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (_collected) return;
    if (other is RunnerPlayer) {
      _collected = true;
      onCollected();

      add(SequenceEffect([
        ScaleEffect.to(Vector2.all(1.6), EffectController(duration: 0.12)),
        OpacityEffect.fadeOut(EffectController(duration: 0.12)),
        RemoveEffect(),
      ]));
      removeWhere((c) => c is CircleHitbox);
    }
  }
}