import 'package:agora_chat_callkit/agora_chat_callkit.dart';

/// Agora chat callkit error.
class AgoraChatCallError implements Exception {
  factory AgoraChatCallError.process(int code, String desc) {
    return AgoraChatCallError._(AgoraChatCallErrorType.process, code, desc);
  }

  factory AgoraChatCallError.im(int code, String desc) {
    return AgoraChatCallError._(AgoraChatCallErrorType.im, code, desc);
  }

  factory AgoraChatCallError.rtc(int code, String desc) {
    return AgoraChatCallError._(AgoraChatCallErrorType.rtc, code, desc);
  }

  AgoraChatCallError._(this.type, this.code, this.errDescription);
  final AgoraChatCallErrorType type;
  final int code;
  final String errDescription;
}
