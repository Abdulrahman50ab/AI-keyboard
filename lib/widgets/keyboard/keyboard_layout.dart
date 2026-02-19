import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/keyboard_provider.dart';
import '../../core/layouts.dart';
import 'key_button.dart';
import 'ai_toolbar.dart';

class KeyboardLayout extends StatelessWidget {
  const KeyboardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context);

    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info Message or AI Result
          if (provider.infoMessage != null)
            Container(
              color: Colors.blue.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                      child: Text(provider.infoMessage!,
                          style: const TextStyle(color: Colors.white))),
                  IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                      onPressed: provider.clearCallback)
                ],
              ),
            ),

          // Tools
          AIToolbar(provider: provider),

          // Main Content (Keyboard or AI Results)
          if (provider.mode == KeyboardMode.rephrase)
            _buildRephraseList(context, provider)
          else if (provider.mode == KeyboardMode.translate)
            _buildTranslationResult(context, provider)
          else
            _buildKeyboard(context, provider),
        ],
      ),
    );
  }

  Widget _buildKeyboard(BuildContext context, KeyboardProvider provider) {
    List<List<String>> layout;
    switch (provider.language) {
      case KeyboardLanguage.urdu:
        layout = KeyboardLayouts.urdu;
        break;
      case KeyboardLanguage.arabic:
        layout = KeyboardLayouts.arabic;
        break;
      default:
        layout = KeyboardLayouts.english;
    }

    // Capitalize if shift is on
    if (provider.isShift || provider.isCaps) {
      layout = layout
          .map((row) => row.map((c) => c.toUpperCase()).toList())
          .toList();
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          ...layout
              .sublist(0, layout.length - 1)
              .map((row) => _buildRow(row, provider)),
          // Last row with Shift and Delete
          Row(
            children: [
              KeyButton(
                label: "",
                icon: provider.isCaps
                    ? Icons.keyboard_capslock
                    : Icons.arrow_upward,
                isSpecial: true,
                backgroundColor:
                    provider.isShift ? const Color(0xFF238636) : null,
                onTap: provider.toggleShift,
                flex: 1.5,
              ),
              ...layout.last.map((char) => KeyButton(
                  label: char, onTap: () => provider.insertText(char))),
              KeyButton(
                label: "",
                icon: Icons.backspace_outlined,
                isSpecial: true,
                onTap: provider.backspace,
                flex: 1.5,
              ),
            ],
          ),
          // Space bar row
          Row(
            children: [
              KeyButton(label: "123", isSpecial: true, onTap: () {}, flex: 1.5),
              KeyButton(
                label: provider.language.name.toUpperCase(),
                isSpecial: true,
                onTap: provider.cycleLanguage,
                flex: 1.0,
              ),
              KeyButton(
                  label: "Space",
                  isSpecial: false,
                  onTap: () => provider.insertText(" "),
                  flex: 4.0),
              KeyButton(
                  label: ".",
                  isSpecial: true,
                  onTap: () => provider.insertText(".")),
              KeyButton(
                  label: "Enter",
                  icon: Icons.keyboard_return,
                  isSpecial: true,
                  backgroundColor: const Color(0xFF238636),
                  onTap: () => provider.insertText("\n"),
                  flex: 1.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys, KeyboardProvider provider) {
    return Row(
      children: keys
          .map((char) => KeyButton(
                label: char,
                onTap: () => provider.insertText(char),
              ))
          .toList(),
    );
  }

  Widget _buildRephraseList(BuildContext context, KeyboardProvider provider) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Text("Select option:", style: TextStyle(color: Colors.white70)),
          Expanded(
            child: ListView(
              children: provider.rephraseOptions
                  .map((opt) => ListTile(
                        title: Text(opt,
                            style: const TextStyle(color: Colors.white)),
                        onTap: () => provider.applyRephrase(opt),
                        tileColor: const Color(0xFF21262D),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                      ))
                  .toList(),
            ),
          ),
          TextButton(
              onPressed: () => provider.setMode(KeyboardMode.normal),
              child: const Text("Cancel"))
        ],
      ),
    );
  }

  Widget _buildTranslationResult(
      BuildContext context, KeyboardProvider provider) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Translation:", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(8)),
            child: Text(provider.translatedText,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: () => provider.setMode(KeyboardMode.normal),
                  child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: () =>
                      provider.applyRephrase(provider.translatedText),
                  child: const Text("Use")),
            ],
          )
        ],
      ),
    );
  }
}
