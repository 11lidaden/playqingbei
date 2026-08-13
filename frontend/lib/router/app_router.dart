import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/subject_screen.dart';
import '../screens/level_map_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/game_screen.dart';
import '../screens/result_screen.dart';
import '../screens/character_select_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/character-select',
        builder: (context, state) => const CharacterSelectScreen(),
      ),
      GoRoute(
        path: '/subject/:grade',
        builder: (context, state) => SubjectScreen(
          grade: state.pathParameters['grade']!,
        ),
      ),
      GoRoute(
        path: '/levels/:grade/:subject',
        builder: (context, state) => LevelMapScreen(
          grade: state.pathParameters['grade']!,
          subject: state.pathParameters['subject']!,
        ),
      ),
      GoRoute(
        path: '/quiz/:grade/:subject/:level',
        builder: (context, state) => QuizScreen(
          grade: state.pathParameters['grade']!,
          subject: state.pathParameters['subject']!,
          level: int.parse(state.pathParameters['level']!),
        ),
      ),
      GoRoute(
        path: '/game/:gameCode/:level',
        builder: (context, state) => GameScreen(
          gameCode: state.pathParameters['gameCode']!,
          level: int.parse(state.pathParameters['level'] ?? '1'),
        ),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResultScreen(
            passed: extra['passed'] as bool,
            stars: extra['stars'] as int,
            correctCount: extra['correctCount'] as int,
            totalCount: extra['totalCount'] as int,
            grade: extra['grade'] as String,
            subject: extra['subject'] as String,
            level: extra['level'] as int,
            gameCode: extra['gameCode'] as String,
          );
        },
      ),
    ],
  );
});
