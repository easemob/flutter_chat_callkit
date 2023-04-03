import 'dart:async';

import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/call_pages/call_buttom.dart';
import 'package:example/tools/format_time_tool.dart';

import 'package:flutter/material.dart';

enum SingleCallType {
  // 音频呼入等待
  audioCallInHolding,
  // 视频呼入等待
  videoCallInHolding,
  // 音频呼出等待
  audioCallOutHolding,
  // 视频呼出等待
  videoCallOutHolding,
  // 音频通话中
  audioCallCalling,
  // 视频通话中
  videoCallCalling,
}

class SingleCallPage extends StatefulWidget {
/*
  factory SingleCallPage.receive(
    String userId,
    String callId, [
    String? nickname,
    TextStyle? nicknameStyle,
    TextStyle? timeStyle,
    Widget? avatar,
    Widget? background,
    bool isVideo = false,
  ]) {
    return SingleCallPage(
      userId,
      callId: callId,
      avatar: avatar,
      nickname: nickname,
      background: background,
      nicknameTextStyle: nicknameStyle,
      timeTextStyle: timeStyle,
      type: isVideo ? AgoraChatCallType.video_1v1 : AgoraChatCallType.audio_1v1,
      calling: false,
    );
  }

  factory SingleCallPage.call(
    String userId, [
    String? nickname,
    TextStyle? nicknameStyle,
    TextStyle? timeStyle,
    Widget? avatar,
    Widget? background,
    bool isVideo = false,
  ]) {
    return SingleCallPage(
      userId,
      avatar: avatar,
      nickname: nickname,
      background: background,
      nicknameTextStyle: nicknameStyle,
      timeTextStyle: timeStyle,
      type: isVideo ? AgoraChatCallType.video_1v1 : AgoraChatCallType.audio_1v1,
      calling: false,
    );
  }
  */

  const SingleCallPage(
    this.userId, {
    this.callId,
    this.avatar,
    this.nickname,
    this.background,
    this.nicknameTextStyle,
    this.timeTextStyle,
    this.type = AgoraChatCallType.audio_1v1,
    this.calling = false,
    super.key,
  });
  final String userId;
  final Widget? avatar;
  final String? nickname;
  final Widget? background;
  final TextStyle? nicknameTextStyle;
  final TextStyle? timeTextStyle;
  final AgoraChatCallType type;
  final String? callId;
  final bool calling;

  @override
  State<SingleCallPage> createState() => _SingleCallPageState();
}

class _SingleCallPageState extends State<SingleCallPage> {
  bool holding = true;
  bool startCalling = false;
  bool speakerOn = false;
  bool mute = false;
  bool cameraOn = true;
  bool hiddenWidgets = false;
  int time = 0;
  Timer? timer;
  String? callId;

  Widget? removeVideoWidget;

  bool hasInit = false;
  bool backgroundVideo = true;

  late SingleCallType currentType;

  @override
  void initState() {
    super.initState();

    addListener();

    if (widget.callId != null) {
      if (widget.calling) {
        if (widget.type == AgoraChatCallType.audio_1v1) {
          currentType = SingleCallType.audioCallCalling;
        } else {
          currentType = SingleCallType.videoCallCalling;
        }
      } else {
        if (widget.type == AgoraChatCallType.audio_1v1) {
          currentType = SingleCallType.audioCallInHolding;
        } else {
          currentType = SingleCallType.videoCallInHolding;
        }
      }
    } else {
      if (widget.type == AgoraChatCallType.audio_1v1) {
        currentType = SingleCallType.audioCallOutHolding;
      } else {
        currentType = SingleCallType.videoCallOutHolding;
      }
    }
    AgoraChatCallManager.initRTC().then((value) {
      setState(() {
        hasInit = true;
      });
      afterRTCInitAction();
    });
  }

  void afterRTCInitAction() {
    switch (currentType) {
      case SingleCallType.audioCallOutHolding:
      case SingleCallType.videoCallOutHolding:
        call();
        break;
      case SingleCallType.audioCallInHolding:
      case SingleCallType.videoCallInHolding:
        break;
      case SingleCallType.audioCallCalling:
      case SingleCallType.videoCallCalling:
        answer();
        break;
    }
  }

  void answer() async {
    await AgoraChatCallManager.answer(widget.callId!);
    holding = false;
    setState(() {});
  }

  void call() async {
    try {
      callId = await AgoraChatCallManager.startSingleCall(widget.userId,
          type: widget.type);
    } catch (e) {
      Navigator.of(context).pop();
    }
  }

  void addListener() {
    AgoraChatCallManager.addEventListener(
      "key",
      AgoraChatCallKitEventHandler(
        onJoinedChannel: (channel) {},
        onUserLeaved: (userId, agoraUid) {},
        onCallEnd: (callId, reason) => Navigator.of(context).pop(),
        onFirstRemoteVideoDecoded: remoteUserOpenVideo,
      ),
    );
  }

  void removeListener() {
    AgoraChatCallManager.removeEventListener("key");
  }

  void remoteUserOpenVideo(String userId, int agoraUid, int width, int height) {
    if (userId == widget.userId) {
      removeVideoWidget = AgoraChatCallManager.getRemoteVideoView(agoraUid);
      setState(() {
        holding = false;
      });
    }
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          time++;
        });
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  @override
  void dispose() {
    stopTimer();
    removeListener();
    AgoraChatCallManager.releaseRTC();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? content;
    switch (currentType) {
      case SingleCallType.audioCallOutHolding:
        {
          content = audioCallOutWidget();
        }
        break;
      case SingleCallType.audioCallInHolding:
        {
          content = audioCallInWidget();
        }
        break;
      case SingleCallType.audioCallCalling:
        {
          content = audioCallOutWidget();
        }
        break;
      case SingleCallType.videoCallOutHolding:
      case SingleCallType.videoCallInHolding:
      case SingleCallType.videoCallCalling:
        {
          content = videoCallWidget();
        }
        break;
    }

    List<Widget> list = [
      Positioned.fill(
          child: widget.background ?? Container(color: Colors.grey)),
      Positioned.fill(child: backgroundWidget()),
      Positioned.fill(
        top: 55,
        bottom: 60,
        child: content,
      ),
    ];

    content = Stack(
      children: list,
    );
    return content;
  }

  Widget backgroundWidget() {
    if (!hasInit) return const Offstage();
    Widget content;
    if (backgroundVideo && removeVideoWidget != null) {
      content = removeWidget();
    } else {
      content = localWidget();
    }

    content = InkWell(
      child: content,
    );

    return content;
  }

  Widget floatWidget() {
    if (!hasInit) return const Offstage();
    Widget content;
    if (!backgroundVideo) {
      content = removeWidget();
    } else {
      content = localWidget();
    }

    content = SizedBox(
      width: 90,
      height: 160,
      child: content,
    );

    content = InkWell(
      onTap: () {
        setState(() => backgroundVideo = !backgroundVideo);
      },
      child: content,
    );

    return content;
  }

  Widget removeWidget() {
    return removeVideoWidget ?? Container();
  }

  Widget localWidget() {
    return AgoraChatCallManager.getLocalVideoView() ?? const Offstage();
  }

  Widget audioCallInWidget() {
    Widget content = avatarWidget();

    content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        content,
        const SizedBox(height: 10),
        nicknameWidget(),
        const SizedBox(height: 10),
        timeWidget('Audio Call'),
      ],
    );

    Widget bottom = bottomWidget([
      answerButton(),
      hangupButton(),
    ]);

    content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [content, bottom],
    );

    return content;
  }

  Widget audioCallOutWidget() {
    Widget content = avatarWidget();

    content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        content,
        const SizedBox(height: 10),
        nicknameWidget(),
        const SizedBox(height: 10),
        timeWidget(holding ? 'Calling...' : timerToStr(time)),
      ],
    );

    Widget bottom = bottomWidget([
      speakerButton(),
      muteButton(),
      hangupButton(),
    ]);

    content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [content, bottom],
    );

    return content;
  }

  Widget videoCallWidget() {
    Widget content = switchCameraButton();
    if (removeVideoWidget == null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [content, const SizedBox(width: 17.5)]),
          avatarWidget(),
          const SizedBox(height: 10),
          nicknameWidget(),
          const SizedBox(height: 10),
          timeWidget(holding ? 'Calling...' : timerToStr(time)),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [content, const SizedBox(width: 17.5)]),
          const SizedBox(height: 10),
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [floatWidget(), const SizedBox(width: 17.5)]),
        ],
      );
    }

    content = Column(
      children: [content, const SizedBox(height: 30)],
    );

    Widget bottom;
    if (currentType == SingleCallType.videoCallCalling ||
        currentType == SingleCallType.videoCallOutHolding) {
      bottom = bottomWidget([cameraButton(), muteButton(), hangupButton()]);
    } else {
      bottom = bottomWidget([cameraButton(), hangupButton(), answerButton()]);
    }

    content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [content, bottom],
    );

    return content;
  }

  Widget avatarWidget() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.red,
        ),
        child: widget.avatar ?? Image.asset('images/avatar.png'),
      ),
    );
  }

  Widget nicknameWidget() {
    return Text(
      widget.nickname ?? widget.userId,
      style: widget.nicknameTextStyle ??
          const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
    );
  }

  Widget topWidget(List<Widget> list) {
    Widget content = Column(
      children: list,
    );

    content = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [content, const SizedBox(width: 17.5)],
    );
    return content;
  }

  Widget bottomWidget(List<Widget> widgets) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: widgets,
    );
  }

  Widget cameraButton() {
    return CallButton(
      selected: cameraOn,
      callback: () async {
        cameraOn = !cameraOn;
        if (cameraOn) {
          await AgoraChatCallManager.cameraOn();
        } else {
          await AgoraChatCallManager.cameraOff();
        }
        setState(() {});
      },
      selectImage: Image.asset("images/video_on.png"),
      unselectImage: Image.asset("images/video_off.png"),
      backgroundColor:
          cameraOn ? const Color.fromRGBO(255, 255, 255, 0.2) : Colors.white,
    );
  }

  Widget switchCameraButton() {
    return InkWell(
      onTap: () {
        AgoraChatCallManager.switchCamera();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
        child: Image.asset('images/switch_camera.png'),
      ),
    );
  }

  Widget hangupButton() {
    return CallButton(
      selected: false,
      callback: () async {
        await AgoraChatCallManager.hangup(widget.callId ?? callId!);
      },
      selectImage: Image.asset("images/hang_up.png"),
      backgroundColor: const Color.fromRGBO(246, 50, 77, 1),
    );
  }

  Widget answerButton() {
    return CallButton(
      selected: false,
      callback: () async {
        await AgoraChatCallManager.answer(widget.callId!);
        holding = false;
        setState(() {
          if (widget.type == AgoraChatCallType.audio_1v1) {
            currentType = SingleCallType.audioCallCalling;
          } else {
            currentType = SingleCallType.videoCallCalling;
          }
        });
      },
      selectImage: Image.asset("images/answer.png"),
      backgroundColor: const Color.fromRGBO(0, 206, 118, 1),
    );
  }

  Widget muteButton() {
    return CallButton(
      selected: mute,
      callback: () async {
        mute = !mute;
        if (mute) {
          await AgoraChatCallManager.mute();
        } else {
          await AgoraChatCallManager.unMute();
        }
        setState(() {});
      },
      selectImage: Image.asset("images/mic_off.png"),
      unselectImage: Image.asset("images/mic_on.png"),
    );
  }

  Widget speakerButton() {
    return CallButton(
      selected: speakerOn,
      callback: () async {
        speakerOn = !speakerOn;
        if (speakerOn) {
          await AgoraChatCallManager.speakerOn();
        } else {
          await AgoraChatCallManager.speakerOff();
        }
        setState(() {});
      },
      selectImage: Image.asset("images/speaker_on.png"),
      unselectImage: Image.asset("images/speaker_off.png"),
    );
  }

  Text timeWidget(String str) {
    return Text(
      str,
      textAlign: TextAlign.center,
      style: widget.timeTextStyle ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
    );
  }
}

