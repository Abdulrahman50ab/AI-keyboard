import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Smarti AI Keyboard Assistant',
          style: TextStyle(
            color: Colors.black, // Dark text for visibility
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Hero Title
            const Text(
              'Smarti AI\nKeyboard Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.orange,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type smarter. Enhance messages with AI. Seamless Android integration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 28),

            // Enable button
            Obx(
              () => ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.isPermissionGranted.value
                      ? Colors.green
                      : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: controller.isPermissionGranted.value
                    ? null
                    : controller.requestKeyboardPermission,
                icon: Icon(
                  controller.isPermissionGranted.value
                      ? Icons.check_circle
                      : Icons.keyboard,
                ),
                label: Text(
                  controller.isPermissionGranted.value
                      ? 'Keyboard Permission Granted'
                      : 'Enable Smarti Keyboard',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Status
            Obx(
              () => Text(
                controller.statusMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: controller.isPermissionGranted.value
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Steps Card
            Card(
              color: Colors.grey.shade100,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'How to enable Smarti Keyboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "Enable Smarti Keyboard"'),
                    Text('2. Go to Settings > System > Languages & input'),
                    Text('3. Open On-screen keyboard > Enable "Smarti Keyboard"'),
                    Text('4. Optionally set as default keyboard'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Footer
            const Text(
              'Privacy-first • No background tracking • Fast & minimal',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
