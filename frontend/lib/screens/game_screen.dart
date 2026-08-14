import 'dart:async';

import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../games/game_controller.dart';
import '../games/runner_game.dart';
import '../games/shooter_game.dart';

/// 游戏页
///
/// 按 gameCode 分发到对应游戏：
/// - runner: 跑酷大冒险（Flame 实现）
/// - shooter: 射击达人（Flame 实现）
/// - 其他游戏（pipe/pinyin_train）：暂为占位页，后续逐个接入
class GameScreen extends StatefulWidget {
  final String gameCode;
  final int level;
  const GameScreen({super.key, required this.gameCode, this.level = 1});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  RunnerGame? _runnerGame;
  ShooterGame? _shooterGame;

  @override
  void dispose() {
    // 页面退出时释放游戏资源，避免泄漏
    _runnerGame?.onRemove();
    _shooterGame?.onRemove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameCode == 'runner') {
      // 持有 game 实例，避免重建导致游戏状态丢失
      _runnerGame ??= RunnerGame(
        onFinished: (success) => context.pop(success),
        level: widget.level,
      );
      final game = _runnerGame!;
      return Scaffold(
        body: SizedBox.expand(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (!game.isGameOver) {
                game.player.jump();
              }
            },
            child: GameWidget<RunnerGame>(
              game: game,
              overlayBuilderMap: {
                'HUD': (_, g) => _RunnerHud(game: g),
                'gameOver': (_, g) => _GameOverOverlay(game: g),
                'gameWin': (_, g) => _GameWinOverlay(game: g),
              },
              initialActiveOverlays: const ['HUD'],
            ),
          ),
        ),
      );
    }

    if (widget.gameCode == 'shooter') {
      _shooterGame ??= ShooterGame(
        onFinished: (success) => context.pop(success),
        level: widget.level,
      );
      final game = _shooterGame!;
      return Scaffold(
        body: SizedBox.expand(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              game.handleTap(e.localPosition.toVector2());
            },
            child: GameWidget<ShooterGame>(
              game: game,
              overlayBuilderMap: {
                'HUD': (_, g) => _RunnerHud(game: g),
                'gameOver': (_, g) => _GameOverOverlay(game: g),
                'gameWin': (_, g) => _GameWinOverlay(game: g),
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

/// 跑酷 HUD：金币进度 + 距离/剩余机会
class _RunnerHud extends StatefulWidget {
  final GameController game;
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            // 金币进度
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    '${game.coins}/${game.targetCoins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 副信息（距离/剩余机会）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${game.statLabel} ${game.statValue}',
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
          // 调试信息（诊断用，正常不显示）
          if (game.debugText.isNotEmpty)
            Positioned(
              left: 8,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  game.debugText,
                  style: const TextStyle(color: Colors.yellow, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 游戏结束浮层（失败）
class _GameOverOverlay extends StatelessWidget {
  final GameController game;
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
                '哎呀，差一点啦！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D5016)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(emoji: '🪙', value: '${game.coins}/${game.targetCoins}', label: '金币'),
                  const SizedBox(width: 28),
                  _StatItem(emoji: '❌', value: '${game.statValue}', label: game.statLabel),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '还差一点就过关啦，再试一次吧！',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  child: const Text('🔄 再试一次', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  onPressed: () => game.quit(false),
                  child: const Text('📝 重新做题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 过关浮层：收集够目标金币
class _GameWinOverlay extends StatelessWidget {
  final GameController game;
  const _GameWinOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.55),
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
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                '太棒了，过关啦！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D5016)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatItem(emoji: '🪙', value: '${game.coins}/${game.targetCoins}', label: '金币'),
                  const SizedBox(width: 28),
                  _StatItem(emoji: '🎯', value: '${game.statValue}', label: game.statLabel),
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
                  onPressed: () => game.quit(true),
                  child: const Text('🎊 完成关卡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  onPressed: () => game.restart(),
                  child: const Text('🔄 再玩一次', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
