import 'package:agora_chat_callkit/agora_chat_callkit.dart';

class CallEndInfo {
  CallEndInfo({
    this.callId,
    required this.callTime,
    required this.remoteUserId,
    required this.reason,
  });
  final String? callId;
  final int callTime;
  final String remoteUserId;
  final AgoraChatCallEndReason reason;

  @override
  String toString() {
    return 'callTime: $callTime, remoteUserId: $remoteUserId, reason: ${reason.toString()}';
  }
}
