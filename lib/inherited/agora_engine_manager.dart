import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:flutter/foundation.dart';

class EngineOptions {
  final String agoraAppId;
  final AudioScenarioType? audioScenarioType;
  final ChannelProfileType? channelProfile;
  final int? areaCode;
  final VideoEncoderConfiguration? videoEncoderConfig;
  final AudioSessionOperationRestriction? audioSessionOperationRestriction;

  EngineOptions({
    required this.agoraAppId,
    this.audioScenarioType,
    this.channelProfile,
    this.areaCode,
    this.videoEncoderConfig,
    this.audioSessionOperationRestriction,
  });
}

class AgoraRtcEngineEventHandler {
  AgoraRtcEngineEventHandler({
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
    this.options,
    this.eventHandler,
  ) {
    _handler = RtcEngineEventHandler(
      onError: eventHandler.onError,
      onJoinChannelSuccess: (connection, elapsed) =>
          eventHandler.onJoinChannelSuccess?.call(),
      onLeaveChannel: (connection, stats) =>
          eventHandler.onLeaveChannel?.call(),
      onUserJoined: (connection, remoteUid, elapsed) =>
          eventHandler.onUserJoined?.call(remoteUid),
      onUserOffline: (connection, remoteUid, reason) =>
          eventHandler.onUserLeaved?.call(remoteUid),
      onUserMuteVideo: (connection, remoteUid, muted) =>
          eventHandler.onUserMuteVideo?.call(remoteUid, muted),
      onUserMuteAudio: (connection, remoteUid, muted) =>
          eventHandler.onUserMuteAudio?.call(remoteUid, muted),
      onFirstRemoteVideoDecoded:
          (connection, remoteUid, width, height, elapsed) => eventHandler
              .onFirstRemoteVideoDecoded
              ?.call(remoteUid, width, height),
      onRemoteVideoStateChanged:
          (connection, remoteUid, state, reason, elapsed) => eventHandler
              .onRemoteVideoStateChanged
              ?.call(remoteUid, state, reason),
      onActiveSpeaker: (connection, uid) =>
          eventHandler.onActiveSpeaker?.call(uid),
    );
  }
  bool _engineHasInit = false;

  late RtcEngine _engine;
  final EngineOptions options;
  final AgoraRtcEngineEventHandler eventHandler;
  RtcEngineEventHandler? _handler;
  Future<void> initEngine() async {
    if (_engineHasInit) return;
    _engineHasInit = true;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: options.agoraAppId,
      audioScenario: options.audioScenarioType,
      channelProfile: options.channelProfile,
      areaCode: options.areaCode,
    ));
    _engine.unregisterEventHandler(_handler!);
    _engine.registerEventHandler(_handler!);
  }

  Future<void> releaseEngine() async {
    if (_engineHasInit) {
      _engine.unregisterEventHandler(_handler!);
      _engineHasInit = false;
      debugPrint("release!!!!");
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
      await enableAudioSpectrumMonitor();
    } else if (type == AgoraChatCallType.multi) {
    } else if (type == AgoraChatCallType.video_1v1) {}

    debugPrint("will join channel $channel");
    await _engine.joinChannel(
        token: token,
        channelId: channel,
        uid: uid,
        options: const ChannelMediaOptions());
  }

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

  Future<void> enableAudioSpectrumMonitor() async {
    if (!_engineHasInit) return;
    _engine.enableAudioSpectrumMonitor();
  }

  Future<void> disableAudioSpectrumMonitor() async {
    if (!_engineHasInit) return;
    _engine.disableAudioSpectrumMonitor();
  }

  Future<void> startPreview() async {
    if (!_engineHasInit) return;
    _engine.startPreview();
  }

  Future<void> stopPreview() async {
    if (!_engineHasInit) return;
    _engine.stopPreview();
  }

  Future<void> startLocalVideo() async {
    if (!_engineHasInit) return;
  }

  Future<void> stopLocalVideo() async {
    if (!_engineHasInit) return;
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
