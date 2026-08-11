import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends StatelessWidget {
  final String gameCode;
  const GameScreen({super.key, required this.gameCode});

  @override
  Widget build(BuildContext context) {
    // TODO: 接入Flame游戏引擎，目前用占位UI
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
              Text(
                _gameEmoji(gameCode),
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              Text(
                _gameName(gameCode),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                '游戏加载中...',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Color(0xFF58CC02)),
              const SizedBox(height: 60),
              // 临时：模拟游戏成功/失败
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.pop(true),  // 游戏成功
                    child: const Text('✅ 游戏成功', style: TextStyle(fontSize: 18)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4B4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.pop(false),  // 游戏失败
                    child: const Text('❌ 游戏失败', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _gameEmoji(String code) {
    switch (code) {
      case 'runner': return '🏃';
      case 'shooter': return '🎯';
      case 'pipe': return '🔧';
      case 'pinyin_train': return '🚂';
      default: return '🎮';
    }
  }

  String _gameName(String code) {
    switch (code) {
      case 'runner': return '跑酷大冒险';
      case 'shooter': return '射击达人';
      case 'pipe': return '水管工';
      case 'pinyin_train': return '拼音火车';
      default: return '小游戏';
    }
  }
}
