import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/call_pages/multi_call_page.dart';
import 'package:example/tools/token_tool.dart';

import 'package:flutter/material.dart';

import 'call_pages/single_call_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    AgoraChatCallManager.setRTCTokenHandler((channel, agoraAppId, agoraUid) {
      return requestAppServerToken(channel, agoraAppId, agoraUid);
    });

    AgoraChatCallManager.addEventListener(
        "home",
        AgoraChatCallKitEventHandler(
          onReceiveCall: onReceiveCall,
        ));
  }

  @override
  void dispose() {
    AgoraChatCallManager.removeEventListener("home");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: SizedBox(
        height: 200,
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                cursorColor: Colors.blue,
                decoration: const InputDecoration(
                    filled: true,
                    fillColor: Color.fromRGBO(242, 242, 242, 1),
                    contentPadding: EdgeInsets.fromLTRB(30, 17, 30, 17),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    hintText: "UserId",
                    hintStyle: TextStyle(color: Colors.grey)),
                obscureText: false,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: audioCall,
                  child: const Text("Audio Call"),
                ),
                ElevatedButton(
                  onPressed: videoCall,
                  child: const Text("Video Call"),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: multiCall,
              child: const Text("multi call"),
            ),
          ],
        ),
      ),
    );

    return content;
  }

  void audioCall() async {
    pushToSingleCallPage(_controller.text, AgoraChatCallType.audio_1v1);
  }

  void videoCall() async {
    pushToSingleCallPage(_controller.text, AgoraChatCallType.video_1v1);
  }

  void multiCall() async {
    pushToSingleCallPage("du001", AgoraChatCallType.multi);
  }

  void onReceiveCall(
    String userId,
    String callId,
    AgoraChatCallType callType,
    Map<String, String>? ext,
  ) async {
    pushToSingleCallPage(userId, callType, callId);
  }

  void pushToSingleCallPage(String userId, AgoraChatCallType callType,
      [String? callId]) async {
    Widget page;
    if (callType == AgoraChatCallType.multi) {
      page = MultiCallPage.call([userId]);
    } else {
      page = SingleCallPage(
        userId,
        callId: callId,
        type: callType,
      );
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return page;
    }));
  }
}
