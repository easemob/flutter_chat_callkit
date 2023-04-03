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
    Config.appServerTokenURL,
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

Future<AgoraChatCallUserMapper?> requestAppServerUserMapper(
  String channel,
  int agoraUid,
) async {
  String? accessToken;
  String? userId;
  try {
    accessToken = await ChatClient.getInstance.getAccessToken();
    userId = await ChatClient.getInstance.getCurrentUserId();
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
  var httpClient = HttpClient();

  Map<String, dynamic> map = {
    "userAccount": userId,
    "channelName": channel,
    "appkey": Config.appkey,
  };

  var uri = Uri.https(
    Config.appServerHost,
    Config.appServerUserMapperURL,
    map,
  );
  var request = await httpClient.getUrl(uri);
  request.headers.set("Authorization", "Bearer $accessToken");
  HttpClientResponse response = await request.close();
  AgoraChatCallUserMapper? ret;
  if (response.statusCode == HttpStatus.ok) {
    var content = await response.transform(const Utf8Decoder()).join();

    Map<String, dynamic>? map = convert.jsonDecode(content);
    if (map != null) {
      if (map["code"] == "RES_0K") {
        String channel = map["channelName"];
        Map result = map["result"];
        Map<int, String> mapper = {};
        result.forEach((key, value) {
          mapper[int.parse(key)] = value;
        });
        ret = AgoraChatCallUserMapper(channel, mapper);
      }
    }
  }
  httpClient.close();

  return ret;
}
