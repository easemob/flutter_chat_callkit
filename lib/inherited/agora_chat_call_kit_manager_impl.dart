import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:agora_chat_callkit/inherited/agora_chat_manager.dart';
import 'package:agora_chat_callkit/inherited/agora_engine_manager.dart';

import 'package:flutter/widgets.dart';

class AgoraChatCallKitManagerImpl {
  static AgoraChatCallKitManagerImpl? _instance;
  static AgoraChatCallKitManagerImpl get instance {
    _instance ??= AgoraChatCallKitManagerImpl();
    return _instance!;
  }

  Map<String, AgoraChatCallKitEventHandler> handlerMap = {};
  RtcTokenHandler? rtcTokenHandler;

  late final AgoraChatManager _chat;
  late final AgoraEngineManager _rtc;

  Duration callTimeout = const Duration(seconds: 30);

  AgoraChatCallKitManagerImpl() {
    _chat = AgoraChatManager(
        AgoraChatEventHandler(
          onCallAccept: () {
            onCallAccept();
          },
          onCallEndReason: (callId, reason) {
            onCallEndReason(callId, reason);
          },
          onError: (error) {
            onError(error);
          },
        ), (newState, preState) {
      stateChanged(newState, preState);
    });

    _rtc = AgoraEngineManager(
      RTCEventHandler(
        onJoinChannelSuccess: () {
          onJoinChannelSuccess();
        },
        onActiveSpeaker: (uid) {
          onActiveSpeaker(uid);
        },
        onError: (err, msg) {
          onRTCError(err, msg);
        },
        onFirstRemoteVideoDecoded: (agoraUid, width, height) {
          onFirstRemoteVideoDecoded(agoraUid, width, height);
        },
        onLeaveChannel: () {
          onLeaveChannel();
        },
        onUserJoined: (agoraUid) {
          onUserJoined(agoraUid);
        },
        onRemoteVideoStateChanged: (agoraUid, state, reason) {
          onRemoteVideoStateChanged(agoraUid, state, reason);
        },
        onUserLeaved: (agoraUid) {
          onUserLeaved(agoraUid);
        },
        onUserMuteAudio: (agoraUid, muted) {
          onUserMuteAudio(agoraUid, muted);
        },
        onUserMuteVideo: (agoraUid, muted) {
          onUserMuteVideo(agoraUid, muted);
        },
      ),
    );
  }

  set agoraAppId(String agoraAppId) {
    _rtc.agoraAppId = agoraAppId;
  }

  Future<String> startSingleCall(
    String userId, {
    AgoraChatCallType type = AgoraChatCallType.audio_1v1,
    Map<String, String>? ext,
  }) async {
    return _chat.startSingleCall(
      userId,
      type: type,
      ext: ext,
    );
  }

  Future<void> answerCall(String callId) {
    return _chat.answerCall(callId);
  }

  Future<void> hangup(String callId) async {
    await _chat.hangup(callId);
  }

  Future<void> answer(String callId) async {
    return _chat.answerCall(callId);
  }

  void addEventListener(String key, AgoraChatCallKitEventHandler handler) {
    handlerMap[key] = handler;
  }

  void removeEventListener(String key) {
    handlerMap.remove(key);
  }

  void clearAllEventListeners() {
    handlerMap.clear();
  }

  void fetchToken() async {
    if (_chat.model.curCall == null ||
        _rtc.agoraAppId == null ||
        rtcTokenHandler == null) return;

    Map<String, int> agoraToken = await rtcTokenHandler!.call(
      _chat.model.curCall!.channel,
      _rtc.agoraAppId!,
      _chat.model.agoraUid,
    );

    if (_chat.model.curCall == null) return;

    await _rtc.joinChannel(
      _chat.model.curCall!.callType,
      agoraToken.keys.first,
      _chat.model.curCall!.channel,
      _chat.model.agoraUid ?? agoraToken.values.first,
    );
  }
}

extension ChatEvent on AgoraChatCallKitManagerImpl {
  void stateChanged(
      AgoraChatCallState newState, AgoraChatCallState preState) async {
    switch (newState) {
      case AgoraChatCallState.idle:
        {
          await _chat.clearCurrentCallInfo();
          await _rtc.clearCurrentCallInfo();
        }
        break;
      case AgoraChatCallState.outgoing:
        {
          fetchToken();
        }
        break;
      case AgoraChatCallState.alerting:
        {
          if (_chat.model.curCall == null) return;
          _rtc.initEngine();
          handlerMap.forEach((key, value) {
            value.onReceiveCall?.call(
              _chat.model.curCall!.remoteUserAccount,
              _chat.model.curCall!.callId,
              _chat.model.curCall!.callType,
              _chat.model.curCall!.ext,
            );
          });
        }
        break;
      case AgoraChatCallState.answering:
        {
          if (_chat.model.curCall == null) return;
          if (_chat.model.curCall!.callType == AgoraChatCallType.multi &&
              _chat.model.curCall!.isCaller) {
            fetchToken();
          }
        }
        break;
    }
  }

  void onCallAccept() {
    fetchToken();
  }

  void onCallEndReason(String callId, AgoraChatCallEndReason reason) {
    handlerMap.forEach((key, value) {
      value.onCallEnd?.call(callId, reason);
    });
  }

  void onError(AgoraChatCallError error) {
    handlerMap.forEach((key, value) {
      value.onError?.call(error);
    });
  }
}

extension RTCEvent on AgoraChatCallKitManagerImpl {
  void onJoinChannelSuccess() {
    if (_chat.model.curCall == null) return;
    _chat.onUserJoined();

    String channel = _chat.model.curCall!.channel;
    handlerMap.forEach((key, value) {
      value.onJoinedChannel?.call(channel);
    });
  }

  void onLeaveChannel() {}
  void onUserJoined(int remoteUid) {
    if (_chat.model.curCall != null) {
      if (_chat.model.curCall?.callType == AgoraChatCallType.multi) {
        String userId = _chat.model.curCall!.allUserAccounts[remoteUid] ?? "";
        if (userId.isNotEmpty) {
          _chat.callTimerDic.remove(userId)?.cancel();
        }
        // update ui
      } else {
        _chat.callTimerDic
            .remove(_chat.model.curCall!.remoteUserAccount)
            ?.cancel();
        _chat.model.curCall!.allUserAccounts[remoteUid] =
            _chat.model.curCall!.remoteUserAccount;
      }

      String userId = _chat.model.curCall!.allUserAccounts[remoteUid] ?? "";
      String channel = _chat.model.curCall!.channel;
      debugPrint("user joined $remoteUid, userId: $userId");
      handlerMap.forEach((key, value) {
        value.onUserJoined?.call(channel, userId, remoteUid);
      });
    }
  }

  void onUserLeaved(int remoteUid) {
    if (_chat.model.curCall != null) {
      String? userId = _chat.model.curCall?.allUserAccounts.remove(remoteUid);
      String channel = _chat.model.curCall!.channel;
      if (userId != null) {
        handlerMap.forEach((key, value) {
          value.onUserLeaved?.call(channel, userId, remoteUid);
        });
      }
      if (_chat.model.curCall!.callType != AgoraChatCallType.multi) {
        _chat.onUserLeave();
      }
      debugPrint("user leave: $userId");
    }
  }

  void onUserMuteVideo(int remoteUid, bool muted) {}
  void onUserMuteAudio(int remoteUid, bool muted) {}
  void onFirstRemoteVideoDecoded(int remoteUid, int width, int height) {}
  void onRemoteVideoStateChanged(
      int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason) {}
  void onActiveSpeaker(int uid) {}
  void onRTCError(ErrorCodeType err, String desc) {
    _chat.onUserLeave();
    if (err == ErrorCodeType.errTokenExpired ||
        err == ErrorCodeType.errInvalidToken) {
      handlerMap.forEach((key, value) {
        value.onError?.call(AgoraChatCallError.rtc(err.index, "RTC Error"));
      });
    }
    debugPrint("joinError: $desc");
  }
}

extension RTCAction on AgoraChatCallKitManagerImpl {
  Future<void> enablePreview() => _rtc.startPreview();
  Future<void> disablePreview() => _rtc.stopPreview();
  Future<void> enableAudio() => _rtc.enableAudio();
  Future<void> disableAudio() => _rtc.disableAudio();
  Future<void> mute() => _rtc.mute();
  Future<void> unMute() => _rtc.unMute();

  AgoraChatCallWidget? getLocalVideoView() {
    Widget? widget = _rtc.localView();
    if (widget == null) return null;
    return AgoraChatCallWidget(
      agoraUid: 0,
      child: widget,
    );
  }

  AgoraChatCallWidget? getRemoteVideoView(int agoraUid) {
    if (_chat.model.curCall != null) {
      String channel = _chat.model.curCall!.channel;
      Widget? widget = _rtc.remoteView(agoraUid, channel);
      if (widget == null) {
        return null;
      }
      return AgoraChatCallWidget(
        channel: channel,
        agoraUid: agoraUid,
        child: widget,
      );
    }
    return null;
  }

  List<AgoraChatCallWidget> getRemoteVideoViews() {
    List<AgoraChatCallWidget> list = [];
    return list;
  }
}
