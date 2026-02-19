import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/services/giphy_service.dart';
import '../data/services/ai_service.dart';
import '../core/keyboard_theme.dart';

enum KeyboardMode {
  normal,
  grammar,
  rephrase,
  translate,
  aiAssist,
  magic,
  apps,
  themes,
  clipboard,
  voice
}

enum KeyboardLanguage { english, urdu, arabic }

enum VoiceState { preparing, ready, listening, processing, done, error }

class KeyboardProvider with ChangeNotifier {
  final AIService _aiService;
  final GiphyService _giphyService;
  final _platform = const MethodChannel('custom_keyboard/input');

  String _currentText = "";
  final List<String> _history = [];
  int _historyIndex = -1;

  String get currentText => _currentText;

  bool _isShift = false;
  bool _isCaps = false;
  bool _isLoading = false;
  bool _isRecording = false;
  int _originalTextLength = 0;
  String _aiTitle = "Rephrase Options";
  String? _infoMessage;
  Timer? _infoTimer;

  // Voice input state
  String _partialTranscription = "";
  VoiceState _voiceState = VoiceState.preparing;

  KeyboardMode _mode = KeyboardMode.normal;
  KeyboardLanguage _language = KeyboardLanguage.english;

  // AI Results
  List<String> _rephraseOptions = [];
  String _translatedText = "";

  bool _isGifs = false;
  bool _showEmojis = false;
  bool _showGifs = false;
  bool _showStickers = false;
  List<String> _giphyResults = [];
  bool _isLoadingGiphy = false;
  List<String> _targetLanguages = ['Urdu', 'Arabic', 'English', 'French'];

  KeyboardProvider(this._aiService, this._giphyService);

  bool get isShift => _isShift;
  bool get isCaps => _isCaps;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording; // Add getter for _isRecording
  int get originalTextLength => _originalTextLength;
  String get aiTitle => _aiTitle;
  String? get infoMessage => _infoMessage;
  KeyboardMode get mode => _mode;
  KeyboardLanguage get language => _language;
  List<String> get rephraseOptions => _rephraseOptions;
  String get translatedText => _translatedText;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;
  String get partialTranscription => _partialTranscription;
  VoiceState get voiceState => _voiceState;

  bool get showEmojis => _showEmojis;
  bool get showGifs => _showGifs;
  bool get showStickers => _showStickers;
  List<String> get giphyResults => _giphyResults;
  bool get isLoadingGiphy => _isLoadingGiphy;
  List<String> get targetLanguages => _targetLanguages;

  void updateTargetLanguages(List<String> languages) {
    if (_targetLanguages != languages) {
      _targetLanguages = languages;
      notifyListeners();
    }
  }

  void setPicker(String type) {
    _showEmojis = type == 'emojis';
    _showGifs = type == 'gifs';
    _showStickers = type == 'stickers';
    if (type != 'none') {
      _mode = KeyboardMode.normal;
    }

    // Auto-fetch trending if picker opened and results empty
    if (type == 'stickers' && _giphyResults.isEmpty) {
      fetchTrendingStickers();
    } else if (type == 'gifs' && _giphyResults.isEmpty) {
      fetchTrendingGifs();
    }

    notifyListeners();
  }

  Future<void> fetchTrendingStickers() async {
    _isLoadingGiphy = true;
    notifyListeners();
    try {
      _giphyResults = await _giphyService.fetchTrendingStickers();
    } catch (e) {
      debugPrint("Giphy Error: $e");
    }
    _isLoadingGiphy = false;
    notifyListeners();
  }

  Future<void> fetchTrendingGifs() async {
    _isLoadingGiphy = true;
    notifyListeners();
    try {
      _giphyResults = await _giphyService.fetchTrendingGifs();
    } catch (e) {
      debugPrint("Giphy Error: $e");
    }
    _isLoadingGiphy = false;
    notifyListeners();
  }

  Future<void> searchGiphy(String query, bool isSticker) async {
    if (query.isEmpty) return;
    _isLoadingGiphy = true;
    notifyListeners();
    try {
      if (isSticker) {
        _giphyResults = await _giphyService.searchStickers(query);
      } else {
        _giphyResults = await _giphyService.searchGifs(query);
      }
    } catch (e) {
      debugPrint("Giphy Error: $e");
    }
    _isLoadingGiphy = false;
    notifyListeners();
  }

  void resetPickers() {
    _showEmojis = false;
    _showGifs = false;
    _showStickers = false;
    _giphyResults = []; // Clear results when closing
    notifyListeners();
  }

  void setInitialText(String text) {
    _currentText = text;
    _originalTextLength = text.length;
    notifyListeners();
  }

  void insertText(String text) {
    _addToHistory();
    _currentText += text;
    if (_isShift && !_isCaps) {
      _isShift = false;
    }
    notifyListeners();
  }

  void backspace() {
    if (_currentText.isNotEmpty) {
      _addToHistory();
      _currentText = _currentText.substring(0, _currentText.length - 1);
      notifyListeners();
    }
  }

  void _addToHistory() {
    // If we are in the middle of history and type, cut off the future
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // Add current state if different from last
    if (_history.isEmpty || _history.last != _currentText) {
      _history.add(_currentText);
      if (_history.length > 20) {
        _history.removeAt(0);
      } else {
        _historyIndex++;
      }
    }
    // Update index to point to the new latest
    _historyIndex = _history.length - 1;
  }

  void undo() {
    if (canUndo) {
      _historyIndex--;
      _currentText = _history[_historyIndex];
      notifyListeners();
    }
  }

  void redo() {
    if (canRedo) {
      _historyIndex++;
      _currentText = _history[_historyIndex];
      notifyListeners();
    }
  }

  void clearCallback() {
    _infoTimer?.cancel();
    _infoMessage = null;
    notifyListeners();
  }

  void showInfo(String message) {
    _infoMessage = message;
    notifyListeners();

    // We removed the auto-dismiss timer so messages persist until manual dismissal.
    _infoTimer?.cancel();
  }

  void toggleShift() {
    if (_isShift) {
      _isCaps = !_isCaps;
      _isShift = _isCaps;
    } else {
      _isShift = true;
    }
    notifyListeners();
  }

  void cycleLanguage() {
    if (_language == KeyboardLanguage.english) {
      _language = KeyboardLanguage.urdu;
    } else if (_language == KeyboardLanguage.urdu) {
      _language = KeyboardLanguage.arabic;
    } else {
      _language = KeyboardLanguage.english;
    }
    notifyListeners();
  }

  void setKeyboardLanguage(KeyboardLanguage lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void resetState() {
    _mode = KeyboardMode.normal;
    _isShift = false;
    _isCaps = false;
    _infoMessage = null;
    _rephraseOptions = [];
    _translatedText = "";
    _showEmojis = false;
    _showGifs = false;
    _showStickers = false;
    notifyListeners();
  }

  void setMode(KeyboardMode newMode) {
    _mode = newMode;
    if (newMode == KeyboardMode.normal) {
      _rephraseOptions = [];
      _translatedText = "";
      _infoMessage = null;
    }
    notifyListeners();
  }

  // AI Actions need to support Undo as well
  Future<void> grammarFix([MethodChannel? platform]) async {
    if (platform != null) {
      final text = await platform
          .invokeMethod<String>('getTextBeforeCursor', {'length': 1000});
      if (text != null && text.isNotEmpty) {
        _currentText = text;
      }
    }

    if (_currentText.isEmpty) {
      showInfo(
          "✏️ Grammar Fix\n\nCorrects spelling and grammar mistakes in your text.\n\nPlease type some text first to use this feature.");
      return;
    }
    _setLoading(true);
    try {
      final result = await _aiService.grammarFix(_currentText);
      if (result.startsWith("Error:")) {
        showInfo(result);
      } else {
        _addToHistory();
        _currentText = result;
        showInfo("Grammar Fixed!");
      }
    } catch (e) {
      showInfo("Error: $e");
    }
    _setLoading(false);
  }

  Future<void> rephrase() async {
    if (_currentText.isEmpty) {
      showInfo(
          "🔄 Rephrase\n\nRewrites your text in different styles while keeping the same meaning.\n\nPlease type some text first to use this feature.");
      return;
    }
    _setLoading(true);
    try {
      _rephraseOptions = await _aiService.rephrase(_currentText);
      if (_rephraseOptions.isNotEmpty &&
          _rephraseOptions.first.startsWith("Error:")) {
        showInfo(_rephraseOptions.first);
        _rephraseOptions = [];
      } else {
        _aiTitle = "Rephrase Options";
        _mode = KeyboardMode.rephrase;
        _originalTextLength = _currentText.length;
      }
    } catch (e) {
      showInfo("Error: $e");
    }
    _setLoading(false);
  }

  Future<void> addEmojis([MethodChannel? platform]) async {
    print("🧠 [DEBUG] KeyboardProvider: addEmojis started.");

    if (platform != null) {
      final text = await platform
          .invokeMethod<String>('getTextBeforeCursor', {'length': 1000});
      if (text != null && text.isNotEmpty) {
        _currentText = text;
        print(
            "🧠 [DEBUG] KeyboardProvider: Fetched text from platform: '$_currentText'");
      }
    }

    if (_currentText.isEmpty) {
      showInfo(
          "🪄 Add Emojis\n\nAnalyzes your text and suggests relevant emojis to make it more expressive.\n\nPlease type some text first to use this feature.");
      return;
    }
    _setLoading(true);
    try {
      final result = await _aiService.addEmojis(_currentText);
      print("🧠 [DEBUG] KeyboardProvider: AIService returned: '$result'");
      if (result.startsWith("Error:")) {
        showInfo(result);
        print("🧠 [DEBUG] KeyboardProvider: Error set in infoMessage.");
      } else {
        _addToHistory();
        _currentText = result; // Restore full replacement
        showInfo("Emojis Added!");
        print(
            "🧠 [DEBUG] KeyboardProvider: Success! New text: '$_currentText'");
      }
    } catch (e) {
      showInfo("Error: $e");
      print("🧠 [DEBUG] KeyboardProvider: Exception caught: $e");
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> translate(String targetLang, [MethodChannel? platform]) async {
    debugPrint(
        "🧠 [DEBUG] KeyboardProvider: translate toward '$targetLang' started.");
    if (platform != null) {
      final text = await platform
          .invokeMethod<String>('getTextBeforeCursor', {'length': 1000});
      if (text != null && text.isNotEmpty) {
        _currentText = text;
      }
    }

    if (_currentText.isEmpty) {
      showInfo(
          "🌍 Translate\n\nTranslates your text to your selected language(s).\n\nPlease type some text first to use this feature.");
      return;
    }
    _setLoading(true);
    try {
      final result = await _aiService.translate(_currentText, targetLang);
      if (result.startsWith("Error:")) {
        showInfo(result);
      } else {
        _translatedText = result;
        _mode = KeyboardMode.translate;
      }
    } catch (e) {
      showInfo("Error: $e");
    }
    _setLoading(false);
  }

  Future<void> aiAssist(String prompt, [MethodChannel? platform]) async {
    _setLoading(true);

    // Sync current text with native side
    if (platform != null) {
      final text = await platform
          .invokeMethod<String>('getTextBeforeCursor', {'length': 1000});
      if (text != null && text.isNotEmpty) {
        _currentText = text;
        // Special handling for Help me write more which depends on currentText
        if (prompt.contains("Help me write more")) {
          prompt = "Help me write more or improve this: $_currentText";
        }
      }
    }

    if (_currentText.isEmpty && prompt.contains("Help me write more")) {
      showInfo(
          "✨ AI Assist\n\nHelps you expand your ideas, improve your writing, or generate creative content.\n\nPlease type some text first or try a greeting!");
      // Continue anyway as aiAssist can generate greetings without text
    }

    try {
      final options = await _aiService.aiAssistOptions(prompt);
      if (options.isEmpty) {
        showInfo("No suggestions found. Please try again.");
      } else {
        _rephraseOptions = options;
        _aiTitle = "AI Assist Suggestions";
        _mode = KeyboardMode.rephrase; // Reuse rephrase UI for selection
      }
    } catch (e) {
      showInfo("Error: $e");
    }
    _setLoading(false);
  }

  void applyRephrase(String text) {
    _addToHistory();
    _currentText = text;
    _mode = KeyboardMode.normal;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Theme Management
  KeyboardTheme _currentTheme = KeyboardTheme.dark;
  KeyboardTheme get currentTheme => _currentTheme;

  String _selectedText = "";
  String get selectedText => _selectedText;

  void updateSelection(String text) {
    if (_selectedText != text) {
      _selectedText = text;
      // If selection is cleared, return to normal mode if we were in magic mode
      if (_selectedText.isEmpty && _mode == KeyboardMode.magic) {
        _mode = KeyboardMode.normal;
      }
      notifyListeners();
    }
  }

  void setTheme(KeyboardTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  Future<void> rephraseSelection() async {
    if (_selectedText.isEmpty) return;
    _setLoading(true);
    try {
      _rephraseOptions = await _aiService.rephrase(_selectedText);
      if (_rephraseOptions.isNotEmpty &&
          _rephraseOptions.first.startsWith("Error:")) {
        showInfo(_rephraseOptions.first);
        _rephraseOptions = [];
      } else {
        _aiTitle = "Magic Rephrase";
        _mode = KeyboardMode.rephrase;
        _originalTextLength = _selectedText.length;
      }
    } catch (e) {
      showInfo("Error: $e");
    }
    _setLoading(false);
  }

  Future<String?> grammarFixSelection() async {
    if (_selectedText.isEmpty) return null;
    _setLoading(true);
    try {
      final result = await _aiService.grammarFix(_selectedText);
      _setLoading(false);
      if (result.startsWith("Error:")) {
        showInfo(result);
        return null;
      } else {
        showInfo("Grammar Fixed!");
        return result;
      }
    } catch (e) {
      _setLoading(false);
      showInfo("Error: $e");
      return null;
    }
  }

  Future<String?> translateSelection(String targetLang) async {
    if (_selectedText.isEmpty) return null;
    _setLoading(true);
    try {
      final result = await _aiService.translate(_selectedText, targetLang);
      _setLoading(false);
      if (result.startsWith("Error:")) {
        showInfo(result);
        return null;
      } else {
        showInfo("Translated!");
        return result;
      }
    } catch (e) {
      _setLoading(false);
      showInfo("Error: $e");
      return null;
    }
  }

  Future<String?> summarizeSelection() async {
    if (_selectedText.isEmpty) return null;
    _setLoading(true);
    try {
      final options = await _aiService.summarizeOptions(_selectedText);
      if (options.isEmpty) {
        showInfo("No summary found. Please try again.");
      } else {
        _rephraseOptions = options;
        _aiTitle = "Summarize Options";
        _originalTextLength = _selectedText.length;
        _mode = KeyboardMode.rephrase;
        // No showInfo here as requested
      }
      return null; // Return null so _handleMagicAction doesn't replace immediately
    } catch (e) {
      showInfo("Error: $e");
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Clipboard History
  final List<String> _clipboardHistory = [];
  List<String> get clipboardHistory => List.unmodifiable(_clipboardHistory);

  void updateClipboardHistory(String text) {
    if (text.trim().isEmpty) return;

    // Remove if already exists (to move it to top)
    _clipboardHistory.removeWhere((item) => item == text);

    // Insert at top
    _clipboardHistory.insert(0, text);

    // Limit to 4 items
    if (_clipboardHistory.length > 4) {
      _clipboardHistory.removeLast();
    }
    debugPrint(
        "🧠 [DEBUG] ClipboardHistory Updated. Count: ${_clipboardHistory.length}. Top: '${_clipboardHistory.first.substring(0, _clipboardHistory.first.length > 20 ? 20 : _clipboardHistory.first.length)}...'");

    notifyListeners();
  }

  Future<void> refreshClipboardHistory([MethodChannel? platform]) async {
    try {
      String? text;
      if (platform != null) {
        text = await platform.invokeMethod<String>('getNativeClipboard');
      } else {
        final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
        text = clipboardData?.text;
      }

      if (text != null) {
        updateClipboardHistory(text);
      }
    } catch (e) {
      debugPrint("Clipboard refresh error: $e");
    }
  }

  Future<void> toggleVoiceInput(MethodChannel platform) async {
    try {
      await platform.invokeMethod('startVoiceInput');
      showInfo("Voice input opened");
      notifyListeners();
    } catch (e) {
      showInfo("Voice input not available");
      debugPrint("Voice input error: $e");
      notifyListeners();
    }
  }

  // Voice input state management
  void updatePartialTranscription(String text) {
    _partialTranscription = text;
    notifyListeners();
  }

  void setVoiceState(VoiceState state) {
    _voiceState = state;
    notifyListeners();
  }

  Future<void> stopVoiceInput(MethodChannel platform) async {
    try {
      await platform.invokeMethod('stopVoiceInput');
    } catch (e) {
      debugPrint("Error stopping voice input: $e");
    }
    _voiceState = VoiceState.preparing;
    notifyListeners();
  }

  void resetVoiceState() {
    _partialTranscription = "";
    _voiceState = VoiceState.preparing;
    notifyListeners();
  }

  Future<bool> sendMedia(String url, String mimeType,
      {String label = "Media"}) async {
    try {
      final bool? result = await _platform.invokeMethod<bool>('commitContent', {
        'url': url,
        'mimeType': mimeType,
        'label': label,
      });

      if (result == false) {
        showInfo(
            "This app doesn't support sharing ${mimeType.contains('gif') ? 'GIFs' : 'Stickers'} here.");
      }
      return result ?? false;
    } catch (e) {
      debugPrint("Error sending media: $e");
      return false;
    }
  }
}
