import 'package:agora_chat_callkit/models/agora_chat_call_user_mapper.dart';

typedef RtcTokenHandler = Future<Map<String, int>> Function(
    String channel, String agoraAppId, int? agoraUid);

typedef UserMapperHandler = Future<AgoraChatCallUserMapper?> Function(
    String channel, int agoraUid);

enum AgoraChatCallType {
  audio_1v1,
  video_1v1,
  multi,
}

enum AgoraChatCallEndReason {
  hangup,
  cancel,
  remoteCancel,
  refuse,
  busy,
  noResponse,
  remoteNoResponse,
  handleOnOtherDevice,
}

enum AgoraChatCallErrorType {
  process,
  rtc,
  im,
}

enum AgoraChatCallState {
  idle,
  outgoing,
  alerting,
  answering,
}

class AgoraChatCallErrorProcessCode {
  static int genral = 0;
  static int invalidParam = 100;
  static int busy = 101;
  static int fetchTokenFail = 102;
}
