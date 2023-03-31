import 'package:flutter/material.dart';

class AgoraChatCallWidget extends StatefulWidget {
  const AgoraChatCallWidget({
    super.key,
    required this.agoraUid,
    this.channel,
    this.child,
    this.backgroundWidget,
  });
  final String? channel;
  final int agoraUid;
  final Widget? backgroundWidget;
  final Widget? child;

  @override
  State<AgoraChatCallWidget> createState() => _AgoraChatCallWidgetState();
}

class _AgoraChatCallWidgetState extends State<AgoraChatCallWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.backgroundWidget ?? const Offstage()),
        Positioned.fill(child: widget.child ?? const Offstage())
      ],
    );
  }
}
