import 'package:agora_chat_callkit/agora_chat_callkit.dart';

class AgoraChatCallKitEventHandler {
  AgoraChatCallKitEventHandler({
    required this.onError,
    required this.onCallEnd,
    required this.onReceiveCall,
    required this.rtcTokenHandler,
    this.onJoinedChannel,
    this.onUserLeave,
  });
  final void Function(AgoraChatCallError error) onError;

  final void Function(AgoraChatCallEndReason reason) onCallEnd;

  final void Function(String userId)? onUserLeave;

  final void Function(
    String channel,
    String userId,
    int? agoraUid,
  )? onJoinedChannel;

  final RtcTokenHandler rtcTokenHandler;

  final void Function(
    String userId,
    String callId,
    AgoraChatCallType callType,
    Map<String, String>? ext,
  ) onReceiveCall;
}
