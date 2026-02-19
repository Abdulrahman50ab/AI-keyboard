import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle, // cleaner than borderRadius for perfect circle
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 3,
          ),
        ),
        // ← We create the colored "spinner arc" using a child instead
        child: Container(
          margin: const EdgeInsets.all(3), // = border width of background ring
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border(
              top: BorderSide(
                color: Color(0xFF58A6FF),
                width: 3,
              ),
            ),
          ),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 1.seconds),
    );
  }
}