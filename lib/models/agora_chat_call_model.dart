import 'package:agora_chat_callkit/agora_chat_callkit_define.dart';
import 'package:agora_chat_callkit/models/agora_chat_call.dart';
import 'package:agora_chat_callkit/tools/agora_chat_callkit_tools.dart';

typedef AgoraChatCallStateChange = void Function(
    AgoraChatCallState newState, AgoraChatCallState preState);

class AgoraChatCallModel {
  AgoraChatCall? curCall;
  String curDevId;
  String? curUserAccount;
  String? agoraRTCToken;
  bool hasJoined;
  int? agoraUid;
  AgoraChatCallStateChange? stateChanged;
  AgoraChatCallState _state;
  Map<String, AgoraChatCall> recvCalls;

  AgoraChatCallModel({
    this.curCall,
    Map<String, AgoraChatCall>? recvCalls,
    this.curUserAccount,
    this.agoraRTCToken,
    AgoraChatCallState state = AgoraChatCallState.idle,
    this.hasJoined = false,
    this.agoraUid,
    String? curDevId,
    this.stateChanged,
  })  : curDevId = curDevId ?? AgoraChatCallKitTools.randomStr,
        _state = state,
        recvCalls = recvCalls ?? {};

  set state(AgoraChatCallState state) {
    stateChanged?.call(state, _state);
    _state = state;
  }

  AgoraChatCallState get state => _state;
}
