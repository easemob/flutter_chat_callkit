import 'package:flutter/material.dart';

class AgoraChatCallWidget extends StatefulWidget {
  const AgoraChatCallWidget({
    super.key,
    this.channel,
    required this.agoraUid,
    required this.child,
    this.maskWidget,
  });
  final String? channel;
  final int agoraUid;
  final Widget? maskWidget;
  final Widget child;

  @override
  State<AgoraChatCallWidget> createState() => _AgoraChatCallWidgetState();
}

class _AgoraChatCallWidgetState extends State<AgoraChatCallWidget> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(child: widget.maskWidget ?? const Offstage()),
      ],
    );
  }
}
