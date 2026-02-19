import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/giphy_service.dart';
import '../data/services/ai_service.dart';
import '../core/constants.dart';

class SettingsProvider with ChangeNotifier {
  final AIService _aiService = AIService();
  final GiphyService _giphyService = GiphyService();
  String _apiKey = AppConstants.kDefaultApiKey;
  bool _isVibrationEnabled = true;
  List<String> _selectedLanguages = ['Urdu', 'Arabic', 'English', 'French'];
  
  static const List<String> availableLanguages = [
    'Urdu', 'Arabic', 'French', 'Spanish', 'German', 'Hindi', 'Chinese', 'Japanese'
  ];

  AIService get aiService => _aiService;
  GiphyService get giphyService => _giphyService;
  String get apiKey => _apiKey;
  bool get isVibrationEnabled => _isVibrationEnabled;
  List<String> get selectedLanguages => _selectedLanguages;

  SettingsProvider() {
    refreshSettings();
  }

  Future<void> refreshSettings() async {
    try {
      const platform = MethodChannel('custom_keyboard/input');
      final Map<dynamic, dynamic>? nativeSettings = await platform.invokeMethod('getSettings');
      
      if (nativeSettings != null) {
        _apiKey = nativeSettings['api_key'] ?? AppConstants.kDefaultApiKey;
        _isVibrationEnabled = nativeSettings['vibration_enabled'] ?? true;
        
        final dynamic languages = nativeSettings['selected_languages'];
        if (languages is List) {
          _selectedLanguages = List<String>.from(languages);
        }
        
        debugPrint("⚙️ [DEBUG] SettingsProvider: Settings refreshed from NATIVE. Selected: $_selectedLanguages");
        
        if (_apiKey.isNotEmpty) {
          _aiService.init(_apiKey);
        }
        notifyListeners();
        return; // Success, skip Fallback
      }
    } catch (e) {
      debugPrint("⚙️ [DEBUG] SettingsProvider: Native refresh failed or unavailable: $e. Falling back to SharedPreferences.");
    }

    // Fallback to standard SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? AppConstants.kDefaultApiKey;
    _isVibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    _selectedLanguages = prefs.getStringList('selected_languages') ?? ['Urdu', 'Arabic', 'English', 'French'];
    
    debugPrint("⚙️ [DEBUG] SettingsProvider: Settings refreshed from SP (Fallback). Selected: $_selectedLanguages");
    
    if (_apiKey.isNotEmpty) {
      _aiService.init(_apiKey);
    }
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    _aiService.init(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    notifyListeners();
  }

  Future<void> toggleVibration(bool value) async {
    _isVibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }

  Future<void> setSelectedLanguages(List<String> languages) async {
    _selectedLanguages = languages;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_languages', languages);
    debugPrint("⚙️ [DEBUG] SettingsProvider: Selected languages UPDATED: $_selectedLanguages");
    notifyListeners();
  }
}
