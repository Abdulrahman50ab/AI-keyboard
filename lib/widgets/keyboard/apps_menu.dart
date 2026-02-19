import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/keyboard_provider.dart';
import '../../core/keyboard_theme.dart';
import '../../utils/keyboard_constants.dart';

// Force reload after import fix
class AppsMenuSheet extends StatelessWidget {
  final VoidCallback onGifs;
  final VoidCallback onStickers;
  final VoidCallback onTheme;
  final VoidCallback onPaste;

  const AppsMenuSheet({
    super.key,
    required this.onGifs,
    required this.onStickers,
    required this.onTheme,
    required this.onPaste,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          _buildHeader(context, "Apps Menu", () => provider.setMode(KeyboardMode.normal)),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _buildMenuItem(
                  Icons.gif_box_outlined,
                  'GIFs',
                  const Color(0xFFE91E63),
                  onGifs,
                ),
                _buildMenuItem(
                  Icons.content_paste_rounded,
                  'Clipboard',
                  const Color(0xFF2196F3),
                  onPaste,
                ),
                _buildMenuItem(
                  Icons.palette_outlined,
                  'Themes',
                  const Color(0xFFFF9800),
                  onTheme,
                ),
                _buildMenuItem(
                  Icons.grid_view_rounded,
                  'Stickers',
                  const Color(0xFF4CAF50),
                  onStickers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, VoidCallback onBack) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeMenuSheet extends StatelessWidget {
  const ThemeMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          _buildHeader("Keyboard Themes", () => provider.setMode(KeyboardMode.apps)),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              itemCount: KeyboardTheme.themes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final theme = KeyboardTheme.themes[index];
                final isSelected = provider.currentTheme == theme;
                
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setTheme(theme);
                    provider.setMode(KeyboardMode.normal);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected 
                          ? Border.all(color: Colors.blueAccent, width: 2) 
                          : Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPreviewKey(theme.keyColor),
                            const SizedBox(width: 4),
                            _buildPreviewKey(theme.keyColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildPreviewKey(theme.specialKeyColor, width: 36),
                        const SizedBox(height: 8),
                        Text(
                          theme.name,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, VoidCallback onBack) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreviewKey(Color color, {double width = 16}) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
class ClipboardHistorySheet extends StatelessWidget {
  final Function(String) onItemSelected;

  const ClipboardHistorySheet({
    super.key,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context);
    final history = provider.clipboardHistory;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          _buildHeader("Clipboard History", () => provider.setMode(KeyboardMode.apps)),
          if (history.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.content_paste_off_rounded, 
                      color: Colors.white24, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'No items copied yet',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                itemCount: history.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = history[index];
                  return InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onItemSelected(item);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, 
                            color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.replaceAll('\n', ' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, 
                            color: Colors.white24, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, VoidCallback onBack) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
