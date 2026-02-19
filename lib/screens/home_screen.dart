import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const platform = MethodChannel('com.example.keyboard/setup');

  Future<void> _enableKeyboard() async {
    try {
      await platform.invokeMethod('openKeyboardSettings');
    } catch (e) {
      debugPrint("Error opening keyboard settings: $e");
    }
  }

  Future<void> _selectKeyboard() async {
    try {
      await platform.invokeMethod('showKeyboardPicker');
    } catch (e) {
      debugPrint("Error showing keyboard picker: $e");
    }
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final bool? granted = await platform.invokeMethod('requestMicrophonePermission');
      if (granted == true) {
        debugPrint("Microphone permission granted");
      } else {
        debugPrint("Microphone permission denied");
      }
    } catch (e) {
      debugPrint("Error requesting microphone permission: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Request microphone permission on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestMicrophonePermission();
    });
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside TextField
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A).withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildStepCard(
                      step: "1",
                      title: "Enable Keyboard",
                      subtitle: "Turn on AI Keyboard in settings",
                      icon: Icons.toggle_on_outlined,
                      onTap: _enableKeyboard,
                      color: const Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 16),
                    _buildStepCard(
                      step: "2",
                      title: "Select Keyboard",
                      subtitle: "Switch to AI Keyboard as default",
                      icon: Icons.keyboard_outlined,
                      onTap: _selectKeyboard,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 16),
                    _buildTestInputCard(),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 64,
            color: Color(0xFF818CF8),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "AI Keyboard Assistant",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Types smarter, faster, and better with AI",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white60,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(icon, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestInputCard() {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      "3",
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Test Your Keyboard",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Try it out instantly",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, color: Colors.white24),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: false,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Tap here to test your keyboard...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
