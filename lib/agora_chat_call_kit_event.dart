import 'package:agora_chat_callkit/agora_chat_callkit.dart';

/// AgoraChatCallKit event handler.
class AgoraChatCallKitEventHandler {
  /// AgoraChatCallKit event handler.
  ///
  /// Param [onError] Call back when the call fails, See [AgoraChatCallError].
  ///
  /// Param [onCallEnd] Call back when the call ends, See [AgoraChatCallEndReason].
  ///
  /// Param [onReceiveCall] Call back when you receive a call invitation.
  ///
  /// Param [onJoinedChannel] The current user joins the call callback.
  ///
  /// Param [onUserLeaved] Call back when an active user leaves.
  ///
  /// Param [onUserJoined] Callback when a user joins a call.
  ///
  /// Param [onUserMuteAudio] Callback when the peer's mute status changes.
  ///
  /// Param [onUserMuteVideo] Callback when the peer's camera status changes.
  ///
  /// Param [onUserRemoved] Callback when the user rejects the call or the call times out.
  ///
  /// Param [onAnswer] Call back when the call is answered.
  ///
  AgoraChatCallKitEventHandler({
    this.onError,
    this.onCallEnd,
    this.onReceiveCall,
    this.onJoinedChannel,
    this.onUserLeaved,
    this.onUserJoined,
    this.onUserMuteAudio,
    this.onUserMuteVideo,
    this.onUserRemoved,
    this.onAnswer,
  });

  /// Call back when the call fails, See [AgoraChatCallError].
  final void Function(AgoraChatCallError error)? onError;

  /// Call back when the call ends, See [AgoraChatCallEndReason].
  final void Function(String? callId, AgoraChatCallEndReason reason)? onCallEnd;

  /// Call back when an active user leaves.
  final void Function(int agoraUid, String? userId)? onUserLeaved;

  /// Callback when a user joins a call.
  final void Function(int agoraUid, String? userId)? onUserJoined;

  /// The current user joins the call callback.
  final void Function(String channel)? onJoinedChannel;

  /// Call back when the call is answered.
  final void Function(String callId)? onAnswer;

  /// Call back when you receive a call invitation.
  final void Function(
    String userId,
    String callId,
    AgoraChatCallType callType,
    Map<String, String>? ext,
  )? onReceiveCall;

  /// Callback when the peer's mute status changes.
  final void Function(int agoraUid, bool muted)? onUserMuteAudio;

  /// Callback when the peer's camera status changes.
  final void Function(int agoraUid, bool muted)? onUserMuteVideo;

  /// Callback when the user rejects the call or the call times out.
  final void Function(
    String callId,
    String userId,
    AgoraChatCallEndReason reason,
  )? onUserRemoved;
}
