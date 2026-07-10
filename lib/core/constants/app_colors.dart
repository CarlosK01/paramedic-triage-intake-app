import 'package:flutter/material.dart';

/// Centralised colour handling for the app, in particular the
/// priority-level hazard colour coding used throughout the UI.
class AppColors {
  AppColors._();

  static const Color priority1 = Color(0xFFB71C1C); // deep red - critical
  static const Color priority2 = Color(0xFFEF6C00); // orange
  static const Color priority3 = Color(0xFFF9A825); // amber
  static const Color priority4 = Color(0xFF1565C0); // blue
  static const Color priority5 = Color(0xFF2E7D32); // green

  static const Color surface = Color(0xFFF5F7FA);
  static const Color pendingBadge = Color(0xFF9E9E9E);
  static const Color syncedBadge = Color(0xFF2E7D32);

  /// Returns the hazard colour associated with a given [priority] level
  /// (1 = most critical, 5 = least critical). Falls back to a neutral grey
  /// for any out-of-range value so the UI never crashes on bad data.
  static Color forPriority(int priority) {
    switch (priority) {
      case 1:
        return priority1;
      case 2:
        return priority2;
      case 3:
        return priority3;
      case 4:
        return priority4;
      case 5:
        return priority5;
      default:
        return Colors.grey;
    }
  }

  static String labelForPriority(int priority) {
    switch (priority) {
      case 1:
        return 'P1 - Critical';
      case 2:
        return 'P2 - Severe';
      case 3:
        return 'P3 - Moderate';
      case 4:
        return 'P4 - Minor';
      case 5:
        return 'P5 - Stable';
      default:
        return 'Unknown';
    }
  }
}
