import 'dart:math';

class AgoraChatCallKitTools {
  static String get randomStr {
    return "flutter_${Random().nextInt(99999999).toString()}";
  }
}
