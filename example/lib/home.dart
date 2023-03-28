import 'package:agora_chat_callkit/agora_chat_callkit.dart';

import 'package:example/tools/token_tool.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String currentCallId = "";
  @override
  void initState() {
    super.initState();
    AgoraChatCallManager.addEventListener(
        "home",
        AgoraChatCallKitEventHandler(
          onReceiveCall: (userId, callId, callType, ext) {
            setState(() {
              currentCallId = callId;
            });
          },
          onCallEnd: (callId, reason) {
            setState(() {
              currentCallId = "";
            });
          },
        ));

    AgoraChatCallManager.setRTCTokenHandler((channel, agoraAppId, agoraUid) =>
        requestAppServerToken(channel, agoraAppId, agoraUid));
  }

  @override
  void dispose() {
    AgoraChatCallManager.removeEventListener("home");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(onPressed: _startCall, child: const Text("Call")),
          ElevatedButton(onPressed: _answerCall, child: const Text("Answer")),
          ElevatedButton(onPressed: _endCall, child: const Text("End")),
        ],
      ),
    );

    if (currentCallId.isNotEmpty) {
      content = Stack(
        children: [
          AgoraChatCallManager.getLocalVideoView() ?? const Offstage(),
          Positioned.fill(child: content),
        ],
      );
    }

    return content;
  }

  void _answerCall() async {
    if (currentCallId.isEmpty) return;
    await AgoraChatCallManager.answer(currentCallId);
  }

  void _startCall() async {
    currentCallId = await AgoraChatCallManager.startSingleCall("du001");
    debugPrint("call id $currentCallId");
  }

  void _endCall() async {
    await AgoraChatCallManager.hangup(currentCallId);
  }
}
