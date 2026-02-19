import 'package:flutter/material.dart';
import '../widgets/keyboard/keyboard_layout.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Keyboard Preview")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white10,
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: "Type here to test the keyboard...",
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          // In a real system keyboard, this widget is rendered by the OS.
          // Here we show it for demo purposes at the bottom.
          const KeyboardLayout(),
        ],
      ),
    );
  }
}
