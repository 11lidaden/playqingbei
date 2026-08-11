import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/constants.dart';
import '../widgets/animated_button.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  String _selected = 'cat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8D5F5), Color(0xFFB5EAD7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                '🐾 选一个伙伴吧！',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text('它会陪你一起冒险哦', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: AppConstants.characters.map((char) {
                  final isSelected = _selected == char['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = char['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF58CC02) : Colors.transparent,
                          width: 4,
                        ),
                        boxShadow: isSelected
                            ? [const BoxShadow(color: Color(0xFF58CC02), blurRadius: 20)]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Text(char['emoji']!, style: TextStyle(fontSize: isSelected ? 70 : 60)),
                          const SizedBox(height: 8),
                          Text(
                            char['name']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              AnimatedButton(
                text: '✅ 就选你了！',
                color: const Color(0xFF58CC02),
                onPressed: () {
                  Hive.box('profile').put('character', _selected);
                  context.go('/');
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
