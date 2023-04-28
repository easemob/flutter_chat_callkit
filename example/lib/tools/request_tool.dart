import 'dart:convert';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:agora_chat_callkit/agora_chat_callkit.dart';

import '../config.dart';

/// When adding an agora channel, a token is required for verification.
/// The purpose of this method is to obtain the token that can be added to the channel according to the channel id, agoraAppId and agora uid.
/// see: https://docs.agora.io/en/video-calling/develop/integrate-token-generation?platform=flutter#integrate-token-generation-into-your-authentication-system
/// Param [channel] The channel id.
///
/// Param [agoraUid] The agora uid.
Future<Map<String, int>> requestAppServerToken(
  String channel,
  int agoraUid,
) async {
  Map<String, int> ret = {};
  String? accessToken;
  String? userId;
  try {
    accessToken = await ChatClient.getInstance.getAccessToken();
    userId = await ChatClient.getInstance.getCurrentUserId();
  } catch (e) {
    return {};
  }

  Map<String, dynamic> params = {
    "userAccount": userId,
  };

  String unencodedPath =
      '${Config.appServerTokenURL}/$channel/agorauid/$agoraUid';

  var uri = Uri.https(
    Config.appServerDomain,
    unencodedPath,
    params,
  );

  var client = http.Client();
  var response = await client.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );

  Map<String, dynamic>? map = convert.jsonDecode(response.body);
  if (map != null) {
    if (map["code"] == "RES_OK") {
      ret[map["accessToken"]] = agoraUid;
    }
  }

  return ret;
}

/// Because AgoraChat and agora are two account systems, you need to map the Agora Uid that is added to the
/// call to the user id of AgoraChat. Through this service, you can query the corresponding AgoraChat userId
/// through channel and agora uid. This service needs to be provided by yourself.
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
    return null;
  }

  Map<String, dynamic> params = {
    "userAccount": userId,
    "channelName": channel,
  };

  var uri = Uri.https(
    Config.appServerDomain,
    Config.appServerUserMapperURL,
    params,
  );

  var client = http.Client();
  var response = await client.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken'
    },
  );
  AgoraChatCallUserMapper? ret;
  Map<String, dynamic>? map = convert.jsonDecode(response.body);
  if (map != null) {
    if (map["code"] == "RES_OK") {
      String channel = map["channelName"];
      Map result = map["result"];
      Map<int, String> mapper = {};
      result.forEach((key, value) {
        mapper[int.parse(key)] = value;
      });
      ret = AgoraChatCallUserMapper(channel, mapper);
    }
  }

  return ret;
}

/// Register with userId and password. You are required to provide your own registration service.
Future<String?> registerAccount(String userId, String password) async {
  String? ret;
  Map<String, String> params = {
    "userAccount": userId,
    "userPassword": password,
  };
  var uri = Uri.https(
    Config.appServerDomain,
    Config.appServerRegister,
  );
  var client = http.Client();

  var response = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(params),
  );
  do {
    Map<String, dynamic>? map = convert.jsonDecode(response.body);
    if (map != null) {
      if (map["code"] != "RES_OK") {
        ret = map['code'];
      }
    }
  } while (false);

  return ret;
}

/// Obtain a agora token using the userId and password, You are required to provide your own registration service.
Future<String?> fetchAgoraToken(String userId, String password) async {
  Map<String, String> params = {};
  params["userAccount"] = userId;
  params["userPassword"] = password;

  var uri = Uri.https(
    Config.appServerDomain,
    Config.appServerGetAgoraToken,
  );

  var client = http.Client();
  var response = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(params),
  );
  if (response.statusCode == 200) {
    Map<String, dynamic>? map = convert.jsonDecode(response.body);
    if (map != null) {
      if (map["code"] == "RES_OK") {
        return map["accessToken"];
      }
    }
  }
  return null;
}
