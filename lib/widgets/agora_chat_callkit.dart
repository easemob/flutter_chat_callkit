import 'dart:async';

import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:agora_chat_callkit/models/agora_chat_call.dart';
import 'package:flutter/material.dart';
import 'package:agora_chat_callkit/tools/agora_chat_callkit_tools.dart';

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
    this.audioScenarioType,
    this.channelProfile,
    this.areaCode,
    this.videoEncoderConfig,
    this.audioSessionOperationRestriction,
    this.callTimeOut = 30,
    this.tokenHandler,
    super.key,
  });
  final String agoraAppId;
  final Widget child;
  final AudioScenarioType? audioScenarioType;
  final ChannelProfileType? channelProfile;
  final int? areaCode;
  final VideoEncoderConfiguration? videoEncoderConfig;
  final AudioSessionOperationRestriction? audioSessionOperationRestriction;

  final RtcTokenHandler? tokenHandler;

  final int callTimeOut;

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
  final RtcEngine _engine = createAgoraRtcEngine();

  final Map<String, Timer> _callTimerDic = {};
  final Map<String, Timer> _alertTimerDic = {};
  late AgoraChatCallModel _mode;
  Timer? _confirmTimer;

  final Map<String, AgoraChatCallKitEvent> _eventDict = {};

  final String _randomKey = AgoraChatCallKitTools.randomStr;
  bool _bNeedSwitchToVoice = false;

  @override
  void initState() {
    super.initState();
    addChatListener();
    _mode = AgoraChatCallModel(
        curDevId: AgoraChatCallKitTools.randomStr,
        stateChanged: (newState, preState) {});
  }

  @override
  void dispose() {
    removeChatListener();
    super.dispose();
  }

  void addEvent(String key, AgoraChatCallKitEvent event) {
    _eventDict[key] = event;
  }

  void removeEvent(String key) {
    _eventDict.remove(key);
  }

  void clearAllEvent() {
    _eventDict.clear();
  }

  Future<void> _unsetRTCEngine() async {
    await _engine.release();
  }

  Future<void> _setRTCEngine() async {
    await _engine.initialize(RtcEngineContext(
      appId: widget.agoraAppId,
      audioScenario: widget.audioScenarioType,
      channelProfile: widget.channelProfile,
      areaCode: widget.areaCode,
    ));

    if (widget.videoEncoderConfig != null) {
      _engine.setVideoEncoderConfiguration(widget.videoEncoderConfig!);
    }

    if (widget.audioSessionOperationRestriction != null) {
      _engine.setAudioSessionOperationRestriction(
          widget.audioSessionOperationRestriction!);
    }

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: (err, msg) {
          // onError?.call();
        },
        onJoinChannelSuccess: (connection, elapsed) {},
        onUserOffline: (connection, remoteUid, reason) {},
        onUserJoined: (connection, remoteUid, elapsed) {},
        onUserMuteVideo: (connection, remoteUid, muted) {},
        onUserMuteAudio: (connection, remoteUid, muted) {},
        onFirstRemoteVideoDecoded:
            (connection, remoteUid, width, height, elapsed) {},
        onRemoteVideoStateChanged:
            (connection, remoteUid, state, reason, elapsed) {},
        onActiveSpeaker: (connection, uid) {},
      ),
    );
  }

  bool get _isBusy {
    // 当前存在通话，且状态不是idle, 是否只需要判断满足一个即可？
    if (_mode.curCall != null && _mode.state != AgoraChatCallState.idle) {
      return true;
    }
    return false;
  }

  Future<String> startSingleCall(
    String userId, {
    AgoraChatCallType type = AgoraChatCallType.audio_1v1,
    int? agoraUid,
    Map<String, String>? ext,
  }) async {
    if (userId.isEmpty) {
      throw AgoraChatCallError.process(
          AgoraChatCallErrorProcessCode.invalidParam, "Require userId");
    }

    if (_isBusy) {
      throw AgoraChatCallError.process(
          AgoraChatCallErrorProcessCode.busy, "current is busy");
    }
    AgoraChatCall call = AgoraChatCall(
      callId: AgoraChatCallKitTools.randomStr,
      channel: AgoraChatCallKitTools.randomStr,
      callType: type,
      isCaller: true,
      remoteUserAccount: userId,
      ext: ext,
      uid: agoraUid,
    );
    _mode = _mode.copyWith(
      curCall: call,
    );
    _mode.state = AgoraChatCallState.outgoing;
    await _setRTCEngine();
    await sendInviteMsgToCallee(
      userId: userId,
      callId: call.callId,
      channel: call.channel,
      callType: call.callType,
      ext: ext,
    );

    return call.callId;
  }

  Future<void> hangup() async {
    if (_mode.state == AgoraChatCallState.answering) {
      if (_mode.curCall?.callType == AgoraChatCallType.multi) {
        for (var timer in _callTimerDic.values) {
          timer.cancel();
        }
        _callTimerDic.clear();
      }
      _mode.state = AgoraChatCallState.idle;
      _eventDict.forEach((key, value) {
        value.onCallEnd.call(AgoraChatCallEndReason.hangup);
      });
    } else {
      if (_mode.state == AgoraChatCallState.outgoing) {
        stopCallTimer(_mode.curCall?.remoteUserAccount ?? "");
        sendCancelCallMsgToCallee(_mode.curCall?.remoteUserAccount ?? "",
            _mode.curCall?.callId ?? "");
        _mode.state = AgoraChatCallState.idle;
      } else if (_mode.state == AgoraChatCallState.answering) {
        // TODO: stop sound;
        sendAnswerMsg(
            _mode.curCall?.remoteUserAccount ?? "",
            _mode.curCall?.callId ?? "",
            kRefuseResult,
            _mode.curCall?.remoteCallDevId ?? "");

        _mode.state = AgoraChatCallState.idle;

        _eventDict.forEach((key, value) {
          value.onCallEnd.call(AgoraChatCallEndReason.refuse);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

extension PrivateMethod on AgoraChatCallKitState {
  Future<void> sendInviteMsgToCallee({
    required String userId,
    required AgoraChatCallType callType,
    required String callId,
    required String channel,
    Map<String, String>? ext,
  }) async {
    String content = () {
      String str = "voice";
      switch (callType) {
        case AgoraChatCallType.audio_1v1:
          str = "voice";
          break;
        case AgoraChatCallType.video_1v1:
          str = "video";
          break;
        case AgoraChatCallType.multi:
          str = "conference";
          break;
      }
      return str;
    }();

    ChatMessage msg = ChatMessage.createTxtSendMessage(
      targetId: userId,
      content: content,
    );

    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kInviteAction,
      kCallId: callId,
      kCallType: callType.index,
      kCallerDevId: _mode.curDevId,
      kChannelName: channel,
      kTs: ts
    };

    if (ext != null) {
      attributes[kExt] = ext;
    }

    msg.attributes = attributes;
    debugPrint("sendInviteMsgToCallee: $userId, $callId");
    await ChatClient.getInstance.chatManager.sendMessage(msg);
    startCallTimer(userId);
  }

  void sendCancelCallMsgToCallee(
    String remoteUserId,
    String callId,
  ) async {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
      targetId: remoteUserId,
      action: "rtcCall",
    );
    msg.attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kCancelCallAction,
      kCallId: callId,
      kCallerDevId: _mode.curDevId,
      kTs: ts
    };

    debugPrint("sendCancelCallMsgToCallee: $remoteUserId, $callId");
    ChatClient.getInstance.chatManager.sendMessage(msg);
  }

  void sendAnswerMsg(
    String remoteUserId,
    String callId,
    String result,
    String devId,
  ) async {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
        targetId: remoteUserId, action: "rtcCall");
    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kAnswerCallAction,
      kCallId: callId,
      kCalleeDevId: _mode.curDevId,
      kCallerDevId: devId,
      kCallResult: result,
      kTs: ts,
    };

    if (_mode.curCall?.callType == AgoraChatCallType.audio_1v1 &&
        _bNeedSwitchToVoice) {
      attributes[kVideoToVoice] == true;
    }

    msg.attributes = attributes;
    debugPrint("sendAnswerMsg: $remoteUserId, $callId");
    ChatClient.getInstance.chatManager.sendMessage(msg);
    startConfirmTimer(callId);
  }

  void sendAlertMsgToCaller(
    String callerId,
    String callId,
    String devId,
  ) {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
      targetId: callerId,
      action: "rtcCall",
      deliverOnlineOnly: true,
    );
    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kAlertAction,
      kCallId: callId,
      kCalleeDevId: _mode.curDevId,
      kCallerDevId: devId,
      kTs: ts,
    };
    msg.attributes = attributes;
    debugPrint("sendAlertMsgToCaller: $callerId, $callId");
    ChatClient.getInstance.chatManager.sendMessage(msg);
  }

  void sendConfirmRingMsgToCallee(
    String userId,
    String callId,
    bool isValid,
    String calleeDevId,
  ) {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
      targetId: userId,
      action: "rtcCall",
      deliverOnlineOnly: true,
    );
    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kConfirmRingAction,
      kCallId: callId,
      kCallerDevId: _mode.curDevId,
      kCallStatus: isValid,
      kTs: ts,
      kCalleeDevId: calleeDevId,
    };
    msg.attributes = attributes;
    debugPrint("sendConfirmRingMsgToCallee: $userId, $callId");
    ChatClient.getInstance.chatManager.sendMessage(msg);
  }

  void sendConfirmAnswerMsgToCallee(
    String userId,
    String callId,
    String result,
    String devId,
  ) {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
      targetId: userId,
      action: "rtcCall",
    );

    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kConfirmCalleeAction,
      kCallId: callId,
      kCallerDevId: _mode.curDevId,
      kCalleeDevId: devId,
      kCallResult: result,
      kTs: ts,
    };
    msg.attributes = attributes;
    debugPrint("sendConfirmAnswerMsgToCallee: $userId, $callId");
    ChatClient.getInstance.chatManager.sendMessage(msg);
    if (result == kAcceptResult) {
      _mode.state = AgoraChatCallState.answering;
    }
  }

  int get ts => DateTime.now().millisecondsSinceEpoch;
}

extension ParseMessage on AgoraChatCallKitState {
  void _parseMsg(ChatMessage message) async {
    if (message.attributes == null) return;
    Map ext = message.attributes!;
    if (!ext.containsKey(kMsgType)) return;

    debugPrint("_parseMsg：${message.toString()}");

    String from = message.from!;
    String msgType = ext[kMsgType];
    String callId = ext[kCallId] ?? "";
    String result = ext[kCallResult] ?? "";
    String callerDevId = ext[kCallerDevId] ?? "";
    String calleeDevId = ext[kCalleeDevId] ?? "";
    String channel = ext[kChannelName] ?? "";
    bool isValid = ext[kCallStatus] ?? false;
    AgoraChatCallType callType =
        AgoraChatCallType.values[(ext[kCallType] ?? 0)];
    bool isVideoToVoice = ext[kVideoToVoice] ?? false;
    Map<String, String>? callExt = ext[kExt]?.cast<String, String>();

    void parseInviteMsgExt(Map callInfo) {
      // 如果当前存在通话，并且不是本则通话，忽略本次邀请；
      if (_mode.curCall != null && _mode.curCall?.callId == callId) {
        return;
      }

      // 如果当前通话已经在呼出timer中，忽略，理论说这个情况不存在？
      if (_callTimerDic.containsKey(callId)) {
        return;
      }

      // 如果当前正忙，应答 “忙碌”
      if (_isBusy) {
        sendAnswerMsg(from, callId, kBusyResult, callerDevId);
      } else {
        AgoraChatCall call = AgoraChatCall(
          callId: callId,
          isCaller: false,
          callType: callType,
          remoteCallDevId: callerDevId,
          channel: channel,
          remoteUserAccount: from,
          ext: callExt,
        );
        _mode.recvCalls[callId] = call;
        sendAlertMsgToCaller(
          call.remoteUserAccount,
          callId,
          call.remoteCallDevId!,
        );
        startAlertTimer(callId);
      }
    }

    void parseAlertMsgExt(Map callInfo) {
      if (_mode.curDevId == callerDevId) {
        if (_mode.curCall != null &&
            _mode.curCall!.callId == callId &&
            _callTimerDic.containsKey(from)) {
          sendConfirmRingMsgToCallee(from, callId, true, calleeDevId);
        } else {
          sendConfirmRingMsgToCallee(from, callId, false, calleeDevId);
        }
      }
    }

    void parseCancelCallMsgExt(Map callInfo) {
      if (_mode.curCall != null &&
          _mode.curCall!.callId == callId &&
          _mode.hasJoined) {
        stopConfirmTimer();
        stopAlertTimer(callId);
        _mode.state = AgoraChatCallState.idle;
        // TODO: stop sound;
        _eventDict.forEach((key, value) {
          value.onCallEnd.call(AgoraChatCallEndReason.remoteCancel);
        });
      } else {
        _mode.recvCalls.remove(callId);
        stopAlertTimer(callId);
      }
    }

    void parseAnswerMsgExt(Map callInfo) {
      if (_mode.curCall != null &&
          _mode.curCall!.callId == callId &&
          _mode.curDevId == callerDevId) {
        if (_mode.curCall!.callType == AgoraChatCallType.multi) {
          // 如果对方不是接受
          if (result != kAcceptResult) {
            //TODO: 将对方从多人会视图中移除
          }
          Timer? timer = _callTimerDic.remove(from);
          if (timer != null) {
            sendConfirmAnswerMsgToCallee(from, callId, result, calleeDevId);
            timer.cancel();
          }
        } else {
          // 当前是呼出状态
          if (_mode.state == AgoraChatCallState.outgoing) {
            // 对方接听
            if (result == kAcceptResult) {
              // 需要从视频换音频
              if (isVideoToVoice) {
                // TODO: change video to voice and callback to user;
              }
              _mode.state = AgoraChatCallState.answering;
            } else {
              _mode.state = AgoraChatCallState.idle;
              if (result == kRefuseResult) {
                _eventDict.forEach((key, value) {
                  value.onCallEnd.call(AgoraChatCallEndReason.refuse);
                });
              }
              if (result == kBusyResult) {
                _eventDict.forEach((key, value) {
                  value.onCallEnd.call(AgoraChatCallEndReason.busy);
                });
              }
            }
          }
        }
      }
    }

    void parseConfirmRingMsgExt(Map callInfo) {
      if (_alertTimerDic.containsKey(callId) && calleeDevId == _mode.curDevId) {
        stopAlertTimer(callId);
        if (_isBusy) {
          sendAnswerMsg(from, callId, kBusyResult, callerDevId);
          return;
        }

        AgoraChatCall? call = _mode.recvCalls.remove(callId);
        if (call != null) {
          if (isValid) {
            _mode = _mode.copyWith(curCall: call);
            _mode.recvCalls.clear();
            _mode.state = AgoraChatCallState.alerting;
            stopAllAlertTimer();
          }
        }
      }
    }

    void parseConfirmCalleeMsgExt(Map callInfo) async {
      if (_mode.state == AgoraChatCallState.alerting &&
          _mode.curCall?.callId == callId) {
        stopConfirmTimer();
        // 仲裁为自己
        if (_mode.curDevId == calleeDevId) {
          if (result == kAcceptResult) {
            _mode.state = AgoraChatCallState.answering;
            if (_mode.curCall!.callType != AgoraChatCallType.audio_1v1) {
              //TODO: 打开本地视频 setupLocalVideo();
            }

            if (widget.tokenHandler != null) {
              Map<String, int> ret = await widget.tokenHandler!
                  .call(
                    _mode.curCall?.channel ?? "",
                    widget.agoraAppId,
                    _mode.curCall?.uid,
                  )
                  .timeout(
                    Duration(seconds: widget.callTimeOut),
                    onTimeout: () => {},
                  );
            } else {
              // 用户不需要token验证的场景暂不处理
            }
          }
        } else {
          // TODO: stop sound;
          _mode.state = AgoraChatCallState.idle;
          _eventDict.forEach(
            (key, value) {
              value.onCallEnd.call(AgoraChatCallEndReason.handleOnOtherDevice);
            },
          );
        }
      } else {
        if (_mode.recvCalls.remove(callId) != null) {
          stopAlertTimer(callId);
        }
      }
    }

    void parseVideoToVoiceMsg(Map callInfo) {
      if (_mode.curCall?.callId == callId) {
        // TODO: switchToVoide;
      }
    }

    if (msgType == kMsgTypeValue) {
      String action = ext[kAction];
      if (action == kInviteAction) {
        parseInviteMsgExt(ext);
      } else if (action == kAlertAction) {
        parseAlertMsgExt(ext);
      } else if (msgType == kCancelCallAction) {
        parseCancelCallMsgExt(ext);
      } else if (msgType == kAnswerCallAction) {
        parseAnswerMsgExt(ext);
      } else if (msgType == kConfirmRingAction) {
        parseConfirmRingMsgExt(ext);
      } else if (msgType == kConfirmCalleeAction) {
        parseConfirmCalleeMsgExt(ext);
      } else if (msgType == kVideoToVoice) {
        parseVideoToVoiceMsg(ext);
      }
    }
  }

  void addChatListener() {
    ChatClient.getInstance.chatManager.addEventHandler(
        _randomKey,
        ChatEventHandler(
          onMessagesReceived: (messages) {
            for (var msg in messages) {
              _parseMsg(msg);
            }
          },
          onCmdMessagesReceived: (messages) {
            for (var msg in messages) {
              _parseMsg(msg);
            }
          },
        ));

    ChatClient.getInstance.chatManager.addMessageEvent(_randomKey,
        ChatMessageEvent(
      onError: (msgId, msg, error) {
        debugPrint("sendMessage error: ${error.toString()}");
        _eventDict.forEach((key, value) {
          value.onError
              .call(AgoraChatCallError.im(error.code, error.description));
        });
      },
    ));
  }

  void removeChatListener() {
    ChatClient.getInstance.chatManager.removeEventHandler(_randomKey);
    ChatClient.getInstance.chatManager.removeMessageEvent(_randomKey);
  }
}

extension TimerExtension on AgoraChatCallKitState {
  void startCallTimer(String remoteUserId) {
    if (_callTimerDic.containsKey(remoteUserId)) return;
    debugPrint("start call timer $remoteUserId");
    _callTimerDic[remoteUserId] = Timer.periodic(
      Duration(seconds: widget.callTimeOut),
      (timer) {
        timeoutCallTimer(remoteUserId);
      },
    );
  }

  void stopCallTimer(String remoteUserId) {
    Timer? timer = _callTimerDic.remove(remoteUserId);
    timer?.cancel();
  }

  void timeoutCallTimer(String remoteUserId) {
    _callTimerDic.remove(remoteUserId);
    debugPrint("call timeout $remoteUserId");
    sendCancelCallMsgToCallee(remoteUserId, _mode.curCall!.callId);
    if (_mode.curCall!.callType != AgoraChatCallType.multi) {
      _mode.state = AgoraChatCallState.idle;
      _eventDict.forEach((key, value) {
        value.onCallEnd.call(AgoraChatCallEndReason.remoteNoResponse);
      });
    } else {
      // TODO: update multi view;
    }
  }

  void startConfirmTimer(String callId) {
    stopConfirmTimer();
    _confirmTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      timeoutConfirmTimer(callId);
    });
  }

  void stopConfirmTimer() {
    _confirmTimer?.cancel();
    _confirmTimer = null;
  }

  void timeoutConfirmTimer(String callId) {
    debugPrint("timeoutConfirm callId: $callId");
    if (_mode.curCall != null && _mode.curCall!.callId == callId) {
      _mode.state = AgoraChatCallState.idle;

      _eventDict.forEach((key, value) {
        value.onCallEnd.call(AgoraChatCallEndReason.remoteNoResponse);
      });
    }
  }

  void startAlertTimer(String callId) {
    Timer timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      timeoutAlertTimer(callId);
    });
    _alertTimerDic[callId] = timer;
  }

  void stopAlertTimer(String callId) {
    Timer? timer = _alertTimerDic.remove(callId);
    timer?.cancel();
  }

  void stopAllAlertTimer() {
    for (var timer in _alertTimerDic.values) {
      timer.cancel();
    }
    _alertTimerDic.clear();
  }

  void timeoutAlertTimer(String callId) {
    Timer? timer = _alertTimerDic.remove(callId);
    timer?.cancel();
  }
}
