import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import 'runner_game.dart';

/// 跑酷玩家
///
/// 儿童友好手感（v1.2.8）：
/// - 跳得更高更慢：峰高 200px，上升 0.45s，滞空时间长，反应窗口大
/// - 轻微不对称重力：下落 ×1.3（不过分下坠，但也不会飘太久）
/// - 大 Coyote time：0.18s，离开地面后仍有充足时间补救
/// - 大 Jump buffer：0.25s，落地前提前按也能接上
/// - 二段跳：空中可再跳一次（80% 力度），跳早了能补救
/// - 去掉可变跳跃：按一下就是一跳，不依赖按压时长，简单直接
class RunnerPlayer extends SpriteComponent with CollisionCallbacks {
  // 跳跃物理参数：峰值高度 h=200px，上升时间 t=0.45s
  static const double _jumpHeight = 200;
  static const double _riseTime = 0.45;
  static const double _gravity = 2 * _jumpHeight / (_riseTime * _riseTime); // ≈1975
  static const double _jumpVelocity = -2 * _jumpHeight / _riseTime; // ≈-889
  static const double _fallMultiplier = 1.3; // 轻微不对称，下落不会太快
  static const double _coyoteTime = 0.18;
  static const double _jumpBuffer = 0.25;
  static const double _maxFallSpeed = 700;
  static const double _doubleJumpMultiplier = 0.8; // 二段跳力度

  Vector2 velocity = Vector2.zero();
  bool _isOnGround = true;
  double _coyoteTimer = 0;
  double _jumpBufferTimer = 0;
  double _runPhase = 0;
  bool _groundTouched = true;
  bool _canDoubleJump = false; // 二段跳可用标记
  bool _hasDoubleJumped = false; // 是否已用掉二段跳

  RunnerPlayer({required super.position}) : super(size: Vector2(60, 80), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    try {
      // 注意：Flame 的 Images 默认 prefix 就是 assets/images/，
      // 所以这里只传文件名，不能带 images/ 前缀，否则路径会变成
      // assets/images/images/runner_player.png 导致加载失败
      sprite = await Sprite.load('runner_player.png');
    } catch (_) {
      // PNG 加载失败时降级为纯色矩形，保证至少能看到角色形状
      sprite = null;
    }
    add(RectangleHitbox(
      size: Vector2(40, 60),
      position: Vector2(10, 20),
    ));
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      // 降级渲染：纯色矩形 + 简单眼睛
      final rect = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawRect(rect, Paint()..color = const Color(0xFFFF6B6B));
      canvas.drawCircle(Offset(size.x * 0.35, size.y * 0.3), 4,
          Paint()..color = Colors.white);
      canvas.drawCircle(Offset(size.x * 0.65, size.y * 0.3), 4,
          Paint()..color = Colors.white);
    }
  }

  void jump() {
    _jumpBufferTimer = _jumpBuffer;
    if (_isOnGround || _coyoteTimer > 0) {
      _doJump();
    } else if (_canDoubleJump && !_hasDoubleJumped) {
      // 空中二段跳（80% 力度），跳早了能补救
      _doDoubleJump();
    }
  }

  void _doJump() {
    velocity.y = _jumpVelocity;
    _isOnGround = false;
    _coyoteTimer = 0;
    _jumpBufferTimer = 0;
    _canDoubleJump = true;
    _hasDoubleJumped = false;
  }

  void _doDoubleJump() {
    velocity.y = _jumpVelocity * _doubleJumpMultiplier;
    _hasDoubleJumped = true;
    _jumpBufferTimer = 0;
  }

  void reset() {
    velocity = Vector2.zero();
    position = Vector2(110, RunnerGame.groundY);
    _isOnGround = true;
    _coyoteTimer = 0;
    _jumpBufferTimer = 0;
    _canDoubleJump = false;
    _hasDoubleJumped = false;
    scale = Vector2.all(1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    const groundY = RunnerGame.groundY;

    // Coyote time 衰减（不依赖 _isOnGround 重判，信任上一帧状态）
    if (!_isOnGround) {
      _coyoteTimer = max(0, _coyoteTimer - dt);
    } else {
      _coyoteTimer = _coyoteTime;
    }
    _jumpBufferTimer = max(0, _jumpBufferTimer - dt);

    // 先处理 buffer 起跳（jump() 可能设了 buffer）
    if (_isOnGround && _jumpBufferTimer > 0) {
      _doJump();
    }

    // 施加重力（跳起后 _isOnGround=false，不会被清零）
    if (!_isOnGround) {
      final g = velocity.y > 0 ? _gravity * _fallMultiplier : _gravity;
      velocity.y = min(_maxFallSpeed, velocity.y + g * dt);
    }

    // 更新位置
    position.y += velocity.y * dt;

    // 落地判定（位置更新之后才判断，避免覆盖 jump() 设的 _isOnGround=false）
    if (position.y >= groundY) {
      position.y = groundY;
      velocity.y = 0;
      _isOnGround = true;
      _canDoubleJump = false;
      _hasDoubleJumped = false;
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