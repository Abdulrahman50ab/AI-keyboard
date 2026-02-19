import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide KeyboardKey;
import 'package:provider/provider.dart';

import '../../providers/keyboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/keyboard_constants.dart';
import 'ai_features.dart';
import 'ai_toolbar.dart';
import 'apps_menu.dart';
import 'keyboard_key.dart';
import 'keyboard_pickers.dart';
import '../../core/keyboard_theme.dart';
import 'voice_input_dialog.dart';

class VibeKeyboard extends StatefulWidget {
  const VibeKeyboard({super.key});

  @override
  State<VibeKeyboard> createState() => _VibeKeyboardState();
}

class _VibeKeyboardState extends State<VibeKeyboard> {
  final platform = const MethodChannel('custom_keyboard/input');
  bool _isShiftPressed = false;
  bool _isCapsLock = false;
  bool _isSymbols = false;
  int _symbolsPageIndex = 0; // 0 for Page 1 (123...), 1 for Page 2 (~`|...)
  DateTime? _lastShiftTap;
  bool _isEmojiPickerVisible = false;
  String _currentLanguage = 'English';
  int _languageIndex = 0;
  String _inputAction = 'newline'; // Default action
  VoiceInputDialog? _voiceDialog;

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethodCall);
    // Refresh settings immediately from native
    Provider.of<SettingsProvider>(context, listen: false).refreshSettings();
    // Refresh clipboard on startup
    _refreshClipboard();
  }

  void _refreshClipboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<KeyboardProvider>(context, listen: false).refreshClipboardHistory(platform);
      }
    });
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'updateAction') {
      final action = call.arguments['action'] as String;
      debugPrint("VibeKeyboard: Received input action update: $action");
      setState(() {
        _inputAction = action;
      });
    } else if (call.method == 'resetState') {
      debugPrint("VibeKeyboard: Resetting state to initial");
      _resetToInitialState();
    } else if (call.method == 'updateSelection') {
      final text = call.arguments['text'] as String;
      Provider.of<KeyboardProvider>(context, listen: false).updateSelection(text);
    } else if (call.method == 'onClipboardChanged') {
      final text = call.arguments['text'] as String;
      debugPrint("VibeKeyboard: Received clipboard update from Native: '$text'");
      Provider.of<KeyboardProvider>(context, listen: false).updateClipboardHistory(text);
    } else if (call.method == 'onVoiceReady') {
      debugPrint("VibeKeyboard: Voice ready for speech");
      final provider = Provider.of<KeyboardProvider>(context, listen: false);
      provider.setVoiceState(VoiceState.ready);
    } else if (call.method == 'onVoiceListening') {
      debugPrint("VibeKeyboard: Voice listening started");
      final provider = Provider.of<KeyboardProvider>(context, listen: false);
      provider.setVoiceState(VoiceState.listening);
    } else if (call.method == 'onVoiceProcessing') {
      debugPrint("VibeKeyboard: Voice processing started");
      final provider = Provider.of<KeyboardProvider>(context, listen: false);
      provider.setVoiceState(VoiceState.processing);
    } else if (call.method == 'onVoiceResult') {
      final text = call.arguments['text'] as String;
      debugPrint("VibeKeyboard: Voice recognition result: '$text'");
      final provider = Provider.of<KeyboardProvider>(context, listen: false);
      provider.setVoiceState(VoiceState.done);
      provider.updatePartialTranscription(text);
      // Close dialog after brief delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && provider.voiceState == VoiceState.done) {
          provider.setMode(KeyboardMode.normal);
        }
      });
    } else if (call.method == 'onVoiceError') {
      final error = call.arguments['error'] as String;
      debugPrint("VibeKeyboard: Voice recognition error: $error");
      final provider = Provider.of<KeyboardProvider>(context, listen: false);
      provider.setVoiceState(VoiceState.error);
      provider.showInfo(error);
      // Close after error delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && provider.voiceState == VoiceState.error) {
          provider.setMode(KeyboardMode.normal);
        }
      });
    } else if (call.method == 'onVoicePartialResult') {
      final text = call.arguments['text'] as String;
      debugPrint("VibeKeyboard: Voice partial result: '$text'");
      final provider = Provider.of<KeyboardProvider>(context, listen: false);
      provider.updatePartialTranscription(text);
    }
  }

  void _resetToInitialState() {
    Provider.of<SettingsProvider>(context, listen: false).refreshSettings();
    Provider.of<KeyboardProvider>(context, listen: false).resetState();
    _refreshClipboard();
    setState(() {
      _isShiftPressed = false;
      _isCapsLock = false;
      _isShiftPressed = false;
      _isCapsLock = false;
      _isSymbols = false;
      _symbolsPageIndex = 0;
    });
  }

  List<List<String>> get _currentLayout {
    if (_isSymbols) {
      return _symbolsPageIndex == 0 
          ? KeyboardConstants.symbolsLayoutPage1 
          : KeyboardConstants.symbolsLayoutPage2;
    }
    return _currentLanguage == 'اردو'
        ? KeyboardConstants.urduLayout
        : KeyboardConstants.qwertyLayout;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context);
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: SizedBox(
              height: KeyboardConstants.standardKeyboardHeight,
              child: Container(
                color: provider.currentTheme.backgroundColor,
                child: Column(
                  children: [


                    Stack(
                      children: [
                        AIToolbar(
                          provider: provider,
                          onGrammarFix: () => _handleAIAction(
                              provider, () => provider.grammarFix(platform)),
                          onTranslate: () => _handleTranslateAction(
                              provider, (lang) => _handleAIAction(provider, () => provider.translate(lang, platform))),
                          onAddEmojis: () => _handleAIAction(
                              provider, () => provider.addEmojis(platform)),
                          onAIAssist: () => _handleAIAction(
                              provider,
                              () => provider.aiAssist(
                                  provider.currentText.isNotEmpty
                                      ? "Help me write more or improve this: ${provider.currentText}"
                                      : "Give me a cool greeting for a formal message",
                                  platform)),
                          onAppsMenu: () => _showAppsMenu(provider),
                          onVoiceInput: () => _showVoiceInputDialog(provider),
                          onMagicPressed: () {
                            if (provider.mode == KeyboardMode.magic) {
                              provider.setMode(KeyboardMode.normal);
                            } else {
                              provider.setMode(KeyboardMode.magic);
                            }
                          },
                        ),
                        if (provider.isLoading)
                          const Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6366F1)),
                              minHeight: 2,
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: _buildKeyboardUI(provider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardUI(KeyboardProvider provider) {
    if (provider.infoMessage != null) {
      return _buildInfoView(provider);
    }

    if (provider.mode == KeyboardMode.magic) {
      return MagicMenuUI(
        provider: provider,
        onRephrase: () => provider.rephraseSelection(),
        onSummarize: () => _handleMagicAction(provider, () => provider.summarizeSelection()),
        onGrammarFix: () => _handleMagicAction(provider, () => provider.grammarFixSelection()),
        onTranslate: () => _handleTranslateAction(
            provider, (lang) => _handleMagicAction(provider, () => provider.translateSelection(lang))),
      );
    }

    if (provider.mode == KeyboardMode.rephrase) {
      return RephraseUI(
        provider: provider,
        onOptionSelected: (option) {
          final int deleteCount = provider.originalTextLength;
          provider.applyRephrase(option);
          platform.invokeMethod('replaceText', {
            'text': option,
            'deleteCount': deleteCount,
          });
        },
      );
    }

    if (provider.mode == KeyboardMode.translate) {
      return TranslateUI(
        provider: provider,
        onUseTranslation: () {
          if (provider.translatedText.isNotEmpty) {
            final translation = provider.translatedText;
            provider.applyRephrase(translation);
            platform.invokeMethod('replaceText', {
              'text': translation,
              'deleteCount': provider.currentText.length
            });
          }
        },
      );
    }

    if (provider.mode == KeyboardMode.apps) {
      return AppsMenuSheet(
        onGifs: () => provider.setPicker('gifs'),
        onStickers: () => provider.setPicker('stickers'),
        onTheme: () => provider.setMode(KeyboardMode.themes),
        onPaste: () => provider.setMode(KeyboardMode.clipboard),
      );
    }

    if (provider.mode == KeyboardMode.themes) {
      return const ThemeMenuSheet();
    }

    if (provider.mode == KeyboardMode.clipboard) {
      return ClipboardHistorySheet(
        onItemSelected: (text) {
          _insertText(text);
          provider.setMode(KeyboardMode.normal);
        },
      );
    }

    if (provider.showEmojis) {
      return EmojiPickerWidget(
        onEmojiSelected: _insertText,
        onBack: () => provider.resetPickers(),
        onDelete: _deleteText,
      );
    }

    if (provider.showStickers) {
      return StickerPickerWidget(
        onStickerSelected: (url) {
          final mimeType = url.toLowerCase().contains('.gif') ? 'image/gif' : 'image/webp';
          provider.sendMedia(url, mimeType, label: "Sticker");
        },
        onBack: () => provider.resetPickers(),
        onDelete: _deleteText,
      );
    }

    if (provider.showGifs) {
      return GifPickerWidget(
        onGifSelected: (url) {
          final mimeType = url.toLowerCase().contains('.webp') ? 'image/webp' : 'image/gif';
          provider.sendMedia(url, mimeType, label: "GIF");
        },
        onBack: () => provider.resetPickers(),
        onDelete: _deleteText,
      );
    }

    if (provider.mode == KeyboardMode.voice) {
      return VoiceInputDialog(
        onResult: (text) {
          provider.setMode(KeyboardMode.normal);
        },
        onCancel: () {
          provider.stopVoiceInput(platform);
          provider.setMode(KeyboardMode.normal);
        },
        partialTranscription: provider.partialTranscription,
        voiceState: provider.voiceState,
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRow(_currentLayout[0], showNumbers: !_isSymbols),
          _buildRow(_currentLayout[1]),
          Row(
            children: [
              SpecialKey(
                icon: !_isSymbols 
                    ? (_isCapsLock ? Icons.file_upload : Icons.arrow_upward_rounded) 
                    : null,
                label: _isSymbols ? (_symbolsPageIndex == 0 ? '=\\<' : '?123') : null,
                backgroundColor: (_isShiftPressed || _isCapsLock)
                    ? provider.currentTheme.textColor.withOpacity(0.2)
                    : Colors.transparent,
                iconColor: (_isCapsLock) 
                    ? provider.currentTheme.specialKeyColor 
                    : provider.currentTheme.specialKeyIconColor, // Highlight if CapsLock
                onPressed: () {
                  if (_isSymbols) {
                    setState(() => _symbolsPageIndex = _symbolsPageIndex == 0 ? 1 : 0);
                  } else {
                    final now = DateTime.now();
                    if (_lastShiftTap != null && 
                        now.difference(_lastShiftTap!) < const Duration(milliseconds: 300)) {
                      // Double tap detected -> Toggle CapsLock
                      setState(() {
                         _isCapsLock = !_isCapsLock;
                         _isShiftPressed = _isCapsLock; // Sync shift with caps
                      });
                      _lastShiftTap = null; // Reset
                    } else {
                      // Single tap
                      _lastShiftTap = now;
                      setState(() {
                        if (_isCapsLock) {
                           // If capslock was on, turn it off completely
                           _isCapsLock = false;
                           _isShiftPressed = false;
                        } else {
                           _isShiftPressed = !_isShiftPressed;
                        }
                      });
                    }
                  }
                },
                onLongPress: !_isSymbols ? () => setState(() => _isCapsLock = !_isCapsLock) : null,
                flex: 12,
              ),
              Expanded(
                flex: 76,
                child: _buildRow(_currentLayout[2], mainRow: false),
              ),
              SpecialKey(
                icon: Icons.backspace_rounded,
                backgroundColor: provider.currentTheme.specialKeyColor,
                iconColor: provider.currentTheme.specialKeyIconColor,
                onPressed: _deleteText,
                autoRepeat: true,
                flex: 13,
              ),
            ],
          ),

          Row(
            children: [
              SpecialKey(
                label: _isSymbols ? 'ABC' : '?123',
                backgroundColor: provider.currentTheme.specialKeyColor,
                // iconColor used for text color in SpecialKey if label set? No, Key uses white hardcoded unless updated
                // SpecialKey uses white hardcoded for text. I should update SpecialKey to accept textColor too?
                // Let's stick to specialKeyIconColor for now or update SpecialKey widget.
                onPressed: () {
                  setState(() {
                    _isSymbols = !_isSymbols;
                    _symbolsPageIndex = 0; // Reset page on toggle
                  });
                },
                flex: 15,
              ),
              SpecialKey(
                icon: Icons.emoji_emotions_outlined,
                backgroundColor: provider.currentTheme.specialKeyColor,
                iconColor: provider.currentTheme.specialKeyIconColor,
                onPressed: () => provider.setPicker(provider.showEmojis ? 'none' : 'emojis'),
                flex: 11,
              ),
              SpecialKey(
                icon: Icons.language_rounded,
                backgroundColor: provider.currentTheme.specialKeyColor,
                iconColor: provider.currentTheme.specialKeyIconColor,
                onPressed: _switchLanguage,
                flex: 11,
              ),
              SpecialKey(
                label: _currentLanguage,
                backgroundColor: provider.currentTheme.keyColor, // Spacebar like normal key? Or special?
                // Usually spacebar is keyColor.
                onPressed: () => _insertText(' '),
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  _switchLanguage();
                },
                flex: 40,
              ),
              SpecialKey(
                label: '.',
                backgroundColor: provider.currentTheme.specialKeyColor,
                onPressed: () => _insertText('.'),
                onLongPress: () => _showQuickPunctuation(),
                flex: 10,
              ),
              SpecialKey(
                icon: _getEnterIcon(),
                backgroundColor: _getEnterColor(),
                iconColor: Colors.black87,
                onPressed: _handleEnter,
                flex: 15,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoView(KeyboardProvider provider) {
    return Container(
      color: provider.currentTheme.backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                provider.infoMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => provider.clearCallback(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8AB4F8),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Got it!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys,
      {double padding = 0, bool showNumbers = false, bool mainRow = true}) {
    final theme = Provider.of<KeyboardProvider>(context).currentTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.asMap().entries.map((entry) {
          final idx = entry.key;
          final key = entry.value;
          var display =
              (_isShiftPressed || _isCapsLock) ? key.toUpperCase() : key;
          final number = showNumbers && idx < 10 ? '${(idx + 1) % 10}' : null;
          return KeyboardKey(
            key: ValueKey('key_${key}_$idx'),
            label: display,
            sublabel: number,
            backgroundColor: theme.keyColor,
            textColor: theme.textColor,
            onTap: () {
              _insertText(display);
              if (_isShiftPressed && !_isCapsLock) {
                setState(() => _isShiftPressed = false);
              }
            },
            onLongPress: number != null
                ? () {
                    HapticFeedback.mediumImpact();
                    _insertText(number);
                  }
                : null,
          );
        }).toList(),
      ),
    );
  }

  void _insertText(String text) =>
      platform.invokeMethod('insertText', {'text': text});

  void _deleteText() => platform.invokeMethod('deleteText');

  void _deleteAllText() {
    HapticFeedback.heavyImpact();
    for (int i = 0; i < 20; i++) {
      _deleteText();
    }
  }

  Future<void> _handleAIAction(
      KeyboardProvider provider, Future<void> Function() action) async {
    final text = await platform.invokeMethod<String>('getTextBeforeCursor');
    // Sync current text with native side before action
    provider.setInitialText(text ?? "");
    
    final int originalLength = text?.length ?? 0;
    
    await action();
    
    print("🧠 [DEBUG] VibeKeyboard: AI Action complete. Mode: ${provider.mode}, Info: ${provider.infoMessage}");
    
    // Only replace text if we had some text to start with and the action returned a result
    if (originalLength > 0 && 
        provider.mode == KeyboardMode.normal &&
        provider.infoMessage != null &&
        !provider.infoMessage!.startsWith("Error:")) {
      print("🧠 [DEBUG] VibeKeyboard: Calling replaceText. Text: '${provider.currentText}', DeleteCount: $originalLength");
      await platform.invokeMethod('replaceText', {
        'text': provider.currentText,
        'deleteCount': originalLength,
      });
    }
  }

  void _handleTranslateAction(KeyboardProvider provider, Function(String) onTranslate) {
    debugPrint("🌍 [DEBUG] VibeKeyboard: _handleTranslateAction. Languages: ${provider.targetLanguages}");
    if (provider.targetLanguages.length == 1) {
      debugPrint("🌍 [DEBUG] VibeKeyboard: Direct translate to ${provider.targetLanguages.first}");
      onTranslate(provider.targetLanguages.first);
    } else if (provider.targetLanguages.length > 1) {
      debugPrint("🌍 [DEBUG] VibeKeyboard: Multiple languages, showing picker.");
      _showLanguagePicker(provider, onTranslate);
    } else {
      debugPrint("🌍 [DEBUG] VibeKeyboard: NO LANGUAGES SELECTED!");
      provider.showInfo("Please select languages in Settings app");
    }
  }

  void _showLanguagePicker(KeyboardProvider provider, Function(String) onTranslate) {
    _showManagedModal(() async {
      await showModalBottomSheet(
        context: context,
        isDismissible: true,
        backgroundColor: const Color(0xFF2C2C2C),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          constraints: BoxConstraints(
            maxHeight: KeyboardConstants.standardKeyboardHeight * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Choose Language",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.targetLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = provider.targetLanguages[index];
                    return ListTile(
                      title: Text(lang, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        onTranslate(lang);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _handleMagicAction(
      KeyboardProvider provider, Future<String?> Function() action) async {
    final result = await action();
    if (result != null) {
      // Replace the selection with the result
      await platform.invokeMethod('replaceText', {'text': result});
      provider.setMode(KeyboardMode.normal);
    }
  }

  void _showVoiceInputDialog(KeyboardProvider provider) async {
    provider.resetVoiceState();
    provider.setMode(KeyboardMode.voice);
    
    // Start voice recognition
    try {
      await platform.invokeMethod('startVoiceInput');
    } catch (e) {
      debugPrint("Voice input error: $e");
      provider.resetVoiceState();
      provider.setMode(KeyboardMode.normal);
    }
  }

  Future<void> _toggleFullScreen(bool enabled) async {
    try {
      await platform.invokeMethod('setFullScreenTouch', {'enabled': enabled});
    } catch (e) {
      debugPrint('Error toggling fullscreen: $e');
    }
  }

  void _startVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input feature coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  int _activeModals = 0;

  Future<void> _showManagedModal(Future<void> Function() modalBuilder) async {
    setState(() => _activeModals++);
    
    // Expand touchable area if this is the first modal
    if (_activeModals == 1) {
      await _toggleFullScreen(true);
    }

    try {
      if (mounted) {
        await modalBuilder();
      }
    } finally {
      setState(() => _activeModals--);
      
      // If no modals are left, restore keyboard area and reset state
      if (_activeModals == 0) {
        await _toggleFullScreen(false);
        _resetToInitialState();
      }
    }
  }

  void _showAppsMenu(KeyboardProvider provider) {
    _refreshClipboard();
    provider.setMode(KeyboardMode.apps);
  }

  void _showThemeMenu() {
    Provider.of<KeyboardProvider>(context, listen: false).setMode(KeyboardMode.themes);
  }

  void _showQuickPunctuation() {
    final punctuations = ['.', ',', '!', '?', ';', ':', '-', '"', "'"];
    _showManagedModal(() async {
      await showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: true,
        barrierColor: Colors.black45,
        backgroundColor: const Color(0xFF2C2C2C),
        builder: (context) => Container(
          padding: const EdgeInsets.all(12),
          height: 90,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: punctuations.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                _insertText(punctuations[index]);
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF3C4043),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    punctuations[index],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showClipboardMenu() {
    Provider.of<KeyboardProvider>(context, listen: false).setMode(KeyboardMode.clipboard);
  }

  void _pasteClipboard() {
    Provider.of<KeyboardProvider>(context, listen: false).refreshClipboardHistory(platform);
    _showClipboardMenu();
  }

  void _switchLanguage() {
    setState(() {
      _languageIndex = (_languageIndex + 1) % KeyboardConstants.languages.length;
      _currentLanguage = KeyboardConstants.languages[_languageIndex];
      // Sync with provider
      final provider = Provider.of<KeyboardProvider>(context, listen: false);
      if (_currentLanguage == 'English') {
        provider.setKeyboardLanguage(KeyboardLanguage.english);
      } else {
        provider.setKeyboardLanguage(KeyboardLanguage.urdu);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _showLanguageMenu() {
    _showManagedModal(() async {
      await showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: true,
        barrierColor: Colors.black45,
        backgroundColor: const Color(0xFF2C2C2C),
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: KeyboardConstants.languages
                .map((lang) => ListTile(
                      title:
                          Text(lang, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        setState(() => _currentLanguage = lang);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        ),
      );
    });
  }

  void _resetPickers() {
    // Moved to provider.resetPickers()
  }

  IconData _getEnterIcon() {
    switch (_inputAction) {
      case 'search':
        return Icons.search_rounded;
      case 'send':
        return Icons.send_rounded;
      case 'go':
        return Icons.arrow_forward_rounded;
      case 'next':
        return Icons.navigate_next_rounded;
      case 'done':
        return Icons.check_rounded;
      default:
        return Icons.keyboard_return_rounded;
    }
  }

  Color _getEnterColor() {
    final theme = Provider.of<KeyboardProvider>(context, listen: false).currentTheme;
    switch (_inputAction) {
      case 'newline':
        return theme.specialKeyColor; // Use theme color
      default:
        return const Color(0xFF8AB4F8); // Blue for actions
    }
  }

  void _handleEnter() {
    if (_inputAction == 'newline') {
      _insertText('\n');
    } else {
      platform.invokeMethod('performEnterAction', {'action': _inputAction});
    }
  }
}
