import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_controller.dart';

/// 玛丽式冒险 - 横版过关
///
/// 玩法：横屏，虚拟按键控制角色左右移动+跳跃。
/// - 地面/平台/砖块（顶出金币）/障碍（碰到失败）
/// - 收集够目标金币 + 到达终点旗 = 过关
/// - 中途 2-3 个「知识门」：碰到弹出题目，答对继续，答错退回上一个知识门
class MarioGame extends FlameGame with HasCollisionDetection implements GameController {
  /// 横屏逻辑分辨率
  static const double gameWidth = 854;
  static const double gameHeight = 480;

  /// 地面 Y
  static const double groundY = 420;

  /// 游戏结束回调
  final void Function(bool success)? onFinished;

  final int level;
  final Random _random = Random();

  /// 已收集金币
  int coins = 0;

  /// 是否游戏结束
  bool isGameOver = false;
  bool hasWon = false;

  /// 知识门题目（进入关卡时由外部注入，或游戏内拉取）
  List<Map<String, dynamic>> gateQuestions = [];

  /// 当前知识门索引（进度保留：答错退回上一个）
  int _gateIndex = 0;

  /// 上一个知识门的 X 坐标（答错退回这里）
  double _lastGateX = 60;

  late final MarioPlayer player;

  /// 控制状态（虚拟按键设置）
  bool inputLeft = false;
  bool inputRight = false;

  /// 过关所需金币 = 8 + 关卡×2
  @override
  int get targetCoins => 8 + level * 2;

  /// 渐进式难度：剩余生命数（低关5条，高关3条）
  int lives = 5;
  int get _maxLives => level <= 3 ? 5 : 3;

  /// 渐进式难度：移动速度（低关慢，高关快）
  double get moveSpeed => level <= 3 ? 160 : (level <= 7 ? 190 : 220);

  /// 渐进式难度：知识门数量（低关2个，高关3个）
  int get gateCount => level <= 3 ? 2 : 3;

  /// 渐进式难度：答错是否给二次机会（低中关给，高关直接退）
  bool get _secondChance => level <= 7;

  /// HUD 副信息（生命数 + 知识门进度）
  @override
  String get statLabel => '生命';
  @override
  String get statValue => '$lives';

  MarioGame({this.onFinished, this.level = 1});

  @override
  Future<void> onLoad() async {
    lives = _maxLives;
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(gameWidth, gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // 背景
    await add(_MarioBackground());

    // 地面
    await add(_Ground());

    // 平台
    await _buildLevelPlatforms();

    // 玩家
    player = MarioPlayer(position: Vector2(60, groundY), moveSpeed: moveSpeed);
    await add(player);

    // 终点旗（每关末尾）
    final flag = MarioFlag(position: Vector2(gameWidth * 2.2, groundY));
    await add(flag);

    // 知识门（2-3 个，分布在关卡中途）
    for (var i = 0; i < gateCount; i++) {
      final gate = KnowledgeGate(
        position: Vector2(gameWidth * (0.7 + i * 0.7), groundY),
        gateIndex: i,
        onReach: _onGateReached,
      );
      await add(gate);
    }
  }

  /// 平台布局（渐进式：低关少/宽/低，高关多/窄/高）
  Future<void> _buildLevelPlatforms() async {
    final platformCount = level <= 3 ? 3 : (level <= 7 ? 4 : 5);
    for (var i = 0; i < platformCount; i++) {
      // 高关卡平台更高、更分散
      final spacing = level <= 3 ? 0.55 : (level <= 7 ? 0.45 : 0.38);
      final heightStep = level <= 3 ? 35 : (level <= 7 ? 45 : 60);
      final x = gameWidth * (0.4 + i * spacing) + (i % 2 == 0 ? 30 : 0);
      final y = groundY - 50 - (i % 3) * heightStep;
      final platform = SpritePlatform(
        position: Vector2(x, y),
        wide: level <= 3,
      );
      await add(platform);
    }

    // 砖块（含金币，顶出）
    for (var i = 0; i < platformCount + 2; i++) {
      final x = gameWidth * (0.3 + i * 0.4) + 20;
      final y = groundY - 120;
      final brick = BrickBlock(
        position: Vector2(x, y),
        onHit: _onBrickHit,
      );
      await add(brick);
    }
  }

  void _onBrickHit() {
    if (!isGameOver) {
      coins += 1;
      _checkWin();
    }
  }

  void _onGateReached(KnowledgeGate gate) {
    if (isGameOver) return;
    // 已经过了的知识门不重复触发
    if (gate.gateIndex < _gateIndex) return;
    if (gate.gateIndex > _gateIndex) return; // 只能依次通过

    // 记录上一个知识门位置（答错退回）
    _lastGateX = gate.position.x - 40;
    _gateIndex = gate.gateIndex + 1; // 通过

    // 弹出题目（由 GameScreen 处理，触发 overlay）
    if (gateQuestions.isNotEmpty) {
      final q = gateQuestions[_gateIndex % gateQuestions.length];
      _showQuestion(q, gate);
    }
  }

  void _showQuestion(Map<String, dynamic> q, KnowledgeGate gate) {
    // 暂停游戏并通知外部（GameScreen 弹题）
    pauseEngine();
    _currentGate = gate;
    _currentQuestion = q;
    overlays.add('knowledgeGate');
  }

  KnowledgeGate? _currentGate;
  Map<String, dynamic>? _currentQuestion;

  /// 外部调用：提交知识门答案（true=答对继续，false=答错退回）
  void submitGateAnswer(bool correct) {
    if (correct) {
      // 答对：继续前进（已经前进）
      overlays.remove('knowledgeGate');
      resumeEngine();
    } else {
      // 答错：退回上一个知识门位置
      player.position = Vector2(_lastGateX, groundY);
      _gateIndex = max(0, _gateIndex - 1);
      overlays.remove('knowledgeGate');
      resumeEngine();
    }
    _currentGate = null;
    _currentQuestion = null;
  }

  /// 获取当前知识门题目
  Map<String, dynamic>? get currentQuestion => _currentQuestion;

  /// 外部（虚拟按键/Listener）调用：跳跃
  void doJump() {
    if (!isGameOver) {
      player.jump();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // 玩家移动（根据虚拟按键状态）
    player.setHorizontalInput(inputLeft, inputRight);

    // 相机跟随玩家（限制在关卡范围内）
    final camX = player.position.x - gameWidth * 0.35;
    camera.viewfinder.position = Vector2(max(0, camX), 0);

    // 检查是否到达终点
    if (player.position.x >= gameWidth * 2.2) {
      _onFinish();
    }

    // 检查掉出地图
    if (player.position.y > gameHeight + 50) {
      _onFall();
    }

    // 检测知识门碰撞
    for (final gate in children.whereType<KnowledgeGate>()) {
      if (!gate.passed &&
          gate.gateIndex >= _gateIndex &&
          (player.position - gate.position).length < 60) {
        _onGateReached(gate);
      }
    }
  }

  void _onFinish() {
    if (isGameOver) return;
    if (coins >= targetCoins) {
      isGameOver = true;
      hasWon = true;
      pauseEngine();
      overlays.add('gameWin');
    } else {
      // 金币不够，提示继续收集
      _showToast('金币还不够，继续收集吧！');
    }
  }

  void _onFall() {
    if (isGameOver) return;
    // 渐进式：掉坑扣命，命扣完才失败
    lives -= 1;
    if (lives <= 0) {
      isGameOver = true;
      hasWon = false;
      pauseEngine();
      overlays.add('gameOver');
    } else {
      // 回到上一个安全位置（知识门或起点）
      player.position = Vector2(max(60, _lastGateX), groundY);
      player.reset();
    }
  }

  void _checkWin() {
    if (coins >= targetCoins && player.position.x >= gameWidth * 2.2) {
      isGameOver = true;
      hasWon = true;
      pauseEngine();
      overlays.add('gameWin');
    }
  }

  void _showToast(String msg) {
    debugPrint('[Mario] $msg');
  }

  /// 重新开始
  @override
  void restart() {
    coins = 0;
    _gateIndex = 0;
    _lastGateX = 60;
    isGameOver = false;
    hasWon = false;

    player.reset();

    overlays.remove('gameOver');
    overlays.remove('gameWin');
    resumeEngine();
  }

  /// 返回上一页
  @override
  void quit(bool success) {
    onFinished?.call(success);
  }
}

/// 玩家组件
class MarioPlayer extends SpriteComponent with CollisionCallbacks {
  static const double _jumpVelocity = -380;
  static const double _gravity = 900;
  static const double _maxFall = 600;
  final double _moveSpeed;

  Vector2 velocity = Vector2.zero();
  bool _isOnGround = true;
  bool _canDoubleJump = false;
  bool _hasDoubleJumped = false;

  MarioPlayer({required super.position, required double moveSpeed})
      : _moveSpeed = moveSpeed,
        super(size: Vector2(56, 72), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    try {
      sprite = await Sprite.load('mario_player.png');
    } catch (_) {
      sprite = null;
    }
    add(RectangleHitbox(size: Vector2(40, 60), position: Vector2(8, 12)));
  }

  void jump() {
    if (_isOnGround) {
      velocity.y = _jumpVelocity;
      _isOnGround = false;
      _canDoubleJump = true;
      _hasDoubleJumped = false;
    } else if (_canDoubleJump && !_hasDoubleJumped) {
      velocity.y = _jumpVelocity * 0.8;
      _hasDoubleJumped = true;
    }
  }

  void setHorizontalInput(bool left, bool right) {
    if (left && !right) {
      velocity.x = -_moveSpeed;
    } else if (right && !left) {
      velocity.x = _moveSpeed;
    } else {
      velocity.x = 0;
    }
  }

  void reset() {
    velocity = Vector2.zero();
    position = Vector2(60, MarioGame.groundY);
    _isOnGround = true;
    _canDoubleJump = false;
    _hasDoubleJumped = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    const groundY = MarioGame.groundY;

    // 重力
    if (!_isOnGround) {
      velocity.y = min(_maxFall, velocity.y + _gravity * dt);
    }

    // 移动
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // 落地
    if (position.y >= groundY) {
      position.y = groundY;
      velocity.y = 0;
      _isOnGround = true;
      _canDoubleJump = false;
      _hasDoubleJumped = false;
    }

    // 限制左边界
    if (position.x < 30) position.x = 30;
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      // 降级：红色小人
      final r = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawRect(r, Paint()..color = const Color(0xFFE12828));
      canvas.drawRect(Rect.fromLTWH(0, size.y * 0.35, size.x, size.y * 0.3),
          Paint()..color = const Color(0xFF3C78E6));
    }
  }
}

/// 地面
class _Ground extends PositionComponent {
  _Ground()
      : super(
          position: Vector2(0, MarioGame.groundY),
          size: Vector2(MarioGame.gameWidth * 3, MarioGame.gameHeight - MarioGame.groundY),
        );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF8B5A2B),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 12),
      Paint()..color = const Color(0xFF58CC02),
    );
  }
}

/// 背景：蓝天+云+远山
class _MarioBackground extends PositionComponent {
  _MarioBackground()
      : super(position: Vector2.zero(), size: Vector2(MarioGame.gameWidth * 3, MarioGame.gameHeight));

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF70C5FF), Color(0xFFB8E6F2), Color(0xFFFFF8E1)],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // 云
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.9);
    for (var i = 0; i < 8; i++) {
      final x = i * 340.0 + 40;
      canvas.drawOval(Rect.fromLTWH(x, 60, 80, 36), cloudPaint);
      canvas.drawOval(Rect.fromLTWH(x + 30, 45, 60, 40), cloudPaint);
    }
  }
}

/// 平台
class SpritePlatform extends SpriteComponent with CollisionCallbacks {
  SpritePlatform({required super.position, bool wide = true})
      : super(
          size: Vector2(wide ? 180 : 120, 32),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    try {
      sprite = await Sprite.load('mario_platform.png');
    } catch (_) {
      sprite = null;
    }
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF4EC04E),
      );
    }
  }
}

/// 砖块（顶出金币）
class BrickBlock extends SpriteComponent with CollisionCallbacks {
  final VoidCallback onHit;
  bool _hit = false;

  BrickBlock({required super.position, required this.onHit})
      : super(size: Vector2(64, 32), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    try {
      sprite = await Sprite.load('mario_brick.png');
    } catch (_) {
      sprite = null;
    }
    add(RectangleHitbox());
  }

  void hit() {
    if (_hit) return;
    _hit = true;
    onHit();
    // 弹起动画
    add(SequenceEffect([
      MoveEffect.by(Vector2(0, -12), EffectController(duration: 0.1)),
      MoveEffect.by(Vector2(0, 12), EffectController(duration: 0.1)),
    ]));
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFFB46432),
      );
    }
  }
}

/// 知识门
class KnowledgeGate extends SpriteComponent {
  final int gateIndex;
  final void Function(KnowledgeGate) onReach;
  bool passed = false;

  KnowledgeGate({
    required super.position,
    required this.gateIndex,
    required this.onReach,
  }) : super(size: Vector2(80, 100), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    try {
      sprite = await Sprite.load('mario_knowledge_gate.png');
    } catch (_) {
      sprite = null;
    }
  }

  void markPassed() {
    passed = true;
  }

  @override
  void render(Canvas canvas) {
    if (sprite != null) {
      super.render(canvas);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF964ED0),
      );
    }
  }
}

/// 终点旗
class MarioFlag extends SpriteComponent {
  MarioFlag({required super.position})
      : super(size: Vector2(32, 96), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    try {
      sprite = await Sprite.load('mario_flag.png');
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
        Paint()..color = const Color(0xFF2AA05C),
      );
    }
  }
}
