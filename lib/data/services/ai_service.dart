import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class AIService {
  String _apiKey = AppConstants.kDefaultApiKey;
  static const String _baseUrl = "https://api.groq.com/openai/v1/chat/completions";
  static const String _modelName = "llama-3.3-70b-versatile"; // Best quality model

  void init(String apiKey) {
    if (apiKey.isNotEmpty) {
      _apiKey = apiKey;
    }
  }

  Future<String> _callGroq(String prompt) async {
    print("🤖 [DEBUG] AIService: Calling Groq ($_modelName)");

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful mobile keyboard assistant. Provide concise and accurate results. Keep responses brief and to the point.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        if (text != null) {
          print("✅ [DEBUG] Groq Success");
          return text.trim();
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? "Unknown Error";
        print("❌ [DEBUG] Groq Error: ${response.statusCode} - $errorMessage");
        return "Error: (${response.statusCode}) $errorMessage";
      }
    } catch (e, stack) {
      print("❌ [DEBUG] Network Error: $e");
      print("❌ [DEBUG] Stack Trace: $stack");
      
      if (e.toString().contains("HandshakeException")) {
        return "Error: SSL Handshake failed. Please try with a VPN if Groq is blocked.";
      }
      
      return "Error: Please check your internet connection.";
    }
    return "Error: Unexpected response format.";
  }

  Future<String> grammarFix(String text) async {
    final prompt = "Fix the grammar and spelling while keeping the casual tone. Input: \"$text\". Only return the corrected text, nothing else.";
    return await _callGroq(prompt);
  }

  Future<String> translate(String text, String targetLang) async {
    final prompt = "Translate this text to $targetLang: \"$text\". Only return the translated text, nothing else.";
    return await _callGroq(prompt);
  }

  Future<String> addEmojis(String text) async {
    final prompt = "Add 1 relevant emoji to the end of this sentence: \"$text\". Return the sentence with emoji added.";
    return await _callGroq(prompt);
  }

  Future<List<String>> rephrase(String text) async {
    final prompt = """Rephrase the following sentence in 3 different ways: "$text". 
Instructions:
1. Provide exactly 3 options as a numbered list (1., 2., 3.).
2. Do NOT include markdown formatting (**).
3. Do NOT include tone labels.
4. Only return the content of the variations.
""";
    final result = await _callGroq(prompt);
    return result.split('\n')
        .where((s) => s.trim().isNotEmpty && (s.trim().startsWith('1.') || s.trim().startsWith('2.') || s.trim().startsWith('3.')))
        .map((s) => s.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .take(3)
        .toList();
  }

  Future<String> generateText(String prompt) async {
    return await _callGroq(prompt);
  }

  Future<String> aiAssist(String prompt) async {
    return await _callGroq(prompt);
  }

  Future<List<String>> aiAssistOptions(String prompt) async {
    final fullPrompt = """$prompt.
Instructions:
1. Provide exactly 3 distinct versions as a numbered list (1., 2., 3.).
2. Do NOT include markdown formatting (**).
3. Do NOT include titles or labels.
4. Keep each option concise.
5. Only return the generated text.
""";
    final result = await _callGroq(fullPrompt);
    return result.split('\n')
        .where((s) => s.trim().isNotEmpty && (s.trim().startsWith('1.') || s.trim().startsWith('2.') || s.trim().startsWith('3.')))
        .map((s) => s.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .take(3)
        .toList();
  }

  Future<List<String>> summarizeOptions(String text) async {
    final prompt = """Summarize the following text in 3 distinct versions:
1. Neutral Tone
2. Positive Tone
3. Professional Tone

Input Text: "$text"

Instructions:
1. Provide exactly 3 options as a numbered list (1., 2., 3.).
2. Prefix each option with its tone name and a colon (e.g., 'Neutral:', 'Positive:', 'Professional:').
3. Do NOT include markdown formatting (**).
4. Keep each summary very concise.
5. Only return the generated text.
""";
    final result = await _callGroq(prompt);
    return result.split('\n')
        .where((s) => s.trim().isNotEmpty && (s.trim().startsWith('1.') || s.trim().startsWith('2.') || s.trim().startsWith('3.')))
        .map((s) => s.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .take(3)
        .toList();
  }

  Future<String> summarize(String text) async {
    final prompt = "Summarize the following text concisely: \"$text\". Only return the summary, nothing else.";
    return await _callGroq(prompt);
  }
}
