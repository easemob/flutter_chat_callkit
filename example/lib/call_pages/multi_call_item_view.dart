import 'dart:ui';

import 'package:flutter/material.dart';

class MultiCallItemView extends StatelessWidget {
  const MultiCallItemView({
    this.agoraUid,
    this.userId,
    this.videoView,
    this.muteAudio = false,
    this.muteVideo = false,
    this.avatar,
    this.nickname,
    super.key,
  });
  final int? agoraUid;
  final bool muteVideo;
  final bool muteAudio;
  final String? userId;
  final Widget? avatar;
  final String? nickname;
  final Widget? videoView;

  MultiCallItemView copyWith({bool? muteAudio, bool? muteVideo}) {
    return MultiCallItemView(
      agoraUid: agoraUid,
      userId: userId,
      videoView: videoView,
      muteAudio: muteAudio ?? this.muteAudio,
      muteVideo: muteVideo ?? this.muteVideo,
      avatar: avatar,
      nickname: nickname,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = avatar ?? Image.asset('images/avatar.png');

    Widget background = Container(
      color: Colors.black87,
      child: avatar ?? Image.asset('images/avatar.png', fit: BoxFit.cover),
    );

    List<Widget> list = [
      const SizedBox(width: 10),
      Text(
        nickname ?? userId ?? agoraUid.toString(),
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      const Expanded(child: Offstage())
    ];

    if (muteVideo == true) {
      list.add(SizedBox(
        width: 18,
        height: 24,
        child: Image.asset('images/video_off.png', color: Colors.white),
      ));
    }
    list.add(const SizedBox(width: 5));
    if (muteAudio == true) {
      list.add(SizedBox(
        width: 18,
        height: 24,
        child: Image.asset('images/mic_off.png', color: Colors.white),
      ));
    }
    list.add(const SizedBox(width: 10));

    Widget bottom = Row(
      mainAxisSize: MainAxisSize.max,
      children: list,
    );
    content = Stack(
      children: [
        Positioned.fill(child: background),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: const Color.fromRGBO(0, 0, 0, 0.4)),
            ),
          ),
        ),
        Positioned(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.all(
                          Radius.circular(50),
                        ),
                      ),
                      width: 100,
                      height: 100,
                      child: content,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(),
              )
            ],
          ),
        ),
        Positioned(child: muteVideo ? Container() : videoView ?? Container()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: 33,
            child: bottom,
          ),
        ),
      ],
    );

    return content;
  }
}
