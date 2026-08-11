import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';

class LevelMapScreen extends StatelessWidget {
  final String grade;
  final String subject;
  const LevelMapScreen({super.key, required this.grade, required this.subject});

  @override
  Widget build(BuildContext context) {
    final gradeName = AppConstants.grades[grade] ?? grade;
    final subjectName = AppConstants.subjects[subject] ?? subject;
    final progressBox = Hive.box('progress');
    final key = '${grade}_$subject';
    final currentLevel = progressBox.get('${key}_level', defaultValue: 1);
    final levelStars = progressBox.get('${key}_stars', defaultValue: <int, int>{});

    return Scaffold(
      appBar: AppBar(
        title: Text('$gradeName · $subjectName'),
        backgroundColor: const Color(0xFF58CC02),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFF98FB98)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          itemCount: 10,
          itemBuilder: (context, index) {
            final level = index + 1;
            final isUnlocked = level <= currentLevel;
            final stars = (levelStars is Map) ? (levelStars[level] ?? 0) : 0;
            final isCompleted = stars > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: isUnlocked
                    ? () => context.push('/quiz/$grade/$subject/$level')
                    : null,
                child: Row(
                  children: [
                    // 关卡节点
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF58CC02)
                            : isUnlocked
                                ? const Color(0xFFFF9600)
                                : Colors.grey[400],
                        boxShadow: isUnlocked
                            ? [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))]
                            : [],
                      ),
                      child: Center(
                        child: isCompleted
                            ? Text('⭐' * stars, style: const TextStyle(fontSize: 14))
                            : isUnlocked
                                ? Text('$level', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                                : const Icon(Icons.lock, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 关卡信息
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUnlocked ? Colors.white.withOpacity(0.9) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '第$level关',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? Colors.black : Colors.grey,
                              ),
                            ),
                            if (isCompleted)
                              Text('已完成 ${'⭐' * stars}', style: const TextStyle(color: Color(0xFFFF9600)))
                            else if (isUnlocked)
                              const Text('点击开始', style: TextStyle(color: Color(0xFF58CC02)))
                            else
                              const Text('🔒 未解锁', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
