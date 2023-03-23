import 'package:agora_chat_callkit/agora_chat_callkit.dart';

class AgoraChatCallKitEvent {
  AgoraChatCallKitEvent({
    required this.onError,
    required this.onCallEnd,
  });
  final void Function(AgoraChatCallError error) onError;
  final void Function(AgoraChatCallEndReason reason) onCallEnd;
}
