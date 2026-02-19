import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  static const platform = MethodChannel('custom_keyboard/keyboard');
  
  final textController = TextEditingController();
  final isPermissionGranted = false.obs;
  final statusMessage = 'Tap the button to enable Smarti Keyboard'.obs;

  @override
  void onInit() {
    super.onInit();
    checkKeyboardPermission();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> checkKeyboardPermission() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isKeyboardEnabled');
      isPermissionGranted.value = isEnabled;
      if (isEnabled) {
        statusMessage.value = 'Smarti Keyboard is enabled and ready to use!';
      } else {
        statusMessage.value = 'Smarti Keyboard is not enabled. Tap the button to enable it.';
      }
    } catch (e) {
      statusMessage.value = 'Error checking keyboard status: $e';
    }
  }

  Future<void> requestKeyboardPermission() async {
    try {
      statusMessage.value = 'Opening keyboard settings...';
      await platform.invokeMethod('openKeyboardSettings');
      
      // Wait a bit and then check again
      await Future.delayed(const Duration(seconds: 2));
      await checkKeyboardPermission();
    } catch (e) {
      statusMessage.value = 'Error opening keyboard settings: $e';
      Get.snackbar(
        'Error',
        'Failed to open keyboard settings. Enable manually in Settings > System > Languages & input > On-screen keyboard, then enable "Smarti Keyboard".',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void onTextFieldTapped() {
    if (!isPermissionGranted.value) {
      Get.snackbar(
        'Smarti Keyboard Not Enabled',
        'Please enable Smarti Keyboard first by tapping the button above.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }
}
