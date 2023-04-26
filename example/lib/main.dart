import 'package:example/tools/request_tool.dart';
import 'package:flutter/material.dart';
import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_pages/multi_call_page.dart';
import 'call_pages/single_call_page.dart';
import 'config.dart';
import 'contact_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = ChatOptions(
    appKey: Config.appkey,
    autoLogin: false,
  );
  await ChatClient.getInstance.init(options);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return AgoraChatCallKit(
          agoraAppId: Config.agoraAppId,
          timeoutDuration: const Duration(seconds: 30),
          child: child!,
        );
      },
      title: 'Callkit demo',
      home: const MyHomePage(title: 'Callkit demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScrollController scrollController = ScrollController();
  String _chatId = "";
  final List<String> _logText = [];

  @override
  void initState() {
    super.initState();
    // set agoraToken request handler.
    AgoraChatCallManager.setRTCTokenHandler((channel, agoraAppId, agoraUid) {
      return requestAppServerToken(channel, agoraAppId, agoraUid);
    });

    // set agoraUid and userId mapper handler.
    AgoraChatCallManager.setUserMapperHandler((channel, agoraUid) {
      return requestAppServerUserMapper(channel, agoraUid);
    });

    // add event listener.
    AgoraChatCallManager.addEventListener(
      "UNIQUE_HANDLER_ID",
      AgoraChatCallKitEventHandler(
        onReceiveCall: onReceiveCall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 10),
            const Text("login userId: ${Config.userId}"),
            const Text("password: ${Config.password}"),
            const Text("agoraToken: ${Config.agoraToken}"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () {
                      _signIn();
                    },
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.lightBlue),
                    ),
                    child: const Text("SIGN IN"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _signOut();
                    },
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.lightBlue),
                    ),
                    child: const Text("SIGN OUT"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Enter userId",
                    ),
                    onChanged: (chatId) => _chatId = chatId,
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: audioCall,
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightBlue),
                  ),
                  child: const Text("1v1Audio"),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: videoCall,
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.lightBlue),
                  ),
                  child: const Text("1v1Video"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: multiCall,
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
                backgroundColor: MaterialStateProperty.all(Colors.lightBlue),
              ),
              child: const Text("Multi Call"),
            ),
            Flexible(
              child: ListView.builder(
                controller: scrollController,
                itemBuilder: (_, index) {
                  return Text(_logText[index]);
                },
                itemCount: _logText.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _signIn() async {
    _addLogToConsole('begin sign in...');
    try {
      bool judgmentPwdOrToken = false;
      do {
        if (Config.password.isNotEmpty) {
          await ChatClient.getInstance.login(
            Config.userId,
            Config.password,
          );
          judgmentPwdOrToken = true;
          break;
        }

        if (Config.agoraToken.isNotEmpty) {
          await ChatClient.getInstance.loginWithAgoraToken(
            Config.userId,
            Config.agoraToken,
          );
          judgmentPwdOrToken = true;
          break;
        }
      } while (false);
      if (judgmentPwdOrToken) {
        _addLogToConsole('sign in success');
      } else {
        _addLogToConsole(
            'sign in fail: The password and agoraToken cannot both be null.');
      }
    } on ChatError catch (e) {
      _addLogToConsole('sign in fail: ${e.description}');
    }
  }

  void _signOut() async {
    _addLogToConsole('begin sign out...');
    try {
      await ChatClient.getInstance.logout();
      _addLogToConsole('sign out success');
    } on ChatError catch (e) {
      _addLogToConsole('sign out fail: ${e.description}');
    }
  }

  void audioCall() async {
    pushToCallPage([_chatId], AgoraChatCallType.audio_1v1);
  }

  void videoCall() async {
    pushToCallPage([_chatId], AgoraChatCallType.video_1v1);
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

  @override
  void dispose() {
    AgoraChatCallManager.removeEventListener("UNIQUE_HANDLER_ID");
    super.dispose();
  }

  void _addLogToConsole(String log) {
    _logText.add("$_timeString: $log");
    setState(() {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  String get _timeString {
    return DateTime.now().toString().split(".").first;
  }
}
