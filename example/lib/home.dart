import 'package:agora_chat_callkit/agora_chat_callkit.dart';

import 'package:example/tools/callInfo.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final callkitEventKey = "callkit_key";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
  }

  void _answerCall() {
    if (receiveCallId.isEmpty) {
      debugPrint('receiveCallId is empty!');
      return;
    }
    AgoraChatCallKit.of(context).answerCall(receiveCallId);
  }

  void _startCall() async {
    String callId = await AgoraChatCallKit.of(context).startSingleCall("du001");
    debugPrint("call id $callId");
  }

  void _endCall() async {
    await AgoraChatCallKit.of(context).hangup();
  }
}
