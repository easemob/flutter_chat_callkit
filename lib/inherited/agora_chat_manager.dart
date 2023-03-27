import 'dart:async';

import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:agora_chat_callkit/models/agora_chat_call.dart';
import 'package:agora_chat_callkit/tools/agora_chat_callkit_tools.dart';
import 'package:flutter/foundation.dart';

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

class CallbackErrorHandler {
  final void Function(AgoraChatCallError error) onError;
  final void Function(AgoraChatCallEndReason reason) onCallEndReason;
  final VoidCallback onCallAccept;
  CallbackErrorHandler({
    required this.onError,
    required this.onCallEndReason,
    required this.onCallAccept,
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
  AgoraChatManager(
    this.errorHandler,
    AgoraChatCallStateChange stateChange, {
    this.timeout = 30,
  }) {
    registerChatEvent();
    model = AgoraChatCallModel(stateChanged: stateChange);
  }

  late AgoraChatCallModel model;
  final String key = "AgoraChatCallKit";
  final CallbackErrorHandler errorHandler;
  final int timeout;
  bool _bNeedSwitchToVoice = false;

  /// 应答 timer，当呼出时需要把callId和计时器放到map中，计时器终止时移除callId。
  /// 目的是确保被叫方收到的通话有效，
  /// 场景：对方收到离线的呼叫消息，需要判断当前呼叫是否有效，则将收到的callId发送给主叫方，
  ///      主叫方收到后，判断map中是否存在对应的callId，如果不存在，则表示本callId对应的通话无效，反之则为有效，之后将结果告知被叫方。
  final Map<String, Timer> callTimerDic = {};
  final Map<String, Timer> alertTimerDic = {};

  Timer? confirmTimer;

  bool get busy {
    return model.curCall != null && model.state != AgoraChatCallState.idle;
  }

  void printMsg(String method, ChatMessage msg) {
    debugPrint("-----------method: $method, ${msg.toJson().toString()}");
  }

  void onUserJoined() {
    model.hasJoined = true;
  }

  void onUserLeave() {
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
    final callType = AgoraChatCallType.values[(ext[kCallType] ?? 0)];
    final isVideoToVoice = ext[kVideoToVoice] ?? false;
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
      debugPrint("收到邀请！channel: $channel");
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
        }
      }
    }

    // 收到呼叫取消
    void parseCancelCallMsgExt() {
      // 如当前已经应答，但还未加入会议，取消所以计时，并告知上层呼叫停止
      if (model.curCall?.callId == callId) {
        confirmTimer?.cancel();
        confirmTimer = null;
        errorHandler.onCallEndReason.call(AgoraChatCallEndReason.remoteCancel);
        model.state = AgoraChatCallState.idle;
        // TODO: 停止播放等待音
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
            // TODO: 移除ui or 回调告诉ui，多人时被叫方拒绝
          }
          Timer? timer = callTimerDic.remove(from);
          if (timer != null) {
            timer.cancel();
            sendConfirmAnswerMsgToCallee(from, callId, result, calleeDevId);
            if (result == kAcceptResult) {
              model.state = AgoraChatCallState.answering;
            }
          }
        } else {
          // 非多人模式，是呼出状态时
          if (model.state == AgoraChatCallState.outgoing) {
            if (result == kAcceptResult) {
              if (isVideoToVoice) {
                // TODO: 如果对方同意，同时按下了视频转音频，需要告知ui
              }
              model.state = AgoraChatCallState.answering;
            } else {
              errorHandler.onCallEndReason.call(
                result == kRefuseResult
                    ? AgoraChatCallEndReason.refuse
                    : AgoraChatCallEndReason.busy,
              );
              model.state = AgoraChatCallState.idle;
            }
          }
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
            if (model.curCall?.callType != AgoraChatCallType.audio_1v1) {
              // 更新本地摄像头数据
            }
            errorHandler.onCallAccept();
            // 此处要开始获取声网token。
          } else {
            model.state = AgoraChatCallState.idle;
            errorHandler.onCallEndReason
                .call(AgoraChatCallEndReason.handleOnOtherDevice);
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
    printMsg("sendInviteMsgToCallee", msg);
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
    printMsg("sendAlertMsgToCaller", msg);
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
    printMsg("sendConfirmRingMsgToCallee", msg);
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

    if (model.curCall?.callType == AgoraChatCallType.audio_1v1 &&
        _bNeedSwitchToVoice) {
      attributes[kVideoToVoice] == true;
    }

    msg.attributes = attributes;
    ChatClient.getInstance.chatManager.sendMessage(msg);
    confirmTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      confirmTimer?.cancel();
      confirmTimer = null;
    });

    printMsg("sendAnswerMsg", msg);
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
    printMsg("sendConfirmAnswerMsgToCallee", msg);
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
    printMsg("sendCancelCallMsgToCallee", msg);
  }

  void registerChatEvent() {
    ChatClient.getInstance.chatManager.addEventHandler(
        key,
        ChatEventHandler(
          onCmdMessagesReceived: onMessageReceived,
          onMessagesReceived: onMessageReceived,
        ));

    ChatClient.getInstance.chatManager.addMessageEvent(key, ChatMessageEvent(
      onError: (msgId, msg, error) {
        errorHandler
            .onError(AgoraChatCallError.im(error.code, error.description));
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
        Duration(seconds: timeout),
        (timer) {
          sendCancelCallMsgToCallee(userId, model.curCall?.callId ?? "");
          if (model.curCall != null) {
            if (model.curCall!.callType != AgoraChatCallType.multi) {
              errorHandler
                  .onCallEndReason(AgoraChatCallEndReason.remoteNoResponse);
              model.state = AgoraChatCallState.idle;
            }
          }
        },
      );
    }

    return model.curCall?.callId ?? "";
  }

  Future<void> hangup() async {
    clearAllTimer();
    if (model.state == AgoraChatCallState.answering) {
      errorHandler.onCallEndReason(AgoraChatCallEndReason.hangup);
    } else if (model.state == AgoraChatCallState.outgoing) {
      if (model.curCall != null) {
        sendCancelCallMsgToCallee(
          model.curCall!.remoteUserAccount,
          model.curCall!.callId,
        );
      }

      errorHandler.onCallEndReason(AgoraChatCallEndReason.cancel);
    } else if (model.state == AgoraChatCallState.alerting) {
      sendAnswerMsg(
        model.curCall!.remoteUserAccount,
        model.curCall!.callId,
        kRefuseResult,
        model.curCall!.remoteCallDevId!,
      );
      errorHandler.onCallEndReason(AgoraChatCallEndReason.refuse);
    }
    model.state = AgoraChatCallState.idle;
  }

  Future<void> answerCall(String callId) async {
    debugPrint("answer call: $callId");
    if (model.curCall != null) {
      sendAnswerMsg(
        model.curCall!.remoteUserAccount,
        callId,
        kAcceptResult,
        model.curCall!.remoteCallDevId!,
      );
    }
  }
}
