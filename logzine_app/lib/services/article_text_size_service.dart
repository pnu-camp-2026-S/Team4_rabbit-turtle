import 'package:flutter/foundation.dart';

/// Reader article body text size setting.
///
/// Step 2 preserves the current reader body size.
class ArticleTextSizeService {
  const ArticleTextSizeService._();

  static const int minStep = 1;
  static const int defaultStep = 2;
  static const int maxStep = 3;

  static final ValueNotifier<int> step = ValueNotifier<int>(defaultStep);

  static int get currentStep => step.value;

  static void setStep(int value) {
    final int next = value.clamp(minStep, maxStep);
    if (step.value == next) return;
    step.value = next;
  }

  static double fontSizeForStep(int value) {
    switch (value.clamp(minStep, maxStep)) {
      case 1:
        return 14;
      case 3:
        return 16;
      case 2:
      default:
        return 15;
    }
  }
}
