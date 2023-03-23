import 'package:agora_chat_callkit/agora_chat_callkit_define.dart';
import 'package:agora_chat_callkit/models/agora_chat_call.dart';
import 'package:agora_chat_callkit/tools/agora_chat_callkit_tools.dart';

typedef AgoraChatCallStateChange = void Function(
    AgoraChatCallState newState, AgoraChatCallState preState);

class AgoraChatCallModel {
  final AgoraChatCall? curCall;
  final String curDevId;
  final String? curUserAccount;
  final String? agoraRTCToken;
  final bool hasJoined;
  final int? uid;
  final AgoraChatCallStateChange? stateChanged;
  AgoraChatCallState _state;
  Map<String, AgoraChatCall> recvCalls;

  AgoraChatCallModel({
    this.curCall,
    Map<String, AgoraChatCall>? recvCalls,
    this.curUserAccount,
    this.agoraRTCToken,
    AgoraChatCallState state = AgoraChatCallState.idle,
    this.hasJoined = false,
    this.uid,
    String? curDevId,
    this.stateChanged,
  })  : curDevId = curDevId ?? AgoraChatCallKitTools.randomStr,
        _state = state,
        recvCalls = recvCalls ?? {};

  AgoraChatCallModel copyWith({
    AgoraChatCall? curCall,
    String? curUserAccount,
    String? agoraRTCToken,
    bool? hasJoined,
    int? uid,
    AgoraChatCallStateChange? stateChanged,
  }) {
    return AgoraChatCallModel(
      curCall: curCall ?? this.curCall,
      recvCalls: recvCalls,
      curDevId: curDevId,
      curUserAccount: curUserAccount ?? this.curUserAccount,
      agoraRTCToken: agoraRTCToken ?? this.agoraRTCToken,
      state: _state,
      hasJoined: hasJoined ?? this.hasJoined,
      uid: uid ?? this.uid,
      stateChanged: stateChanged ?? this.stateChanged,
    );
  }

  set state(AgoraChatCallState state) {
    stateChanged?.call(state, _state);
    _state = state;
  }

  AgoraChatCallState get state => _state;
}
