import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../providers/keyboard_provider.dart';

class VoiceInputDialog extends StatefulWidget {
  final Function(String) onResult;
  final VoidCallback onCancel;
  final String partialTranscription;
  final VoiceState voiceState;

  const VoiceInputDialog({
    super.key,
    required this.onResult,
    required this.onCancel,
    this.partialTranscription = "",
    this.voiceState = VoiceState.preparing,
  });

  @override
  State<VoiceInputDialog> createState() => _VoiceInputDialogState();
}

class _VoiceInputDialogState extends State<VoiceInputDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcription = widget.partialTranscription;
    final state = widget.voiceState;
    
    String statusText;
    bool isListening = false;
    
    switch (state) {
      case VoiceState.preparing:
        statusText = "Initializing...";
        break;
      case VoiceState.ready:
        statusText = "Ready to speak";
        break;
      case VoiceState.listening:
        statusText = "Listening...";
        isListening = true;
        break;
      case VoiceState.processing:
        statusText = "Processing...";
        break;
      case VoiceState.done:
        statusText = "Done!";
        break;
      case VoiceState.error:
        statusText = "Error";
        break;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A).withOpacity(0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),

          // Cancel button
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, top: 0),
              child: IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: widget.onCancel,
              ),
            ),
          ),

          // Mic and Status section
          Flexible(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated microphone icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isListening
                                ? [
                                    const Color(0xFF6366F1),
                                    const Color(0xFF818CF8),
                                  ]
                                : [
                                    Colors.grey.shade700,
                                    Colors.grey.shade600,
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isListening
                                  ? const Color(0xFF6366F1).withOpacity(0.4)
                                  : Colors.transparent,
                              blurRadius: 10 + (_pulseController.value * 8),
                              spreadRadius: 1 + (_pulseController.value * 3),
                            ),
                          ],
                        ),
                        child: state == VoiceState.processing
                            ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                state == VoiceState.done ? Icons.check : Icons.mic,
                                size: 30,
                                color: Colors.white,
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                // Status text
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 4),

                // Waveform animation
                if (isListening)
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final delay = index * 0.2;
                            final animValue = (_pulseController.value + delay) % 1.0;
                            final height = 6 + (math.sin(animValue * math.pi * 2) * 8);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 2.5,
                              height: height.abs(),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF818CF8),
                                    Color(0xFF6366F1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(1.25),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),

          // Transcription display section
          if (transcription.isNotEmpty)
            Flexible(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    transcription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          
        ],
      ),
    );
  }
}
