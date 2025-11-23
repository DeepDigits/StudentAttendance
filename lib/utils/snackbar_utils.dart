import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Import Fluttertoast

// Rename the class to reflect its new purpose
class ToastUtils {
  // Method for showing success toast
  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
        // Prepend success icon character
        msg: "✅  $message",
        toastLength: Toast.LENGTH_SHORT, // Duration (SHORT or LONG)
        gravity: ToastGravity.BOTTOM, // Position (BOTTOM, CENTER, TOP)
        timeInSecForIosWeb: 1, // iOS/Web specific duration
        backgroundColor: Colors.green[600], // Success color
        textColor: Colors.white, // Text color
        fontSize: 16.0 // Font size
        );
  }

  // Method for showing error toast
  static void showErrorToast(String message) {
    Fluttertoast.showToast(
        // Prepend error icon character
        msg: "❌  $message",
        toastLength: Toast.LENGTH_LONG, // Show errors for a bit longer
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red[600], // Error color
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
