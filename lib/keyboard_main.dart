import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/keyboard_provider.dart';

@pragma('vm:entry-point')
void main() {
  // Add this to ensure the engine wakes up properly
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KeyboardApp());
}

class KeyboardApp extends StatelessWidget {
  const KeyboardApp({super.key});

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
        title: 'AI Keyboard',
        theme: ThemeData(
          brightness: Brightness.dark,
        ),
        // Important: Remove scaffold backgrounds if inside IME
        home: const Scaffold(
          backgroundColor: Color(0xFF1E1E2D),
          body: CustomKeyboard(),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class CustomKeyboard extends StatefulWidget {
  const CustomKeyboard({super.key});

  @override
  State<CustomKeyboard> createState() => _CustomKeyboardState();
}

class _CustomKeyboardState extends State<CustomKeyboard> {
  static const platform = MethodChannel('custom_keyboard/input');
  bool _isShiftPressed = false;
  bool _isCapsLock = false;
  bool _isSymbols = false;

  final List<List<String>> _qwertyLayout = [
    ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
  ];

  final List<List<String>> _symbolsLayout = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['-', '/', ':', ';', '(', ')', '\$', '&', '@', '"'],
    ['.', ',', '?', '!', "'", '#', '%', '^', '*', '+'],
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAIToolbar(provider),
        if (provider.isLoading)
          const LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            minHeight: 2,
          ),
        _buildKeyboardUI(provider),
      ],
    );
  }

  Widget _buildAIToolbar(KeyboardProvider provider) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildToolbarButton(Icons.spellcheck, 'Fix Grammar',
              () => _handleAIAction(provider, () => provider.grammarFix())),
          _buildToolbarButton(
              Icons.translate,
              'Urdu',
              () =>
                  _handleAIAction(provider, () => provider.translate('Urdu'))),
          _buildToolbarButton(
              Icons.auto_awesome,
              'Magic',
              () => _handleAIAction(
                  provider, () => provider.aiAssist('Improve'))),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: Colors.blueAccent),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        backgroundColor: Colors.white10,
      ),
    );
  }

  Future<void> _handleAIAction(
      KeyboardProvider provider, Future<void> Function() action) async {
    final text = await platform.invokeMethod<String>('getTextBeforeCursor');
    if (text != null && text.isNotEmpty) {
      provider.insertText(text);
      await action();
      await platform
          .invokeMethod('replaceText', {'text': provider.currentText});
    }
  }

  Widget _buildKeyboardUI(KeyboardProvider provider) {
    final layout = _isSymbols ? _symbolsLayout : _qwertyLayout;
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          ...layout.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((key) => _buildKey(key)).toList(),
                ),
              )),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildSpecialKey(
                label: _isSymbols ? 'ABC' : '?123',
                onPressed: () => setState(() => _isSymbols = !_isSymbols),
                flex: 2,
              ),
              _buildSpecialKey(
                label: 'Space',
                onPressed: () => _insertText(' '),
                flex: 5,
              ),
              _buildSpecialKey(
                icon: Icons.backspace_outlined,
                onPressed: _deleteText,
                flex: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String text) {
    String display =
        (_isShiftPressed || _isCapsLock) ? text.toUpperCase() : text;
    return Expanded(
      child: GestureDetector(
        onTap: () => _insertText(display),
        child: Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
              child: Text(display, style: const TextStyle(fontSize: 18))),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(
      {String? label,
      IconData? icon,
      required VoidCallback onPressed,
      int flex = 1}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 20)
                : Text(label!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _insertText(String text) =>
      platform.invokeMethod('insertText', {'text': text});
  void _deleteText() => platform.invokeMethod('deleteText');
}
