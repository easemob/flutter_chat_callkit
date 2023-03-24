import 'package:agora_chat_callkit/agora_chat_callkit.dart';

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
    this.onUserOffline,
    this.onUserJoined,
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

  final void Function(
    RtcConnection connection,
    int elapsed,
  )? onJoinChannelSuccess;

  final void Function(
    RtcConnection connection,
    int elapsed,
    UserOfflineReasonType type,
  )? onUserOffline;

  final void Function(
    RtcConnection connection,
    int remoteUid,
    int elapsed,
  )? onUserJoined;

  final void Function(
    RtcConnection connection,
    int remoteUid,
    bool muted,
  )? onUserMuteVideo;

  final void Function(
    RtcConnection connection,
    int remoteUid,
    bool muted,
  )? onUserMuteAudio;

  final void Function(
    RtcConnection connection,
    int remoteUid,
    int width,
    int height,
    int elapsed,
  )? onFirstRemoteVideoDecoded;

  final void Function(
    RtcConnection connection,
    int remoteUid,
    RemoteVideoState state,
    RemoteVideoStateReason reason,
    int elapsed,
  )? onRemoteVideoStateChanged;

  final void Function(
    RtcConnection connection,
    int uid,
  )? onActiveSpeaker;
}

class AgoraEngineManager {
  AgoraEngineManager(
    this.options,
    this.eventHandler,
  ) {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onError: eventHandler.onError,
      onJoinChannelSuccess: eventHandler.onJoinChannelSuccess,
      onUserOffline: eventHandler.onUserOffline,
      onUserJoined: eventHandler.onUserJoined,
      onUserMuteVideo: eventHandler.onUserMuteVideo,
      onUserMuteAudio: eventHandler.onUserMuteAudio,
      onFirstRemoteVideoDecoded: eventHandler.onFirstRemoteVideoDecoded,
      onRemoteVideoStateChanged: eventHandler.onRemoteVideoStateChanged,
      onActiveSpeaker: eventHandler.onActiveSpeaker,
    ));
  }

  final RtcEngine _engine = createAgoraRtcEngine();
  final EngineOptions options;
  final AgoraRtcEngineEventHandler eventHandler;

  Future<void> initEngine() async {
    await _engine.initialize(RtcEngineContext(
      appId: options.agoraAppId,
      audioScenario: options.audioScenarioType,
      channelProfile: options.channelProfile,
      areaCode: options.areaCode,
    ));
  }

  bool hasJoined = false;

  Future<void> releaseEngine() async {
    await _engine.release();
  }

  void joinChannel(String channel) async {
    await initEngine();
    hasJoined = true;
  }

  Future<void> enableVideo(int uid) async {
    await _engine.enableVideo();
  }

  Future<void> disableVideo(int uid) async {
    await _engine.disableVideo();
  }

  Future<void> enableAudio() async {
    await _engine.enableAudio();
  }

  Future<void> disableAudio() async {
    await _engine.disableAudio();
  }

  Future<void> enableAudioSpectrumMonitor() async {
    _engine.enableAudioSpectrumMonitor();
  }

  Future<void> disableAudioSpectrumMonitor() async {
    _engine.disableAudioSpectrumMonitor();
  }
}
