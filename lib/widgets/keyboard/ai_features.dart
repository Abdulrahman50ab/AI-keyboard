import 'package:flutter/material.dart';
import '../../providers/keyboard_provider.dart';

class RephraseUI extends StatelessWidget {
  final KeyboardProvider provider;
  final Function(String) onOptionSelected;

  const RephraseUI({
    super.key,
    required this.provider,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 38, // Slightly tighter
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Text(provider.aiTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => provider.setMode(KeyboardMode.normal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: provider.rephraseOptions.length,
            itemBuilder: (context, index) {
              final option = provider.rephraseOptions[index];
              String? label;
              String content = option;

              if (option.contains(':') && option.indexOf(':') < 20) {
                final parts = option.split(':');
                label = parts[0].trim();
                content = parts.sublist(1).join(':').trim();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => onOptionSelected(content),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C4043),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        Text(
                          content,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TranslateUI extends StatelessWidget {
  final KeyboardProvider provider;
  final VoidCallback onUseTranslation;

  const TranslateUI({
    super.key,
    required this.provider,
    required this.onUseTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.translate, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              const Text("Translation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => provider.setMode(KeyboardMode.normal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3C4043),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    provider.translatedText.isNotEmpty ? provider.translatedText : "Loading...",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: provider.translatedText.isNotEmpty ? onUseTranslation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8AB4F8),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
                child: const Text("Use Translation"),
              ),
            ],
          ),
        ),
      ),
      ],
    );
  }
}
class MagicMenuUI extends StatelessWidget {
  final KeyboardProvider provider;
  final VoidCallback onRephrase;
  final VoidCallback onSummarize;
  final VoidCallback onGrammarFix;
  final VoidCallback onTranslate;

  const MagicMenuUI({
    super.key,
    required this.provider,
    required this.onRephrase,
    required this.onSummarize,
    required this.onGrammarFix,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_fix_high, color: Color(0xFF8AB4F8), size: 16),
              const SizedBox(width: 8),
              const Text("Magic Selection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => provider.setMode(KeyboardMode.normal),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMagicCard(
                          icon: Icons.refresh_rounded,
                          label: "Rephrase",
                          description: "Alternatives",
                          onTap: onRephrase,
                        ),
                      ),
                      const SizedBox(width: 8), // Tighter gap
                      Expanded(
                        child: _buildMagicCard(
                          icon: Icons.short_text_rounded,
                          label: "Summarize",
                          description: "Concise",
                          onTap: onSummarize,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMagicCard(
                          icon: Icons.spellcheck_rounded,
                          label: "Fix Grammar",
                          description: "Correct",
                          onTap: onGrammarFix,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMagicCard(
                          icon: Icons.translate_rounded,
                          label: "Translate",
                          description: provider.targetLanguages.length == 1 
                              ? "To ${provider.targetLanguages.first}" 
                              : "Pick Language",
                          onTap: onTranslate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMagicCard({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF3C4043),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
