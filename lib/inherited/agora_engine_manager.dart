import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:flutter/material.dart';

class RTCOptions {
  final AudioScenarioType? audioScenarioType;
  final ChannelProfileType? channelProfile;
  final int? areaCode;
  final VideoEncoderConfiguration? videoEncoderConfig;
  final AudioSessionOperationRestriction? audioSessionOperationRestriction;

  RTCOptions({
    this.audioScenarioType,
    this.channelProfile,
    this.areaCode,
    this.videoEncoderConfig,
    this.audioSessionOperationRestriction,
  });
}

class RTCEventHandler {
  RTCEventHandler({
    this.onError,
    this.onJoinChannelSuccess,
    this.onLeaveChannel,
    this.onUserJoined,
    this.onUserLeaved,
    this.onUserMuteVideo,
    this.onUserMuteAudio,
    this.onFirstRemoteVideoDecoded,
    this.onRemoteVideoStateChanged,
    this.onActiveSpeaker,
  });

  final void Function(
    ErrorCodeType err,
    String msg,
  )? onError;

  final VoidCallback? onJoinChannelSuccess;
  final VoidCallback? onLeaveChannel;
  final void Function(int remoteUid)? onUserJoined;
  final void Function(int userId)? onUserLeaved;
  final void Function(int remoteUid, bool muted)? onUserMuteVideo;
  final void Function(int remoteUid, bool muted)? onUserMuteAudio;
  final void Function(int remoteUid, int width, int height)?
      onFirstRemoteVideoDecoded;
  final void Function(
          int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason)?
      onRemoteVideoStateChanged;
  final void Function(int uid)? onActiveSpeaker;
}

class AgoraEngineManager {
  AgoraEngineManager(
    this.handler,
  ) {
    _handler = RtcEngineEventHandler(
      onError: handler.onError,
      onJoinChannelSuccess: (connection, elapsed) {
        handler.onJoinChannelSuccess?.call();
      },
      onLeaveChannel: (connection, stats) {
        handler.onLeaveChannel?.call();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        handler.onUserJoined?.call(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        handler.onUserLeaved?.call(remoteUid);
      },
      onUserMuteVideo: (
        connection,
        remoteUid,
        muted,
      ) {
        handler.onUserMuteVideo?.call(remoteUid, muted);
      },
      onUserMuteAudio: (
        connection,
        remoteUid,
        muted,
      ) {
        handler.onUserMuteAudio?.call(remoteUid, muted);
      },
      onFirstRemoteVideoDecoded: (
        connection,
        remoteUid,
        width,
        height,
        elapsed,
      ) {
        handler.onFirstRemoteVideoDecoded?.call(remoteUid, width, height);
      },
      onRemoteVideoStateChanged: (
        connection,
        remoteUid,
        state,
        reason,
        elapsed,
      ) {
        handler.onRemoteVideoStateChanged?.call(remoteUid, state, reason);
      },
      onActiveSpeaker: (
        connection,
        uid,
      ) {
        handler.onActiveSpeaker?.call(uid);
      },
    );
  }
  bool _engineHasInit = false;
  RTCOptions? options;
  String? agoraAppId;
  late RtcEngine _engine;
  final RTCEventHandler handler;
  RtcEngineEventHandler? _handler;
  Future<void> initEngine() async {
    if (_engineHasInit) return;
    _engineHasInit = true;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: agoraAppId,
      audioScenario: options?.audioScenarioType,
      channelProfile: options?.channelProfile,
      areaCode: options?.areaCode,
    ));
    _engine.unregisterEventHandler(_handler!);
    _engine.registerEventHandler(_handler!);
    _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
  }

  Future<void> releaseEngine() async {
    if (_engineHasInit) {
      _engine.unregisterEventHandler(_handler!);
      _engineHasInit = false;
      await _engine.release();
    }
  }

  void dispose() {
    releaseEngine();
  }

  Future<void> joinChannel(
    AgoraChatCallType type,
    String token,
    String channel,
    int uid,
  ) async {
    await initEngine();

    if (type == AgoraChatCallType.audio_1v1) {
      await enableAudio();
    } else if (type == AgoraChatCallType.multi) {
    } else if (type == AgoraChatCallType.video_1v1) {}

    debugPrint("will join channel $channel");
    await _engine.joinChannel(
        token: token,
        channelId: channel,
        uid: uid,
        options: const ChannelMediaOptions());
  }

  Future<void> leaveChannel() async {
    if (!_engineHasInit) return;
    await _engine.leaveChannel();
  }

  Future<void> clearCurrentCallInfo() async {
    await leaveChannel();
    await stopPreview();
    await disableAudio();
    await releaseEngine();
  }
}

extension EngineActions on AgoraEngineManager {
  Future<void> enableVideo(int uid) async {
    if (!_engineHasInit) return;
    await _engine.enableVideo();
  }

  Future<void> disableVideo(int uid) async {
    if (!_engineHasInit) return;
    await _engine.disableVideo();
  }

  Future<void> enableAudio() async {
    if (!_engineHasInit) return;
    await _engine.enableAudio();
  }

  Future<void> disableAudio() async {
    if (!_engineHasInit) return;
    await _engine.disableAudio();
  }

  Future<void> mute() async {
    if (!_engineHasInit) return;
    await _engine.muteLocalAudioStream(true);
  }

  Future<void> unMute() async {
    if (!_engineHasInit) return;
    await _engine.muteLocalAudioStream(false);
  }

  Future<void> startPreview() async {
    if (!_engineHasInit) return;
    await _engine.startPreview();
  }

  Future<void> stopPreview() async {
    if (!_engineHasInit) return;
    await _engine.stopPreview();
  }

  Widget? remoteView(int agoraUid, String channel) {
    if (!_engineHasInit) return null;
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: agoraUid),
        connection: RtcConnection(channelId: channel),
      ),
    );
  }

  Widget? localView() {
    if (!_engineHasInit) return null;
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }
}
