import 'package:flutter/material.dart';
import '../../providers/keyboard_provider.dart';

class AIToolbar extends StatelessWidget {
  final KeyboardProvider provider;
  final VoidCallback onGrammarFix;
  final VoidCallback onTranslate;
  final VoidCallback onAddEmojis;
  final VoidCallback onAIAssist;
  final VoidCallback onAppsMenu;
  final VoidCallback onVoiceInput;
  final VoidCallback onMagicPressed;

  const AIToolbar({
    super.key,
    required this.provider,
    this.onGrammarFix = _empty,
    this.onTranslate = _empty,
    this.onAddEmojis = _empty,
    this.onAIAssist = _empty,
    this.onAppsMenu = _empty,
    this.onVoiceInput = _empty,
    this.onMagicPressed = _empty,
  });

  static void _empty() {}

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Row(
        children: [
          _buildToolbarIcon(
            Icons.grid_view_rounded,
            onAppsMenu,
          ),
          _buildToolbarIcon(
            Icons.spellcheck,
            onGrammarFix,
          ),
          _buildToolbarIcon(
            Icons.translate,
            onTranslate,
          ),
          _buildToolbarIcon(
            Icons.emoji_emotions_outlined,
            onAddEmojis,
          ),
          _buildToolbarIcon(
            Icons.auto_awesome,
            onAIAssist,
          ),
          if (provider.selectedText.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildToolbarIcon(
              Icons.auto_fix_high_rounded,
              onMagicPressed,
              isActive: provider.mode == KeyboardMode.magic,
            ),
          ],
          const Spacer(),
          _buildToolbarIcon(
            Icons.mic_none_rounded,
            onVoiceInput,
            isActive: provider.isRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return IconButton(
      icon: Icon(
        icon,
        size: 22,
        color: isActive ? const Color(0xFF8AB4F8) : Colors.white70,
      ),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}
