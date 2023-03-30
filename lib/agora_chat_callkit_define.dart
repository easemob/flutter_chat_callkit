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
