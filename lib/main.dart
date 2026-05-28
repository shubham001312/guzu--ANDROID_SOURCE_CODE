import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'theme/app_theme.dart';
import 'providers/tab_provider.dart';
import 'providers/browser_provider.dart';
import 'providers/bookmark_provider.dart';
import 'providers/history_provider.dart';
import 'providers/download_provider.dart';
import 'screens/browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const GuzuApp());
}

class GuzuApp extends StatelessWidget {
  const GuzuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabProvider()..init()),
        ChangeNotifierProvider(create: (_) => BrowserProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()..load()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()..load()),
      ],
      child: MaterialApp(
        title: 'GUZU',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const BrowserScreen(),
      ),
    );
  }
}
