import 'package:agora_chat_callkit/agora_chat_callkit.dart';

class AgoraChatCallKitEvent {
  AgoraChatCallKitEvent({
    required this.onError,
    required this.onCallEnd,
    this.onJoinedChannel,
  });
  final void Function(AgoraChatCallError error) onError;
  final void Function(AgoraChatCallEndReason reason) onCallEnd;
  final void Function(String channel, String userId, int? agoraUid)?
      onJoinedChannel;
}
