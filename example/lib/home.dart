import 'dart:convert';
import 'dart:io';
import 'dart:convert' as convert;
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

    testTask();
  }

  void testTask() async {
    await Future.delayed(const Duration(seconds: 5))
        .timeout(const Duration(seconds: 2))
        .onError((error, stackTrace) => debugPrint("error"))
        .whenComplete(() => debugPrint("complete"))
        .catchError((e) => debugPrint("catch error"));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    debugPrint("didChangeDependencies");
    AgoraChatCallKit.of(context).removeEvent(callkitEventKey);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("build");
    AgoraChatCallKit.of(context).addEvent(
      callkitEventKey,
      AgoraChatCallKitEvent(
        onCallEnd: (reason) {},
        onError: (error) {},
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(onPressed: _startCall, child: const Text("Call")),
        ElevatedButton(onPressed: _endCall, child: const Text("End")),
        ElevatedButton(onPressed: _testRun, child: const Text("GetToken"))
      ],
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

  void _testRun() async {
    Map<String, int> info = await requestAppServerToken(
      "channel_name",
      Config.agoraAppId,
      3000,
    );
    debugPrint("rtc info: ${info.toString()}");
  }

  Future<Map<String, int>> requestAppServerToken(
    String channel,
    String agoraAppId,
    int? agoraUid,
  ) async {
    Map<String, int> ret = {};
    String? accessToken;
    String? userId;
    try {
      accessToken = await ChatClient.getInstance.getAccessToken();
      userId = await ChatClient.getInstance.getCurrentUserId();
    } catch (e) {
      debugPrint(e.toString());
      return {};
    }
    var httpClient = HttpClient();

    Map<String, dynamic> map = {
      "userAccount": userId,
      "channelName": channel,
      "appkey": Config.appkey,
    };
    if (agoraUid != null) {
      map["agoraUserId"] = agoraUid.toString();
    }

    var uri = Uri.http(
      Config.appServerHost,
      Config.appServerURL,
      map,
    );
    var request = await httpClient.getUrl(uri);
    request.headers.set("Authorization", "Bearer $accessToken");
    HttpClientResponse response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      var content = await response.transform(const Utf8Decoder()).join();
      debugPrint(content);
      Map<String, dynamic>? map = convert.jsonDecode(content);
      if (map != null) {
        if (map["code"] == "RES_0K") {
          debugPrint("获取数据成功: $map");
          ret[map["accessToken"]] = map["agoraUserId"] ?? 0;
        }
      }
    }
    httpClient.close();
    return ret;
  }
}
