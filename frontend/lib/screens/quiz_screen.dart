import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../config/constants.dart';

class QuizScreen extends StatefulWidget {
  final String grade;
  final String subject;
  final int level;
  const QuizScreen({super.key, required this.grade, required this.subject, required this.level});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _loading = true;
  List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final dio = Dio();
      final resp = await dio.get('${AppConstants.baseUrl}/questions', queryParameters: {
        'grade': widget.grade,
        'subject': widget.subject,
        'level': widget.level,
      });
      setState(() {
        _questions = resp.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载题目失败，请检查网络')),
        );
      }
    }
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });

    final q = _questions[_currentIndex];
    final correct = answer == q['answer']?.toString()?.toUpperCase();
    if (correct) _correctCount++;

    _answers.add({
      'questionId': q['id'],
      'userAnswer': answer,
    });

    // 显示结果后自动跳转
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  void _finishQuiz() {
    // 计算结果
    final passRate = widget.grade == 'kindergarten' ? 3 : widget.grade == 'grade-5-6' ? 5 : 4;
    final passed = _correctCount >= passRate;
    int stars = 0;
    if (passed) {
      if (_correctCount >= 5) stars = 3;
      else if (_correctCount >= 4) stars = 2;
      else stars = 1;
    }

    // 确定游戏类型
    final gameCycle = ['runner', 'shooter', 'pipe', 'pinyin_train'];
    String gameCode = gameCycle[(widget.level - 1) % gameCycle.length];

    context.push('/result', extra: {
      'passed': passed,
      'stars': stars,
      'correctCount': _correctCount,
      'totalCount': _questions.length,
      'grade': widget.grade,
      'subject': widget.subject,
      'level': widget.level,
      'gameCode': gameCode,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('玩出清北')),
        body: const Center(child: Text('暂无题目', style: TextStyle(fontSize: 20))),
      );
    }

    final q = _questions[_currentIndex];
    final options = (q['options'] as List).cast<String>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 进度条
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 30),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _questions.length,
                          minHeight: 16,
                          backgroundColor: Colors.white.withOpacity(0.5),
                          color: const Color(0xFF58CC02),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_currentIndex + 1}/${_questions.length}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // 题目
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
                  ),
                  child: Text(
                    q['content'] ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                // 选项
                ...List.generate(options.length, (i) {
                  final optLabel = String.fromCharCode(65 + i); // A/B/C/D
                  final isSelected = _selectedAnswer == optLabel;
                  final isCorrect = optLabel == (q['answer'] ?? '').toString().toUpperCase();
                  Color bgColor = Colors.white;
                  if (_answered) {
                    if (isCorrect) bgColor = const Color(0xFF58CC02);
                    else if (isSelected) bgColor = const Color(0xFFFF4B4B);
                  } else if (isSelected) {
                    bgColor = const Color(0xFFE0E0E0);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bgColor,
                          foregroundColor: _answered && (isCorrect || isSelected)
                              ? Colors.white
                              : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        onPressed: _answered ? null : () => _selectAnswer(optLabel),
                        child: Text('$optLabel. ${options[i]}'),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // 正确/错误反馈
                if (_answered)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedAnswer ==
                              (q['answer'] ?? '').toString().toUpperCase()
                          ? const Color(0xFF58CC02).withOpacity(0.1)
                          : const Color(0xFFFF4B4B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _selectedAnswer ==
                              (q['answer'] ?? '').toString().toUpperCase()
                          ? '✅ 太棒了！'
                          : '❌ 答案是 ${q['answer']}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
