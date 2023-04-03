import 'dart:async';

import 'package:agora_chat_callkit/inherited/agora_chat_call_kit_manager_impl.dart';
import 'package:agora_chat_callkit/models/agora_chat_call_user_mapper.dart';

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

typedef UserMapperHandler = Future<AgoraChatCallUserMapper?> Function(
    String channel, int agoraUid);

class AgoraChatCallKit extends StatefulWidget {
  const AgoraChatCallKit({
    required this.agoraAppId,
    required this.child,
    this.timeoutDuration = const Duration(seconds: 30),
    super.key,
  });
  final String agoraAppId;
  final Widget child;

  final Duration timeoutDuration;

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
  @override
  void initState() {
    AgoraChatCallKitManagerImpl.instance.agoraAppId = widget.agoraAppId;
    AgoraChatCallKitManagerImpl.instance.callTimeout = widget.timeoutDuration;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
