import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/keyboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cache_manager;
import 'keyboard_key.dart';

class PickerBottomBar extends StatelessWidget {
  final VoidCallback onBackToKeyboard;
  final VoidCallback onDelete;
  final VoidCallback? onSearch;

  const PickerBottomBar({
    super.key,
    required this.onBackToKeyboard,
    required this.onDelete,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Row(
        children: [
          SpecialKey(
            label: 'ABC',
            onPressed: onBackToKeyboard,
            flex: 20,
          ),
          const Spacer(flex: 40),
          SpecialKey(
            icon: Icons.backspace_rounded,
            onPressed: onDelete,
            flex: 20,
          ),
          if (onSearch != null)
            SpecialKey(
              icon: Icons.search_rounded,
              backgroundColor: const Color(0xFF8AB4F8),
              iconColor: Colors.black87,
              onPressed: onSearch!,
              flex: 20,
            ),
        ],
      ),
    );
  }
}

class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              HapticFeedback.selectionClick();
              onEmojiSelected(emoji.emoji);
            },
            config: Config(
              height: 256,
              checkPlatformCompatibility: true,
              emojiViewConfig: EmojiViewConfig(
                emojiSizeMax: 28,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                gridPadding: EdgeInsets.zero,
                backgroundColor: const Color(0xFF1E1E1E),
                columns: 8,
                buttonMode: ButtonMode.MATERIAL,
              ),
              categoryViewConfig: const CategoryViewConfig(
                iconColor: Colors.white38,
                iconColorSelected: Color(0xFF8AB4F8),
                backspaceColor: Color(0xFF8AB4F8),
                backgroundColor: Color(0xFF1E1E1E),
                indicatorColor: Color(0xFF8AB4F8),
              ),
              bottomActionBarConfig: const BottomActionBarConfig(
                enabled: false, // We use our custom bottom bar
              ),
              searchViewConfig: const SearchViewConfig(
                backgroundColor: Color(0xFF1E1E1E),
                buttonIconColor: Colors.white38,
              ),
            ),
          ),
        ),
        PickerBottomBar(
          onBackToKeyboard: onBack,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class StickerPickerWidget extends StatelessWidget {
  final Function(String) onStickerSelected;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const StickerPickerWidget({
    super.key,
    required this.onStickerSelected,
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context);

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: provider.isLoadingGiphy
              ? const Center(child: CircularProgressIndicator())
              : provider.giphyResults.isEmpty
                  ? const Center(child: Text("No stickers found", style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: provider.giphyResults.length,
                      itemBuilder: (context, index) {
                        final url = provider.giphyResults[index];
                        return GestureDetector(
                          onTap: () async {
                            // Optimistically try to get the file from cache
                            final file = await cache_manager.DefaultCacheManager().getSingleFile(url);
                            provider.sendMedia(file.path, 'image/webp'); 
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Container(
                                color: Colors.white12,
                                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        PickerBottomBar(
          onBackToKeyboard: onBack,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class GifPickerWidget extends StatelessWidget {
  final Function(String)? onGifSelected;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const GifPickerWidget({
    super.key,
    this.onGifSelected,
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KeyboardProvider>(context);

    return Column(
      children: [
        const SizedBox(height: 8),
        Expanded(
          child: provider.isLoadingGiphy
              ? const Center(child: CircularProgressIndicator())
              : provider.giphyResults.isEmpty
                  ? const Center(child: Text("No GIFs found", style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: provider.giphyResults.length,
                      itemBuilder: (context, index) {
                        final url = provider.giphyResults[index];
                        return GestureDetector(
                          onTap: () async {
                            debugPrint("GIF Selected: $url");
                            // Optimistically try to get the file from cache
                            final file = await cache_manager.DefaultCacheManager().getSingleFile(url);
                            provider.sendMedia(file.path, 'image/gif');
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.white12,
                                child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white24),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        PickerBottomBar(
          onBackToKeyboard: onBack,
          onDelete: onDelete,
        ),
      ],
    );
  }
}
