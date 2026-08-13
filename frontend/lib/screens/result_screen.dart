import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/animated_button.dart';

class ResultScreen extends StatefulWidget {
  final bool passed;
  final int stars;
  final int correctCount;
  final int totalCount;
  final String grade;
  final String subject;
  final int level;
  final String gameCode;

  const ResultScreen({
    super.key,
    required this.passed,
    required this.stars,
    required this.correctCount,
    required this.totalCount,
    required this.grade,
    required this.subject,
    required this.level,
    required this.gameCode,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    // 注意：不再在此保存进度。
    // 现在过关 = 做题达标 + 游戏里收集够金币，进度在游戏过关后（_saveProgress）才保存。
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.passed
                ? [const Color(0xFF58CC02), const Color(0xFF2D5016)]
                : [const Color(0xFFFF6B6B), const Color(0xFFC0392B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.passed ? '🎉' : '😢',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              Text(
                widget.passed ? '太棒了！' : '再试一次吧！',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                '答对 ${widget.correctCount} / ${widget.totalCount} 题',
                style: const TextStyle(fontSize: 22, color: Colors.white70),
              ),
              if (widget.passed) ...[
                const SizedBox(height: 16),
                Text(
                  '⭐' * widget.stars,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '去游戏里收集 ${8 + widget.level * 2} 枚金币即可过关！',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
              const SizedBox(height: 60),
              if (widget.passed)
                AnimatedButton(
                  text: '🎮 开始游戏！',
                  color: const Color(0xFFFF9600),
                  onPressed: () async {
                    // 进入游戏：收集够目标金币才算完成本关（目标随关卡递增）
                    final gameResult = await context.push<bool>(
                      '/game/${widget.gameCode}/${widget.level}',
                    );
                    if (gameResult == true) {
                      // 游戏过关 → 保存进度、发放奖励、过关庆祝
                      if (context.mounted) {
                        _saveProgress();
                        _showLevelComplete(context);
                      }
                    } else {
                      // 游戏失败（没收集够金币）→ 重新做题，巩固后再拿游戏机会
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('没收集够金币，重新做题后再试！')),
                        );
                        context.go('/quiz/${widget.grade}/${widget.subject}/${widget.level}');
                      }
                    }
                  },
                )
              else
                AnimatedButton(
                  text: '📝 重新答题',
                  color: const Color(0xFFFF9600),
                  onPressed: () => context.go('/quiz/${widget.grade}/${widget.subject}/${widget.level}'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/levels/${widget.grade}/${widget.subject}'),
                child: const Text('返回关卡', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProgress() {
    final progressBox = Hive.box('progress');
    final profileBox = Hive.box('profile');
    final key = '${widget.grade}_${widget.subject}';

    if (widget.passed) {
      // 更新关卡进度
      final currentLevel = progressBox.get('${key}_level', defaultValue: 1);
      if (widget.level >= currentLevel) {
        progressBox.put('${key}_level', widget.level + 1);
      }

      // 保存星级
      final starsMap = Map<int, int>.from(progressBox.get('${key}_stars', defaultValue: {}));
      final existingStars = starsMap[widget.level] ?? 0;
      if (widget.stars > existingStars) {
        starsMap[widget.level] = widget.stars;
        progressBox.put('${key}_stars', starsMap);
      }

      // 加金币
      final coins = profileBox.get('coins', defaultValue: 0);
      profileBox.put('coins', coins + widget.stars * 10);

      // 更新总星数
      int totalStars = 0;
      for (final v in starsMap.values) {
        totalStars += v;
      }
      profileBox.put('totalStars', totalStars);
    }
  }

  void _showLevelComplete(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text('过关！', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('第${widget.level}关 完成', style: const TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/levels/${widget.grade}/${widget.subject}');
              },
              child: const Text('继续冒险', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
