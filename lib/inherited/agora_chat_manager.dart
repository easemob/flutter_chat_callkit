import 'dart:async';

import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:agora_chat_callkit/models/agora_chat_call.dart';
import 'package:agora_chat_callkit/models/agora_chat_call_model.dart';
import 'package:agora_chat_callkit/tools/agora_chat_callkit_tools.dart';
import 'package:flutter/foundation.dart';

import 'agora_chat_log_tool.dart';

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

class AgoraChatEventHandler {
  final void Function(AgoraChatCallError error) onError;
  final void Function(String callId, AgoraChatCallEndReason reason)
      onCallEndReason;
  final VoidCallback onCallAccept;
  final void Function(
    String callId,
    String userId,
    AgoraChatCallEndReason reason,
  ) onUserRemoved;

  final void Function(String callId) onAnswer;

  AgoraChatEventHandler({
    required this.onError,
    required this.onCallEndReason,
    required this.onCallAccept,
    required this.onUserRemoved,
    required this.onAnswer,
  });
}

/// 流程：
/// 1. invite
///               2. receive invite
///               3. send alerting
/// 4. receive alerting
/// 5. send confirm ring
///               6. receive confirm ring
///               7. send refuse / answer
/// 8. receive, send device id to callee.

class AgoraChatManager {
  AgoraChatManager(this.handler, AgoraChatCallStateChange stateChange) {
    registerChatEvent();
    model = AgoraChatCallModel(stateChanged: stateChange);
  }

  late AgoraChatCallModel model;
  final String key = "AgoraChatCallKit";
  final AgoraChatEventHandler handler;
  Duration timeoutDuration = const Duration(seconds: 30);

  /// 应答 timer，当呼出时需要把callId和计时器放到map中，计时器终止时移除callId。
  /// 目的是确保被叫方收到的通话有效，
  /// 场景：对方收到离线的呼叫消息，需要判断当前呼叫是否有效，则将收到的callId发送给主叫方，
  ///      主叫方收到后，判断map中是否存在对应的callId，如果不存在，则表示本callId对应的通话无效，反之则为有效，之后将结果告知被叫方。
  final Map<String, Timer> callTimerDic = {};
  final Map<String, Timer> alertTimerDic = {};
  Timer? ringTimer;

  Timer? confirmTimer;

  bool get busy {
    return model.curCall != null && model.state != AgoraChatCallState.idle;
  }

  void chatLog(String method, ChatMessage msg) {
    log("chat method: $method, ${msg.toJson().toString()}");
  }

  void onUserJoined() {
    model.hasJoined = true;
  }

  void clearInfo() {
    if (model.curCall != null) {
      model.hasJoined = false;
      model.state = AgoraChatCallState.idle;
    }
  }

  void onStateChange(AgoraChatCallState state) {
    model.state = state;
  }

  Future<void> clearCurrentCallInfo() async {
    clearAllTimer();
    model.hasJoined = false;
    model.curCall = null;
    model.recvCalls.clear();
  }

  void parseMsg(ChatMessage message) async {
    Map ext = message.attributes ?? {};
    if (!ext.containsKey(kMsgType)) return;

    final from = message.from!;
    final msgType = ext[kMsgType];
    final callId = ext[kCallId] ?? "";
    final result = ext[kCallResult] ?? "";
    final callerDevId = ext[kCallerDevId] ?? "";
    final calleeDevId = ext[kCalleeDevId] ?? "";
    final channel = ext[kChannelName] ?? "";

    final isValid = ext[kCallStatus] ?? false;
    num type = ext[kCallType] ?? 0;

    final callType = AgoraChatCallType.values[type.toInt()];
    Map<String, String>? callExt = (ext[kExt] ?? {}).cast<String, String>();

    // 收到邀请
    void parseInviteMsgExt() {
      // 已经在通话中或者呼叫中。直接返回
      if (model.curCall?.callId == callId || callTimerDic.containsKey(callId)) {
        return;
      }
      // 如果忙碌，直接返回 kBusyResult
      if (busy) {
        sendAnswerMsg(from, callId, kBusyResult, callerDevId);
        return;
      }

      // 将邀请放到收到的call中
      model.recvCalls[callId] = AgoraChatCall(
        callId: callId,
        remoteUserAccount: from,
        remoteCallDevId: callerDevId,
        callType: callType,
        isCaller: false,
        channel: channel,
        ext: callExt,
      );

      // 发送应答
      sendAlertMsgToCaller(from, callId, callerDevId);
      // 启动应答计时器
      alertTimerDic[callId] =
          Timer.periodic(const Duration(seconds: 5), (timer) {
        // 时间到，取消应答计时
        timer.cancel();
        alertTimerDic.remove(callId);
      });
    }

    // 收到邀请应答
    void parseAlertMsgExt() {
      // 判断是我发送的邀请收到应答
      if (model.curDevId == callerDevId) {
        // 判断应答是否与本地存储数据呼应
        if (model.curCall?.callId == callId && callTimerDic.containsKey(from)) {
          // 告知对方，应答验证通过, 告知对方当前通话有效
          sendConfirmRingMsgToCallee(from, callId, true, calleeDevId);
        }
      } else {
        // 告知应答方，应答验证未通过，当前通话已经过期或者无效
        sendConfirmRingMsgToCallee(from, callId, false, calleeDevId);
      }
    }

    // 收到回复，可以确定通话有效，此处如果非忙可以弹窗。
    void parseConfirmRingMsgExt() {
      if (alertTimerDic.containsKey(callId) && calleeDevId == model.curDevId) {
        alertTimerDic.remove(callId)?.cancel();
        if (busy) {
          sendAnswerMsg(from, callId, kBusyResult, callerDevId);
          return;
        }
        if (model.recvCalls.containsKey(callId)) {
          // 验证通话有效，可以变为alerting状态, 如果无效则不需要处理
          if (isValid) {
            model.curCall = model.recvCalls[callId];
            model.recvCalls.clear();
            model.state = AgoraChatCallState.alerting;
            alertTimerDic.forEach((key, value) {
              value.cancel();
            });
            alertTimerDic.clear();
          }
          model.recvCalls.remove(callId);
          ringTimer = Timer.periodic(timeoutDuration, (timer) {
            timer.cancel();
            ringTimer = null;
            if (model.curCall?.callId == callId) {
              handler.onCallEndReason.call(
                model.curCall!.callId,
                AgoraChatCallEndReason.remoteNoResponse,
              );
              model.state = AgoraChatCallState.idle;
            }
          });
        }
      }
    }

    // 收到呼叫取消
    void parseCancelCallMsgExt() {
      // 如当前已经应答，但还未加入会议，取消所以计时，并告知上层呼叫停止
      if (model.curCall?.callId == callId) {
        confirmTimer?.cancel();
        confirmTimer = null;
        handler.onCallEndReason
            .call(model.curCall!.callId, AgoraChatCallEndReason.remoteCancel);
        model.state = AgoraChatCallState.idle;
      } else {
        model.recvCalls.remove(callId);
      }
      alertTimerDic.remove(callId)?.cancel();
    }

    // 收到结果应答
    void parseAnswerMsgExt() {
      if (model.curCall?.callId == callId && model.curDevId == callerDevId) {
        // 如果为多人模式
        if (model.curCall?.callType == AgoraChatCallType.multi) {
          // 对方拒绝
          if (result != kAcceptResult) {
            removeUser(from, AgoraChatCallEndReason.busy);
          }

          Timer? timer = callTimerDic.remove(from);
          if (timer != null) {
            timer.cancel();
            sendConfirmAnswerMsgToCallee(from, callId, result, calleeDevId);
            if (result == kAcceptResult) {
              model.state = AgoraChatCallState.answering;
              ringTimer?.cancel();
              ringTimer = null;
            }
          }
          onAnswer();
        } else {
          // 非多人模式，是呼出状态时
          if (model.state == AgoraChatCallState.outgoing) {
            if (result == kAcceptResult) {
              model.state = AgoraChatCallState.answering;
              ringTimer?.cancel();
              ringTimer = null;
            } else {
              handler.onCallEndReason.call(
                model.curCall!.callId,
                result == kRefuseResult
                    ? AgoraChatCallEndReason.refuse
                    : AgoraChatCallEndReason.busy,
              );
              model.state = AgoraChatCallState.idle;
            }
          }
          onAnswer();
          // 用于被叫方多设备的情况，被叫方收到后可以进行仲裁，只有收到这条后被叫方才能进行通话
          sendConfirmAnswerMsgToCallee(from, callId, result, calleeDevId);
        }
      }
    }

    void parseConfirmCalleeMsgExt() {
      if (model.state == AgoraChatCallState.alerting &&
          model.curCall?.callId == callId) {
        confirmTimer?.cancel();
        confirmTimer = null;
        if (model.curDevId == calleeDevId) {
          if (result == kAcceptResult) {
            model.state = AgoraChatCallState.answering;
            ringTimer?.cancel();
            ringTimer = null;
            if (model.curCall?.callType != AgoraChatCallType.audio_1v1) {
              // 更新本地摄像头数据
            }
            handler.onCallAccept.call();
            // 此处要开始获取声网token。
          } else {
            model.state = AgoraChatCallState.idle;
            handler.onCallEndReason.call(model.curCall!.callId,
                AgoraChatCallEndReason.handleOnOtherDevice);
          }
        }
      } else {
        if (model.recvCalls.remove(callId) != null) {
          alertTimerDic.remove(callId)?.cancel();
        }
      }
    }

    void parseVideoToVoiceMsg() {}

    if (msgType == kMsgTypeValue) {
      String action = ext[kAction];
      debugPrint("action:-----------$action, ${ext.toString()}");
      if (action == kInviteAction) {
        parseInviteMsgExt();
      } else if (action == kAlertAction) {
        parseAlertMsgExt();
      } else if (action == kCancelCallAction) {
        parseCancelCallMsgExt();
      } else if (action == kAnswerCallAction) {
        parseAnswerMsgExt();
      } else if (action == kConfirmRingAction) {
        parseConfirmRingMsgExt();
      } else if (action == kConfirmCalleeAction) {
        parseConfirmCalleeMsgExt();
      } else if (action == kVideoToVoice) {
        parseVideoToVoiceMsg();
      }
    }
  }

  Future<void> sendInviteMsgToCallee(String userId, AgoraChatCallType type,
      String callId, String channel, Map<String, String>? ext) async {
    String sType = 'voice';
    if (type == AgoraChatCallType.multi) {
      sType = 'conference';
    } else if (type == AgoraChatCallType.video_1v1) {
      sType = 'video';
    }
    final msg = ChatMessage.createTxtSendMessage(
        targetId: userId, content: 'invite info: $sType');
    Map attr = {
      kMsgType: kMsgTypeValue,
      kAction: kInviteAction,
      kCallId: callId,
      kCallType: type.index,
      kCallerDevId: model.curDevId,
      kChannelName: channel,
      kTs: ts
    };
    if (ext != null) {
      attr[kExt] = ext;
    }

    msg.attributes = attr;
    ChatClient.getInstance.chatManager.sendMessage(msg);
    chatLog("sendInviteMsgToCallee", msg);
  }

  void sendAlertMsgToCaller(
      String callerId, String callId, String devId) async {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
      targetId: callerId,
      action: "rtcCall",
      deliverOnlineOnly: true,
    );
    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kAlertAction,
      kCallId: callId,
      kCalleeDevId: model.curDevId,
      kCallerDevId: devId,
      kTs: ts,
    };
    msg.attributes = attributes;
    ChatClient.getInstance.chatManager.sendMessage(msg);
    chatLog("sendAlertMsgToCaller", msg);
  }

  void sendConfirmRingMsgToCallee(
      String userId, String callId, bool isValid, String calleeDevId) {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
      targetId: userId,
      action: "rtcCall",
      deliverOnlineOnly: true,
    );
    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kConfirmRingAction,
      kCallId: callId,
      kCallerDevId: model.curDevId,
      kCallStatus: isValid,
      kTs: ts,
      kCalleeDevId: calleeDevId,
    };
    msg.attributes = attributes;

    ChatClient.getInstance.chatManager.sendMessage(msg);
    chatLog("sendConfirmRingMsgToCallee", msg);
  }

  void sendAnswerMsg(
      String remoteUserId, String callId, String result, String devId) async {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
        targetId: remoteUserId, action: "rtcCall");
    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kAnswerCallAction,
      kCallId: callId,
      kCalleeDevId: model.curDevId,
      kCallerDevId: devId,
      kCallResult: result,
      kTs: ts,
    };

    msg.attributes = attributes;
    ChatClient.getInstance.chatManager.sendMessage(msg);
    confirmTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      timer.cancel();
      confirmTimer = null;
    });

    chatLog("sendAnswerMsg", msg);
  }

  void sendConfirmAnswerMsgToCallee(
      String userId, String callId, String result, String devId) async {
    ChatMessage msg = ChatMessage.createCmdSendMessage(
      targetId: userId,
      action: "rtcCall",
    );

    Map attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kConfirmCalleeAction,
      kCallId: callId,
      kCallerDevId: model.curDevId,
      kCalleeDevId: devId,
      kCallResult: result,
      kTs: ts,
    };
    msg.attributes = attributes;
    ChatClient.getInstance.chatManager.sendMessage(msg);
    chatLog("sendConfirmAnswerMsgToCallee", msg);
  }

  void sendCancelCallMsgToCallee(String userId, String callId) {
    final msg =
        ChatMessage.createCmdSendMessage(targetId: userId, action: 'rtcCall');
    msg.attributes = {
      kMsgType: kMsgTypeValue,
      kAction: kCancelCallAction,
      kCallId: callId,
      kCallerDevId: model.curDevId,
      kTs: ts,
    };

    ChatClient.getInstance.chatManager.sendMessage(msg);
  }

  void registerChatEvent() {
    unregisterChatEvent();
    ChatClient.getInstance.chatManager.addEventHandler(
        key,
        ChatEventHandler(
          onCmdMessagesReceived: onMessageReceived,
          onMessagesReceived: onMessageReceived,
        ));

    ChatClient.getInstance.chatManager.addMessageEvent(key, ChatMessageEvent(
      onError: (msgId, msg, error) {
        handler.onError(AgoraChatCallError.im(error.code, error.description));
      },
    ));
  }

  void unregisterChatEvent() {
    ChatClient.getInstance.chatManager.removeEventHandler(key);
    ChatClient.getInstance.chatManager.removeMessageEvent(key);
  }

  void onMessageReceived(List<ChatMessage> list) {
    for (var msg in list) {
      parseMsg(msg);
    }
  }

  int get ts => DateTime.now().millisecondsSinceEpoch;

  void clearAllTimer() {
    callTimerDic.forEach((key, value) {
      value.cancel();
    });
    callTimerDic.clear();

    alertTimerDic.forEach((key, value) {
      value.cancel();
    });
    alertTimerDic.clear();

    confirmTimer?.cancel();
    confirmTimer = null;

    ringTimer?.cancel();
    ringTimer = null;
  }

  void dispose() {
    unregisterChatEvent();
    clearAllTimer();
  }

  Future<String> startSingleCall(
    String userId, {
    AgoraChatCallType type = AgoraChatCallType.audio_1v1,
    int? agoraUid,
    Map<String, String>? ext,
  }) async {
    if (userId.isEmpty) {
      throw AgoraChatCallError.process(
          AgoraChatCallErrorProcessCode.invalidParam, 'Require remote userId');
    }
    if (busy) {
      throw AgoraChatCallError.process(
          AgoraChatCallErrorProcessCode.busy, 'Current is busy');
    }
    model.curCall = AgoraChatCall(
      callId: AgoraChatCallKitTools.randomStr,
      channel: AgoraChatCallKitTools.randomStr,
      remoteUserAccount: userId,
      callType: type,
      isCaller: true,
      ext: ext,
    );

    model.state = AgoraChatCallState.outgoing;

    await sendInviteMsgToCallee(userId, type, model.curCall?.callId ?? "",
        model.curCall?.channel ?? "", ext);

    if (!callTimerDic.containsKey(userId)) {
      callTimerDic[userId] = Timer.periodic(
        timeoutDuration,
        (timer) {
          timer.cancel();
          callTimerDic.remove(userId);
          if (model.curCall != null) {
            sendCancelCallMsgToCallee(userId, model.curCall!.callId);
            if (model.curCall!.callType != AgoraChatCallType.multi) {
              handler.onCallEndReason(model.curCall!.callId,
                  AgoraChatCallEndReason.remoteNoResponse);
              model.state = AgoraChatCallState.idle;
            }
          }
        },
      );
    }

    return model.curCall!.callId;
  }

  void removeUser(String userId, AgoraChatCallEndReason reason) {
    if (model.curCall != null) {
      handler.onUserRemoved(model.curCall!.callId, userId, reason);
    }
  }

  void onAnswer() {
    if (model.curCall?.callId != null) {
      handler.onAnswer(model.curCall!.callId);
    }
  }

  Future<String> startInviteUsers(
    List<String> userIds,
    Map<String, String>? ext,
  ) async {
    if (userIds.isEmpty) {
      throw AgoraChatCallError.process(
          AgoraChatCallErrorProcessCode.invalidParam, 'Require remote userId');
    }

    if (model.curCall != null) {
      for (var element in userIds) {
        if (model.curCall!.allUserAccounts.values.contains(element)) {
          continue;
        }
        sendInviteMsgToCallee(
          element,
          model.curCall!.callType,
          model.curCall!.callId,
          model.curCall!.channel,
          ext,
        );

        callTimerDic[element] = Timer.periodic(timeoutDuration, (timer) {
          timer.cancel();
          callTimerDic.remove(element);
          if (model.curCall != null) {
            sendCancelCallMsgToCallee(element, model.curCall!.callId);
            removeUser(element, AgoraChatCallEndReason.remoteNoResponse);
          }
        });
      }
    } else {
      model.curCall = AgoraChatCall(
        callId: AgoraChatCallKitTools.randomStr,
        callType: AgoraChatCallType.multi,
        isCaller: true,
        channel: AgoraChatCallKitTools.randomStr,
        ext: ext,
      );

      model.state = AgoraChatCallState.answering;
      for (var element in userIds) {
        sendInviteMsgToCallee(
          element,
          model.curCall!.callType,
          model.curCall!.callId,
          model.curCall!.channel,
          ext,
        );

        callTimerDic[element] = Timer.periodic(timeoutDuration, (timer) {
          timer.cancel();
          callTimerDic.remove(element);
          if (model.curCall != null) {
            sendCancelCallMsgToCallee(element, model.curCall!.callId);
            removeUser(element, AgoraChatCallEndReason.remoteNoResponse);
          }
        });
      }
    }

    return model.curCall!.callId;
  }

  Future<void> hangup(String callId) async {
    if (model.curCall?.callId == callId) {
      clearAllTimer();
      if (model.state == AgoraChatCallState.answering) {
        handler.onCallEndReason(callId, AgoraChatCallEndReason.hangup);
      } else if (model.state == AgoraChatCallState.outgoing) {
        sendCancelCallMsgToCallee(
          model.curCall!.remoteUserAccount!,
          model.curCall!.callId,
        );
        handler.onCallEndReason(callId, AgoraChatCallEndReason.cancel);
      } else if (model.state == AgoraChatCallState.alerting) {
        sendAnswerMsg(
          model.curCall!.remoteUserAccount!,
          model.curCall!.callId,
          kRefuseResult,
          model.curCall!.remoteCallDevId!,
        );
        handler.onCallEndReason(callId, AgoraChatCallEndReason.refuse);
      }
      model.state = AgoraChatCallState.idle;
    }
  }

  Future<void> answerCall(String callId) async {
    if (model.curCall?.callId == callId) {
      if (model.curCall!.isCaller == true) {
        return;
      }
      onAnswer();
      sendAnswerMsg(
        model.curCall!.remoteUserAccount!,
        callId,
        kAcceptResult,
        model.curCall!.remoteCallDevId!,
      );
    }
  }
}
