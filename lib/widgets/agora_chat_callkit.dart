import 'dart:async';

import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:agora_chat_callkit/inherited/agora_chat_manager.dart';
import 'package:agora_chat_callkit/inherited/agora_engine_manager.dart';
import 'package:flutter/material.dart';

String kAction = "action";
String kChannelName = "channelName";
String kCallType = "type";
String kCallerDevId = "callerDevId";
String kCallId = "callId";
String kTs = "ts";
String kMsgType = "msgType";
String kCalleeDevId = "calleeDevId";
String kCallStatus = "status";
String kCallResult = "result";
String kInviteAction = "invite";
String kAlertAction = "alert";
String kConfirmRingAction = "confirmRing";
String kCancelCallAction = "cancelCall";
String kAnswerCallAction = "answerCall";
String kConfirmCalleeAction = "confirmCallee";
String kVideoToVoice = "videoToVoice";
String kBusyResult = "busy";
String kAcceptResult = "accept";
String kRefuseResult = "refuse";
String kMsgTypeValue = "rtcCallWithAgora";
String kExt = "ext";

typedef RtcTokenHandler = Future<Map<String, int>> Function(
    String channel, String agoraAppId, int? agoraUid);

class AgoraChatCallKit extends StatefulWidget {
  const AgoraChatCallKit({
    required this.agoraAppId,
    required this.child,
    required this.eventHandler,
    this.audioScenarioType,
    this.channelProfile,
    this.areaCode,
    this.videoEncoderConfig,
    this.audioSessionOperationRestriction,
    this.callTimeout = 30,
    super.key,
  });
  final String agoraAppId;
  final Widget child;
  final AudioScenarioType? audioScenarioType;
  final ChannelProfileType? channelProfile;
  final int? areaCode;
  final VideoEncoderConfiguration? videoEncoderConfig;
  final AudioSessionOperationRestriction? audioSessionOperationRestriction;

  final AgoraChatCallKitEventHandler eventHandler;
  final int callTimeout;

  @override
  State<AgoraChatCallKit> createState() => AgoraChatCallKitState();

  static AgoraChatCallKitState of(BuildContext context) {
    AgoraChatCallKitState? state;
    state = context.findAncestorStateOfType<AgoraChatCallKitState>();
    assert(
      state != null,
      'You must have a AgoraChatCallKit widget at the top of you widget tree',
    );

    return state!;
  }
}

class AgoraChatCallKitState extends State<AgoraChatCallKit> {
  late final AgoraChatManager _chat;
  late final AgoraEngineManager _rtc;

  @override
  void initState() {
    super.initState();

    _chat = AgoraChatManager(
      CallbackErrorHandler(
        onCallAccept: () {
          fetchToken();
        },
        onError: (error) {
          widget.eventHandler.onError(error);
        },
        onCallEndReason: (reason) {
          widget.eventHandler.onCallEnd(reason);
        },
      ),
      (newState, preState) async {
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
              widget.eventHandler.onReceiveCall(
                _chat.model.curCall!.remoteUserAccount,
                _chat.model.curCall!.callId,
                _chat.model.curCall!.callType,
                _chat.model.curCall!.ext,
              );
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
      },
      timeout: widget.callTimeout,
    );
    _rtc = AgoraEngineManager(
      EngineOptions(
        agoraAppId: widget.agoraAppId,
        areaCode: widget.areaCode,
        audioSessionOperationRestriction:
            widget.audioSessionOperationRestriction,
        videoEncoderConfig: widget.videoEncoderConfig,
      ),
      AgoraRtcEngineEventHandler(
        onJoinChannelSuccess: () {
          _chat.onUserJoined();
          onCurrentUserJoinSucceed();
        },
        onUserLeaved: (remoteUid) {
          if (_chat.model.curCall != null) {
            String? userId =
                _chat.model.curCall?.allUserAccounts.remove(remoteUid);
            if (userId != null) {
              widget.eventHandler.onUserLeave?.call(userId);
            }
            if (_chat.model.curCall!.callType != AgoraChatCallType.multi) {
              _chat.onUserLeave();
            }
            debugPrint("user leave: $userId");
          }
        },
        onUserJoined: (remoteUid) {
          onUserJoined(remoteUid);
        },
        onError: (err, msg) {
          _chat.onUserLeave();
          if (err == ErrorCodeType.errTokenExpired ||
              err == ErrorCodeType.errInvalidToken) {
            widget.eventHandler
                .onError(AgoraChatCallError.rtc(err.index, "RTC Error"));
          }
          debugPrint("joinError: $msg");
        },
      ),
    );
  }

  void onCurrentUserJoinSucceed() {
    debugPrint("current user joined");
  }

  void onUserJoined(int agoraUid) {
    if (_chat.model.curCall != null) {
      if (_chat.model.curCall?.callType == AgoraChatCallType.multi) {
        String userId = _chat.model.curCall!.allUserAccounts[agoraUid] ?? "";
        if (userId.isNotEmpty) {
          _chat.callTimerDic.remove(userId)?.cancel();
        }
        // update ui
      } else {
        _chat.callTimerDic
            .remove(_chat.model.curCall!.remoteUserAccount)
            ?.cancel();
        _chat.model.curCall!.allUserAccounts[agoraUid] =
            _chat.model.curCall!.remoteUserAccount;
      }
      String channel = _chat.model.curCall!.channel;
      String userId = _chat.model.curCall!.allUserAccounts[agoraUid] ?? "";
      debugPrint("user joined $agoraUid, userId: $userId");
      widget.eventHandler.onJoinedChannel?.call(channel, userId, agoraUid);
    }
  }

  void fetchToken() async {
    if (_chat.model.curCall == null) return;
    Map<String, int> agoraToken =
        await widget.eventHandler.rtcTokenHandler.call(
      _chat.model.curCall!.channel,
      widget.agoraAppId,
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

  @override
  void dispose() {
    _chat.dispose();
    _rtc.dispose();
    super.dispose();
  }

  Future<String> startSingleCall(
    String userId, {
    AgoraChatCallType type = AgoraChatCallType.audio_1v1,
    int? agoraUid,
    Map<String, String>? ext,
  }) {
    debugPrint("call: $userId");

    return _chat.startSingleCall(
      userId,
      type: type,
      agoraUid: agoraUid,
      ext: ext,
    );
  }

  Future<void> answerCall(String callId) {
    return _chat.answerCall(callId);
  }

  Future<void> hangup() async {
    await _chat.hangup();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
