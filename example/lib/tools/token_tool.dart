import 'dart:convert';
import 'dart:io';
import 'dart:convert' as convert;

import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/config.dart';
import 'package:flutter/foundation.dart';

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

  var uri = Uri.https(
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
        ret[map["accessToken"]] = map["agoraUserId"] ?? 0;
      }
    }
  }
  httpClient.close();
  debugPrint("get token: ${ret.toString()}");
  return ret;
}
