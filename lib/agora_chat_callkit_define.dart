import 'package:agora_chat_callkit/models/agora_chat_call_user_mapper.dart';

/// Returns a Map where key is agoraToken and value is agoraUid
typedef RtcTokenHandler = Future<Map<String, int>> Function(
    String channel, String agoraAppId, int? agoraUid);

/// Returns a AgoraChatCallUserMapper, See [AgoraChatCallUserMapper]
typedef UserMapperHandler = Future<AgoraChatCallUserMapper?> Function(
    String channel, int agoraUid);

/// Call type
enum AgoraChatCallType {
  audio_1v1,
  video_1v1,
  multi,
}

/// End of call cause
enum AgoraChatCallEndReason {
  hangup,
  cancel,
  remoteCancel,
  refuse,
  busy,
  remoteNoResponse,
  handleOnOtherDevice,
  err,
}

/// Call error type
enum AgoraChatCallErrorType {
  process,
  rtc,
  im,
}

/// Call error code
class AgoraChatCallErrorProcessCode {
  static int general = 1;
  static int invalidParam = 100;
  static int busy = 101;
  static int fetchTokenFail = 102;
}
