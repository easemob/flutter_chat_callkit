import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/call_pages/call_buttom.dart';
import 'package:example/call_pages/multi_call_item_view.dart';
import 'package:example/call_pages/multi_call_view.dart';
import 'package:flutter/material.dart';

class MultiCallPage extends StatefulWidget {
  factory MultiCallPage.call(List<String> userList) {
    return MultiCallPage(userList, isCaller: true);
  }

  factory MultiCallPage.receive(String callId, String caller) {
    return MultiCallPage([caller], isCaller: false, callId: callId);
  }

  const MultiCallPage(
    this.userList, {
    required this.isCaller,
    this.callId,
    super.key,
  });
  final bool isCaller;
  final String? callId;
  final List<String> userList;

  @override
  State<MultiCallPage> createState() => _MultiCallPageState();
}

class _MultiCallPageState extends State<MultiCallPage> {
  final PageController _controller = PageController();
  bool mute = false;
  bool cameraOn = true;
  List<MultiCallItemView> list = [];
  String? callId;
  @override
  void initState() {
    super.initState();
    addCallKitListener();
    AgoraChatCallManager.initRTC().then((value) {
      afterInit();
    });

    _controller.addListener(() {});
  }

  Future<void> afterInit() async {
    if (widget.isCaller) {
      for (var element in widget.userList) {
        list.add(MultiCallItemView(
          userId: element,
        ));
      }

      callId = await AgoraChatCallManager.startInviteUsers(widget.userList);
    }
    setState(() {});
  }

  void addCallKitListener() {
    AgoraChatCallManager.addEventListener(
      "multi",
      AgoraChatCallKitEventHandler(
        onUserJoined: (userId, agoraUid) {
          setState(() {
            list.add(
              MultiCallItemView(
                userId: userId,
              ),
            );
          });
        },
        onUserLeaved: (userId, agoraUid) {
          setState(() {
            list.removeWhere((element) => element.userId == userId);
          });
        },
        onCallEnd: (callId, reason) => Navigator.of(context).pop(),
      ),
    );
  }

  void removeCallKitListener() {
    AgoraChatCallManager.removeEventListener("multi");
  }

  @override
  void dispose() {
    removeCallKitListener();
    AgoraChatCallManager.releaseRTC();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    for (var i = 0; i < list.length; i += 4) {
      int tmp = i + 4;
      if (tmp > list.length) {
        tmp = list.length;
      }
      children.add(
        MultiCallView(
          list.sublist(i, tmp),
        ),
      );
    }

    Widget content = PageView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      children: children,
    );

    content = Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: content),
        SizedBox(
          height: 143,
          child: bottomWidget([
            cameraButton(),
            muteButton(),
            hangupButton(),
          ]),
        ),
      ],
    );

    return content;
  }

  Widget bottomWidget(List<Widget> widgets) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: Colors.black),
        ),
        Positioned.fill(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          children: widgets,
        ))
      ],
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
      },
      selectImage: Image.asset("images/answer.png"),
      backgroundColor: const Color.fromRGBO(0, 206, 118, 1),
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
}
