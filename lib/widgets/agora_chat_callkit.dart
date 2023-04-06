import 'package:agora_chat_callkit/inherited/agora_chat_call_kit_manager_impl.dart';

import 'package:flutter/material.dart';

class AgoraChatCallKit extends StatefulWidget {
  const AgoraChatCallKit({
    required this.agoraAppId,
    required this.child,
    this.timeoutDuration = const Duration(seconds: 30),
    super.key,
  });
  final String agoraAppId;
  final Widget child;

  final Duration timeoutDuration;

  @override
  State<AgoraChatCallKit> createState() => AgoraChatCallKitState();

  static AgoraChatCallKitState of(BuildContext context) {
    AgoraChatCallKitState? state;
    state = context.findAncestorStateOfType<AgoraChatCallKitState>();
    assert(
      state != null,
      'You must have a AgoraChatCallKit widget at the top of you widget tree',
    );

    return state!;
  }
}

class AgoraChatCallKitState extends State<AgoraChatCallKit> {
  @override
  void initState() {
    AgoraChatCallKitManagerImpl.instance.agoraAppId = widget.agoraAppId;
    AgoraChatCallKitManagerImpl.instance.callTimeout = widget.timeoutDuration;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
