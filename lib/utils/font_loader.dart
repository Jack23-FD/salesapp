import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FontLoader {
  static Future<void> loadFonts() async {
    // Pre-load and cache the Visby font
    final visbyRegular = rootBundle.load('fonts/Visby/VisbyRegular.otf');
    final visbyMedium = rootBundle.load('fonts/Visby/VisbyMedium.otf');
    final visbySemibold = rootBundle.load('fonts/Visby/VisbySemibold.otf');
    final visbyBold = rootBundle.load('fonts/Visby/VisbyBold.otf');

    // Pre-load and cache the Urbanist font
    final urbanistRegular =
        rootBundle.load('fonts/Urbanist/Urbanist-Regular.ttf');
    final urbanistMedium =
        rootBundle.load('fonts/Urbanist/Urbanist-Medium.ttf');
    final urbanistSemiBold =
        rootBundle.load('fonts/Urbanist/Urbanist-SemiBold.ttf');
    final urbanistBold = rootBundle.load('fonts/Urbanist/Urbanist-Bold.ttf');

    // Await all font loading operations
    await Future.wait([
      visbyRegular,
      visbyMedium,
      visbySemibold,
      visbyBold,
      urbanistRegular,
      urbanistMedium,
      urbanistSemiBold,
      urbanistBold
    ]);

    debugPrint('All custom fonts pre-loaded successfully');
  }
}
