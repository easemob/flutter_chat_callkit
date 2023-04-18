import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'inherited/agora_chat_call_kit_manager_impl.dart';

class AgoraChatCallManager {
  static AgoraChatCallKitManagerImpl get _impl =>
      AgoraChatCallKitManagerImpl.instance;

  /// Initiate a 1v1 call.
  ///
  /// Param [userId] called user id.
  ///
  /// Param [type] call type, see [AgoraChatCallType].
  ///
  /// Param [ext] additional information.
  ///
  static Future<String> startSingleCall(
    String userId, {
    AgoraChatCallType type = AgoraChatCallType.audio_1v1,
    Map<String, String>? ext,
  }) {
    return _impl.startSingleCall(userId, type: type, ext: ext);
  }

  /// Initiate a multi-party call invitation.
  ///
  /// Param [userIds] Invited user.
  ///
  /// Param [ext] additional information.
  ///
  static Future<String> startInviteUsers(
    List<String> userIds, {
    Map<String, String>? ext,
  }) {
    return _impl.startInviteUsers(userIds, ext);
  }

  /// Initializes the rtc engine, which needs to be called before the call is established,
  /// and has a one-to-one correspondence with [releaseRTC].
  static Future<void> initRTC() {
    return _impl.initRTC();
  }

  /// release rtc engine. You are advised to call it after the call is over.
  /// The release relationship must be one-to-one with [initRTC].
  static Future<void> releaseRTC() {
    return _impl.releaseRTC();
  }

  /// Answer the call.
  ///
  /// Param [callId] the received call id.
  static Future<void> answer(String callId) {
    return _impl.answer(callId);
  }

  /// Hangup the call.
  ///
  /// Param [callId] the received call id.
  static Future<void> hangup(String callId) {
    return _impl.hangup(callId);
  }

  /// Turn on the camera, when you call it, the other party will receive
  /// a [AgoraChatCallKitEventHandler.onUserMuteVideo] callback.
  static Future<void> cameraOn() async {
    await _impl.enableLocalView();
    await _impl.startPreview();
  }

  /// Turn off the camera, when you call it, the other party will receive
  /// a [AgoraChatCallKitEventHandler.onUserMuteVideo] callback.
  static Future<void> cameraOff() async {
    await _impl.disableLocalView();
    await _impl.stopPreview();
  }

  /// Switch front and rear cameras.
  static Future<void> switchCamera() {
    return _impl.switchCamera();
  }

  /// Get the local capture screen widget.
  static AgoraVideoView? getLocalVideoView() {
    return _impl.getLocalVideoView();
  }

  /// Get the remote capture screen widget.
  ///
  /// Param [agoraUid] The agoraUid to be obtained. The user specifies which agoraUid the window to obtain belongs to.
  static AgoraVideoView? getRemoteVideoView(int agoraUid) {
    return _impl.getRemoteVideoView(agoraUid);
  }

  /// Mute, mute the other party can not hear you, when you mute,
  /// the other party will receive [AgoraChatCallKitEventHandler.onUserMuteAudio] callback.
  static Future<void> mute() {
    return _impl.mute();
  }

  /// Unmute. When unmute, the other party can hear your voice. When you call unmute,
  /// the other party will receive a [AgoraChatCallKitEventHandler.onUserMuteAudio] callback.
  static Future<void> unMute() {
    return _impl.unMute();
  }

  /// Turn on the speaker.
  static Future<void> speakerOn() {
    return _impl.speakerOn();
  }

  /// Turn off the speaker.
  static Future<void> speakerOff() {
    return _impl.speakerOff();
  }

  /// Set agoraToken handler to get agora tokens when agora_chat_callkit is needed.
  ///
  /// Param [handler] see [RtcTokenHandler].
  static void setRTCTokenHandler(RtcTokenHandler handler) {
    _impl.rtcTokenHandler = handler;
  }

  /// Set up the handler for the agoraUid and userId mapping to obtain the agora token when needed by agora_chat_callkit.
  ///
  /// Param [handler] see [UserMapperHandler].
  static void setUserMapperHandler(UserMapperHandler handler) {
    _impl.userMapperHandler = handler;
  }

  /// Add event listener
  ///
  /// Param [identifier] The custom handler identifier, is used to find the corresponding handler.
  ///
  /// Param [handler] The handle for callkit event. See [AgoraChatCallKitEventHandler].
  static void addEventListener(
    String identifier,
    AgoraChatCallKitEventHandler handler,
  ) {
    _impl.addEventListener(identifier, handler);
  }

  /// Remove the callkit event handler.
  ///
  /// Param [identifier] The custom handler identifier.
  static void removeEventListener(String identifier) {
    _impl.removeEventListener(identifier);
  }

  /// Remove all callkit event handler.
  ///
  static void clearAllEventListeners() {
    _impl.clearAllEventListeners();
  }
}
