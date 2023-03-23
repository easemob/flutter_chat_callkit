import 'package:agora_chat_callkit/agora_chat_callkit_define.dart';

class AgoraChatCall {
  const AgoraChatCall({
    required this.callId,
    required this.remoteUserAccount,
    required this.callType,
    required this.isCaller,
    required this.channel,
    this.remoteCallDevId,
    this.uid,
    this.allUserAccounts,
    this.ext,
  });

  final String callId;
  final String remoteUserAccount;
  final AgoraChatCallType callType;
  final String channel;
  final bool isCaller;
  final String? remoteCallDevId;
  final int? uid;
  final Map<int, String>? allUserAccounts;
  final Map<String, String>? ext;

  AgoraChatCall copyWith({
    String? callId,
    String? remoteUserAccount,
    String? remoteCallDevId,
    AgoraChatCallType? callType,
    bool? isCaller,
    int? uid,
    Map<int, String>? allUserAccounts,
    String? channel,
    Map<String, String>? ext,
  }) {
    return AgoraChatCall(
      callId: callId ?? this.callId,
      remoteUserAccount: remoteUserAccount ?? this.remoteUserAccount,
      remoteCallDevId: remoteCallDevId ?? this.remoteCallDevId,
      callType: callType ?? this.callType,
      isCaller: isCaller ?? this.isCaller,
      uid: uid ?? this.uid,
      allUserAccounts: allUserAccounts ?? this.allUserAccounts,
      channel: channel ?? this.channel,
      ext: ext ?? this.ext,
    );
  }
}
