import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'config/app_config.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 注入账号配置（从 --dart-define 环境变量读取）
  // 如果配置无效，将 fallback 到 Info.plist/AndroidManifest（已废弃）
  await AppConfig.inject();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DownloadStateManager(),
      child: MaterialApp(
        title: 'Polyv Media Player Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
