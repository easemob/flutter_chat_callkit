import 'package:agora_chat_callkit/agora_chat_callkit.dart';

class AgoraChatCallKitEventHandler {
  AgoraChatCallKitEventHandler({
    this.onError,
    this.onCallEnd,
    this.onReceiveCall,
    this.onJoinedChannel,
    this.onUserLeaved,
    this.onUserJoined,
    this.onFirstRemoteVideoDecoded,
    this.onUserMuteAudio,
    this.onUserMuteVideo,
    this.onActiveSpeaker,
    this.onUserRemoved,
  });
  final void Function(AgoraChatCallError error)? onError;

  final void Function(String callId, AgoraChatCallEndReason reason)? onCallEnd;

  final void Function(int agoraUid, String? userId)? onUserLeaved;

  final void Function(int agoraUid, String? userId, int width, int height)?
      onFirstRemoteVideoDecoded;

  final void Function(int agoraUid, String? userId)? onActiveSpeaker;

  final void Function(int agoraUid, String? userId)? onUserJoined;

  final void Function(String channel)? onJoinedChannel;

  final void Function(String userId, String callId, AgoraChatCallType callType,
      Map<String, String>? ext)? onReceiveCall;

  final void Function(int agoraUid, bool muted)? onUserMuteAudio;
  final void Function(int agoraUid, bool muted)? onUserMuteVideo;
  final void Function(
          String callId, String userId, AgoraChatCallEndReason reason)?
      onUserRemoved;
}
