import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/call_pages/multi_call_page.dart';
import 'package:example/tools/token_tool.dart';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_pages/single_call_page.dart';
import 'contact_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    AgoraChatCallManager.setRTCTokenHandler((channel, agoraAppId, agoraUid) {
      return requestAppServerToken(channel, agoraAppId, agoraUid);
    });

    AgoraChatCallManager.setUserMapperHandler((channel, agoraUid) {
      return requestAppServerUserMapper(channel, agoraUid);
    });

    AgoraChatCallManager.addEventListener(
        "home",
        AgoraChatCallKitEventHandler(
          onReceiveCall: onReceiveCall,
          onCallEnd: (callId, reason) {
            debugPrint('call end: reason: $reason');
          },
          onAnswer: (callId) {
            debugPrint('call answer: $callId');
          },
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
            ElevatedButton(
              onPressed: audioCall,
              child: const Text("Audio Call"),
            ),
            ElevatedButton(
              onPressed: videoCall,
              child: const Text("Video Call"),
            ),
            ElevatedButton(
              onPressed: multiCall,
              child: const Text("multi call"),
            ),
            ElevatedButton(
              onPressed: logout,
              child: const Text("logout"),
            ),
          ],
        ),
      ),
    );

    return content;
  }

  void audioCall() async {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const ContactPage(isMulti: false);
    })).then((value) {
      if (value != null && value is List && value.isNotEmpty) {
        String userId = (value as List<String>).first;
        pushToCallPage([userId], AgoraChatCallType.audio_1v1);
      }
    });
  }

  void videoCall() async {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const ContactPage(isMulti: false);
    })).then((value) {
      if (value != null && value is List && value.isNotEmpty) {
        String userId = (value as List<String>).first;
        pushToCallPage([userId], AgoraChatCallType.video_1v1);
      }
    });
  }

  void multiCall() async {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const ContactPage(isMulti: true);
    })).then((value) {
      if (value != null && value is List && value.isNotEmpty) {
        pushToCallPage(value as List<String>, AgoraChatCallType.multi);
      }
    });
  }

  void logout() async {
    await ChatClient.getInstance.logout().then((value) {
      Navigator.of(context).popAndPushNamed("login");
    });
  }

  void onReceiveCall(
    String userId,
    String callId,
    AgoraChatCallType callType,
    Map<String, String>? ext,
  ) async {
    pushToCallPage([userId], callType, callId);
  }

  void pushToCallPage(List<String> userIds, AgoraChatCallType callType,
      [String? callId]) async {
    Widget page;
    if (callType == AgoraChatCallType.multi) {
      if (callId == null) {
        page = MultiCallPage.call(userIds);
      } else {
        page = MultiCallPage.receive(callId, userIds.first);
      }
    } else {
      if (callId == null) {
        page = SingleCallPage.call(userIds.first, type: callType);
      } else {
        page = SingleCallPage.receive(userIds.first, callId, type: callType);
      }
    }

    [Permission.microphone, Permission.camera].request().then((value) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return page;
        }),
      ).then((value) {
        if (value != null) {
          debugPrint('call end: $value');
        }
      });
    });
  }
}
