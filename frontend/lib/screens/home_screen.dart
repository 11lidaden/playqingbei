import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';
import '../widgets/animated_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileBox = Hive.box('profile');
    final selectedChar = profileBox.get('character', defaultValue: 'cat');
    final charInfo = AppConstants.characters.firstWhere(
      (c) => c['id'] == selectedChar,
      orElse: () => AppConstants.characters[0],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF98FB98)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              const Text(
                '🎮 玩出清北',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D5016),
                  shadows: [
                    Shadow(color: Colors.white, blurRadius: 10, offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '边玩边学，通关上清北！',
                style: TextStyle(fontSize: 18, color: Color(0xFF4A7C2E)),
              ),
              const SizedBox(height: 40),
              // 角色展示
              Text(
                charInfo['emoji']!,
                style: const TextStyle(fontSize: 80),
              ),
              Text(
                charInfo['name']!,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // 主按钮
              AnimatedButton(
                text: '🚀 开始冒险',
                color: const Color(0xFF58CC02),
                onPressed: () {
                  // 检查是否选过角色
                  if (profileBox.get('character') == null) {
                    context.push('/character-select');
                  } else {
                    _showGradeSelector(context);
                  }
                },
              ),
              const SizedBox(height: 16),
              AnimatedButton(
                text: '🐾 换个角色',
                color: const Color(0xFFCE82FF),
                onPressed: () => context.push('/character-select'),
              ),
              const Spacer(),
              // 每日任务入口
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statBadge('🪙', '金币', '${profileBox.get('coins', defaultValue: 0)}'),
                    _statBadge('⭐', '关卡', '${profileBox.get('totalStars', defaultValue: 0)}'),
                    _statBadge('🔥', '连胜', '${profileBox.get('streak', defaultValue: 0)}天'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGradeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择年级', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...AppConstants.grades.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/subject/${e.key}');
                  },
                  child: Text(e.value),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
