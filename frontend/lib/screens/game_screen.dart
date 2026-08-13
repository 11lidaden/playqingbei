import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../games/runner_game.dart';

/// 游戏页
///
/// 按 gameCode 分发到对应游戏：
/// - runner: 跑酷大冒险（Flame 实现）
/// - 其他游戏（shooter/pipe/pinyin_train）：暂为占位页，后续逐个接入
class GameScreen extends StatefulWidget {
  final String gameCode;
  const GameScreen({super.key, required this.gameCode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  RunnerGame? _runnerGame;

  @override
  void dispose() {
    // 页面退出时释放游戏资源（取消计时器、解绑），避免泄漏
    _runnerGame?.onRemove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameCode == 'runner') {
      // 持有 game 实例，避免重建导致游戏状态丢失
      _runnerGame ??= RunnerGame(
        onFinished: (success) => context.pop(success),
      );
      final game = _runnerGame!;
      return Scaffold(
        body: SizedBox.expand(
          child: Listener(
            // 用 Listener 而非 GestureDetector：Listener 不参与手势 arena，
            // 直接在指针接触屏幕时回调，100% 触发，不受 GameWidget 内部
            // gesture recognizer 或 HUD overlay 手势竞争影响。
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (!game.isGameOver) {
                game.player.jump();
              }
            },
            child: GameWidget<RunnerGame>(
              game: game,
              overlayBuilderMap: {
                'HUD': (_, game) => _RunnerHud(game: game),
                'gameOver': (_, game) => _GameOverOverlay(game: game),
              },
              initialActiveOverlays: const ['HUD'],
            ),
          ),
        ),
      );
    }

    // 其他游戏占位页（后续接入）
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_gameEmoji(widget.gameCode), style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
              Text(
                _gameName(widget.gameCode),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                '游戏开发中，敬请期待...',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.pop(false),
                child: const Text('返回', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _gameEmoji(String code) {
    switch (code) {
      case 'runner':
        return '🏃';
      case 'shooter':
        return '🎯';
      case 'pipe':
        return '🔧';
      case 'pinyin_train':
        return '🚂';
      default:
        return '🎮';
    }
  }

  String _gameName(String code) {
    switch (code) {
      case 'runner':
        return '跑酷大冒险';
      case 'shooter':
        return '射击达人';
      case 'pipe':
        return '水管工';
      case 'pinyin_train':
        return '拼音火车';
      default:
        return '小游戏';
    }
  }
}

/// 跑酷 HUD：分数 + 距离
class _RunnerHud extends StatefulWidget {
  final RunnerGame game;
  const _RunnerHud({required this.game});

  @override
  State<_RunnerHud> createState() => _RunnerHudState();
}

class _RunnerHudState extends State<_RunnerHud> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 分数
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '${game.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 距离
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🏃 ${game.distanceMeters}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 游戏结束浮层
class _GameOverOverlay extends StatelessWidget {
  final RunnerGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.6),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😵', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                '哎呀，撞到障碍啦！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D5016)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(emoji: '⭐', value: '${game.score}', label: '金币'),
                  const SizedBox(width: 28),
                  _StatItem(emoji: '🏃', value: '${game.distanceMeters}m', label: '距离'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => game.restart(),
                  child: const Text('🔄 再跑一次', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2D5016),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF58CC02)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => game.quit(true),
                  child: const Text('返回关卡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatItem({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2D5016))),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}
