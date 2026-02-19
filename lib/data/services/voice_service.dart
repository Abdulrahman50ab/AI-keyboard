/*
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) => debugPrint('🎙️ Voice Status: $status'),
        onError: (error) => debugPrint('🎙️ Voice Error: $error'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('🎙️ Voice Init Error: $e');
      return false;
    }
  }

  bool get isListening => _speechToText.isListening;

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    bool available = await init();
    if (available) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
            onDone();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: true,
      );
    } else {
      debugPrint('🎙️ Speech recognition not available');
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> cancelListening() async {
    await _speechToText.cancel();
  }
}
*/

