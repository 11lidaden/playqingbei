import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';

class SubjectScreen extends StatelessWidget {
  final String grade;
  const SubjectScreen({super.key, required this.grade});

  @override
  Widget build(BuildContext context) {
    final gradeName = AppConstants.grades[grade] ?? grade;

    return Scaffold(
      appBar: AppBar(
        title: Text(gradeName),
        backgroundColor: const Color(0xFF58CC02),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F8FF), Color(0xFFE8F5E9)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择科目',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ...AppConstants.subjects.entries.map((e) {
                final color = Color(AppConstants.subjectColors[e.key] ?? 0xFF58CC02);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => context.push('/levels/$grade/${e.key}'),
                      child: Text(e.value),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
