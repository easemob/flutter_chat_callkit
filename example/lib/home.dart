import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/config.dart';
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
    AgoraChatCallKit.of(context).event = AgoraChatCallKitEvent(
      onCallEnd: (reason) {},
      onError: (error) {},
    );
    testCode();
  }

  void testCode() async {
    debugPrint("debugRun");
    Map<String, int> ret = await Future.delayed(const Duration(seconds: 5), () {
      return {"key": 1};
    }).timeout(
      const Duration(seconds: 2),
      onTimeout: () => {"key": 2},
    );
    debugPrint(ret.toString());
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
          ElevatedButton(onPressed: _endCall, child: const Text("End")),
        ],
      ),
    );
  }

  void _startCall() async {
    String callId =
        await AgoraChatCallKit.of(context).startSingleCall(Config.calleeId);
    debugPrint("call id $callId");
  }

  void _endCall() async {
    await AgoraChatCallKit.of(context).hangup();
  }
}
