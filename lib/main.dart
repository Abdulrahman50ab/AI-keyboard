import 'package:flutter/material.dart';
// VibeKey AI App Entry Point
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/settings_provider.dart';
import 'providers/keyboard_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/keyboard/vibe_keyboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VibeKeyApp());
}

class VibeKeyApp extends StatelessWidget {
  const VibeKeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, KeyboardProvider>(
          create: (context) {
            final settings = Provider.of<SettingsProvider>(context, listen: false);
            return KeyboardProvider(settings.aiService, settings.giphyService);
          },
          update: (context, settings, previous) {
            final provider = previous ?? KeyboardProvider(settings.aiService, settings.giphyService);
            provider.updateTargetLanguages(settings.selectedLanguages);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'VibeKey AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme.copyWith(
          canvasColor: Colors.transparent,
          scaffoldBackgroundColor: Colors.transparent,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/keyboard': (context) => const Scaffold(
            backgroundColor: Colors.transparent,
            body: VibeKeyboard(),
          ),
        },
      ),
    );
  }
}