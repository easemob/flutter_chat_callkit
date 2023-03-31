import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:flutter/widgets.dart';
import 'inherited/agora_chat_call_kit_manager_impl.dart';

class AgoraChatCallManager {
  static AgoraChatCallKitManagerImpl get _impl =>
      AgoraChatCallKitManagerImpl.instance;

  static Future<String> startSingleCall(
    String userId, {
    AgoraChatCallType type = AgoraChatCallType.audio_1v1,
    Map<String, String>? ext,
  }) {
    return _impl.startSingleCall(userId, type: type, ext: ext);
  }

  static Future<void> initRTC() {
    return _impl.initRTC();
  }

  static Future<void> releaseRTC() {
    return _impl.releaseRTC();
  }

  static Future<void> answer(String callId) {
    return _impl.answer(callId);
  }

  static Future<void> hangup(String callId) {
    return _impl.hangup(callId);
  }

  static Future<void> cameraOn() async {
    await _impl.enableLocalView();
    await _impl.startPreview();
  }

  static Future<void> cameraOff() async {
    await _impl.disableLocalView();
    await _impl.stopPreview();
  }

  static Future<void> switchCamera() {
    return _impl.switchCamera();
  }

  static AgoraChatCallWidget? getLocalVideoView([Widget? background]) {
    return _impl.getLocalVideoView(background);
  }

  static AgoraChatCallWidget? getRemoteVideoView(int agoraUid) {
    return _impl.getRemoteVideoView(agoraUid);
  }

  static List<AgoraChatCallWidget> getRemoteVideoViews() {
    return _impl.getRemoteVideoViews();
  }

  static Future<void> mute() {
    return _impl.mute();
  }

  static Future<void> unMute() {
    return _impl.unMute();
  }

  static Future<void> speakerOn() {
    return _impl.speakerOn();
  }

  static Future<void> speakerOff() {
    return _impl.speakerOff();
  }

  static void setRTCTokenHandler(RtcTokenHandler handler) {
    _impl.rtcTokenHandler = handler;
  }

  static void addEventListener(
    String key,
    AgoraChatCallKitEventHandler handler,
  ) {
    _impl.addEventListener(key, handler);
  }

  static void removeEventListener(String key) {
    _impl.removeEventListener(key);
  }

  static void clearAllEventListeners() {
    _impl.clearAllEventListeners();
  }
}
