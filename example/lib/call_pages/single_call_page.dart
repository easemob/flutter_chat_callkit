import 'dart:async';

import 'package:agora_chat_callkit/agora_chat_callkit.dart';
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
  bool hasJoined = false;
  int time = 0;
  Timer? timer;
  String? callId;

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

    switch (currentType) {
      case SingleCallType.audioCallOutHolding:
      case SingleCallType.videoCallOutHolding:
        call();
        break;
      case SingleCallType.audioCallInHolding:
        break;
      case SingleCallType.videoCallInHolding:
        break;
      case SingleCallType.audioCallCalling:
        break;
      case SingleCallType.videoCallCalling:
        break;
    }
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
        onJoinedChannel: (channel) {
          hasJoined = true;
        },
        onUserJoined: onUserJoined,
        onUserLeaved: (userId, agoraUid) {},
        onCallEnd: (callId, reason) {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void removeListener() {
    AgoraChatCallManager.removeEventListener("key");
  }

  void onUserJoined(String userId, int agoraUid) {
    if (userId == widget.userId) {
      setState(() {
        holding = false;
      });
      startTimer();
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        time++;
      });
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
        {}
        break;
      case SingleCallType.videoCallInHolding:
        {}
        break;
      case SingleCallType.videoCallCalling:
        {}
        break;
    }
    content = Stack(
      children: [
        Positioned.fill(
          child: widget.background ??
              Container(
                color: Colors.grey,
              ),
        ),
        Positioned.fill(
          top: 40,
          bottom: 60,
          child: SafeArea(
            child: content!,
          ),
        ),
      ],
    );
    return content;
  }

  Widget audioCallInWidget() {
    Widget content = avatarWidget();

    content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        content,
        const Divider(height: 10),
        nicknameWidget(),
        const Divider(height: 10),
        timeWidget('Audio Call'),
      ],
    );

    Widget bottom = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        answerButton(),
        hangupButton(),
      ],
    );

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
        const Divider(height: 10),
        nicknameWidget(),
        const Divider(height: 10),
        timeWidget(holding ? 'Calling...' : timerToStr(time)),
      ],
    );

    Widget bottom = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        speakerButton(),
        muteButton(),
        hangupButton(),
      ],
    );

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
      child: widget.avatar ??
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.red,
            ),
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
          currentType = SingleCallType.audioCallCalling;
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
        if (!hasJoined) {
          return;
        }
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

class CallButton extends StatefulWidget {
  const CallButton({
    required this.callback,
    required this.selected,
    required this.selectImage,
    this.unselectImage,
    this.backgroundColor,
    super.key,
  });

  final VoidCallback callback;
  final bool selected;
  final Widget selectImage;
  final Widget? unselectImage;
  final Color? backgroundColor;
  @override
  State<CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<CallButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.callback,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: widget.backgroundColor ??
              (widget.selected
                  ? const Color.fromRGBO(255, 255, 255, 1)
                  : const Color.fromRGBO(255, 255, 255, 0.2)),
        ),
        width: 64,
        height: 64,
        child: widget.selected
            ? widget.selectImage
            : widget.unselectImage ?? widget.selectImage,
      ),
    );
  }
}
