import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import 'runner_game.dart';

/// 跑酷玩家
///
/// 使用 SpriteComponent 加载 AI 生成的卡通角色图。
/// 手感调校（参考 game-feel 技能）：
/// - 不对称重力：下落重力 = 上升重力 ×1.8
/// - Coyote time：离开地面后 0.10s 内仍可起跳
/// - Jump buffer：落地前 0.12s 内按跳跃会缓冲
/// - 可变跳跃：松手后上升速度减半
class RunnerPlayer extends SpriteComponent with CollisionCallbacks {
  // 跳跃物理参数：峰值高度 h=130px，上升时间 t=0.30s
  static const double _jumpHeight = 130;
  static const double _riseTime = 0.30;
  static const double _gravity = 2 * _jumpHeight / (_riseTime * _riseTime); // ≈2889
  static const double _jumpVelocity = -2 * _jumpHeight / _riseTime; // ≈-867
  static const double _fallMultiplier = 1.8; // 不对称重力
  static const double _coyoteTime = 0.10;
  static const double _jumpBuffer = 0.12;
  static const double _maxFallSpeed = 900;
  static const double _variableJumpCut = 0.5;

  Vector2 velocity = Vector2.zero();
  bool _isOnGround = true;
  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;
  double _runPhase = 0;
  bool _groundTouched = true;

  RunnerPlayer({required super.position}) : super(size: Vector2(60, 80), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('images/runner_player.png');
    add(RectangleHitbox(
      size: Vector2(40, 60),
      position: Vector2(10, 20),
    ));
  }

  void jump() {
    _jumpBufferTimer = _jumpBuffer;
    if (_isOnGround || _coyoteTimer > 0) {
      _doJump();
    }
  }

  void releaseJump() {
    if (velocity.y < 0) {
      velocity.y *= _variableJumpCut;
    }
  }

  void _doJump() {
    velocity.y = _jumpVelocity;
    _isOnGround = false;
    _coyoteTimer = 0;
    _jumpBufferTimer = 0;
  }

  void reset() {
    velocity = Vector2.zero();
    position = Vector2(110, RunnerGame.groundY);
    _isOnGround = true;
    _coyoteTimer = 0;
    _jumpBufferTimer = 0;
    scale = Vector2.all(1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    const groundY = RunnerGame.groundY;
    _isOnGround = position.y >= groundY - 0.5;

    if (_isOnGround) {
      _coyoteTimer = _coyoteTime;
    } else {
      _coyoteTimer = max(0, _coyoteTimer - dt);
    }
    _jumpBufferTimer = max(0, _jumpBufferTimer - dt);

    if (_isOnGround && _jumpBufferTimer > 0) {
      _doJump();
    }

    if (!_isOnGround) {
      final g = velocity.y > 0 ? _gravity * _fallMultiplier : _gravity;
      velocity.y = min(_maxFallSpeed, velocity.y + g * dt);
    } else {
      velocity.y = 0;
    }

    position.y += velocity.y * dt;

    if (position.y >= groundY) {
      position.y = groundY;
      velocity.y = 0;
      _isOnGround = true;
    }

    // 卡通形变：跳起拉长 + 落地弹一下 + 跑步微颠簸
    double sx = 1.0, sy = 1.0;
    if (!_isOnGround) {
      sx = 0.9;
      sy = 1.12;
    } else if (_groundTouched) {
      sx = 1.08;
      sy = 0.92;
      _groundTouched = false;
    } else {
      sx = 1 + sin(_runPhase) * 0.02;
      sy = 1 - sin(_runPhase) * 0.02;
    }
    scale = Vector2(sx, sy);

    _runPhase += dt * 10;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    _groundTouched = true;
  }
}