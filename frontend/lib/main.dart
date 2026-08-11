import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('progress');   // 闯关进度
  await Hive.openBox('profile');    // 角色、金币
  await Hive.openBox('daily');      // 每日任务
  runApp(const ProviderScope(child: WanChuQingBeiApp()));
}

class WanChuQingBeiApp extends ConsumerWidget {
  const WanChuQingBeiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '玩出清北',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF58CC02),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.notoSansScTextTheme(),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
