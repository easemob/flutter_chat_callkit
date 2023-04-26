import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/call_pages/call_button.dart';
import 'package:example/call_pages/multi_call_item_view.dart';
import 'package:example/call_pages/multi_call_view.dart';
import 'package:example/contact_page.dart';
import 'package:flutter/material.dart';

class MultiCallPage extends StatefulWidget {
  factory MultiCallPage.call(
    List<String> userList, {
    Widget? avatar,
    String? nickname,
    TextStyle? nicknameTextStyle,
  }) {
    return MultiCallPage(
      userList: userList,
      isCaller: true,
      avatar: avatar,
      nickname: nickname,
      nicknameTextStyle: nicknameTextStyle,
    );
  }

  factory MultiCallPage.receive(
    String callId,
    String caller, {
    Widget? avatar,
    String? nickname,
    TextStyle? nicknameTextStyle,
  }) {
    return MultiCallPage(
      isCaller: false,
      callId: callId,
      caller: caller,
      avatar: avatar,
      nickname: nickname,
      nicknameTextStyle: nicknameTextStyle,
    );
  }

  const MultiCallPage({
    required this.isCaller,
    this.userList,
    this.caller,
    this.callId,
    this.avatar,
    this.nickname,
    this.nicknameTextStyle,
    super.key,
  });
  final bool isCaller;
  final String? caller;
  final String? callId;
  final Widget? avatar;
  final String? nickname;
  final List<String>? userList;
  final TextStyle? nicknameTextStyle;

  @override
  State<MultiCallPage> createState() => _MultiCallPageState();
}

class _MultiCallPageState extends State<MultiCallPage> {
  final PageController _controller = PageController();
  bool mute = false;
  bool cameraOn = true;
  bool isCalling = false;
  List<MultiCallItemView> list = [];
  List<String>? currentList;
  String? callId;
  @override
  void initState() {
    super.initState();
    addCallKitListener();
    currentList = widget.userList;
    AgoraChatCallManager.initRTC().then((value) {
      afterInit();
    });
  }

  Future<void> afterInit() async {
    if (widget.isCaller && widget.userList != null) {
      isCalling = true;
      callId = await AgoraChatCallManager.startInviteUsers(widget.userList!);
    }

    currentList?.forEach((element) {
      list.add(MultiCallItemView(
        userId: element,
      ));
    });

    String? current = ChatClient.getInstance.currentUserId;
    list.insert(
        0,
        MultiCallItemView(
          userId: current!,
          isWaiting: false,
          videoView: AgoraChatCallManager.getLocalVideoView(),
        ));
    setState(() {});
  }

  void addCallKitListener() {
    AgoraChatCallManager.addEventListener(
      "multi",
      AgoraChatCallKitEventHandler(
        onUserMuteAudio: (agoraUid, muted) {
          int index =
              list.indexWhere((element) => element.agoraUid == agoraUid);
          if (index != -1) {
            MultiCallItemView view = list[index];
            view = view.copyWith(muteAudio: muted);
            list[index] = view;
            setState(() {});
          }
        },
        onUserMuteVideo: (agoraUid, muted) {
          int index =
              list.indexWhere((element) => element.agoraUid == agoraUid);
          if (index != -1) {
            MultiCallItemView view = list[index];
            view = view.copyWith(muteVideo: muted);
            list[index] = view;
            setState(() {});
          }
        },
        onUserJoined: (agoraUid, userId) {
          setState(() {
            list.removeWhere((element) =>
                element.userId == userId || element.agoraUid == agoraUid);
            list.add(MultiCallItemView(
              agoraUid: agoraUid,
              userId: userId,
              isWaiting: false,
              videoView: AgoraChatCallManager.getRemoteVideoView(agoraUid),
            ));
          });
        },
        onUserLeaved: (agoraUid, userId) {
          setState(() {
            list.removeWhere((element) =>
                element.userId == userId || element.agoraUid == agoraUid);
          });
        },
        onCallEnd: (callId, reason) => Navigator.of(context).pop(),
        onUserRemoved: (callId, userId, reason) {
          setState(() {
            list.removeWhere((element) => element.userId == userId);
          });
        },
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

    List<Widget> bottomList = [];
    if (widget.isCaller || isCalling) {
      bottomList = [cameraButton(), muteButton(), hangupButton()];
    } else {
      bottomList = [cameraButton(), hangupButton(), answerButton()];
    }

    content = Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: content),
        SizedBox(
          height: 143,
          child: bottomWidget(bottomList),
        ),
      ],
    );

    List<Widget> topWidget = [switchCameraButton(), const SizedBox(width: 10)];
    if (isCalling) {
      topWidget.addAll([inviteUserButton(), const SizedBox(width: 10)]);
    }

    Widget top = SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: topWidget,
      ),
    );

    content = Stack(
      children: [
        Positioned(child: content),
        Positioned(top: 0, left: 0, right: 0, child: top),
        () {
          return !isCalling ? beforeCallingWidget() : Container();
        }()
      ],
    );

    content = Scaffold(
      body: content,
    );
    return content;
  }

  Widget beforeCallingWidget() {
    Widget avatar = widget.avatar ?? Image.asset('images/avatar.png');

    avatar = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100)),
      clipBehavior: Clip.hardEdge,
      child: avatar,
    );

    Widget content = Column(
      children: [
        avatar,
        const SizedBox(height: 10),
        Text(
          widget.nickname ?? widget.caller ?? "",
          style: widget.nicknameTextStyle ??
              const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 24),
        ),
        const SizedBox(height: 10),
        const Text(
          'Multi Call',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Colors.white,
            fontSize: 14,
          ),
        )
      ],
    );

    content = Positioned(left: 0, right: 0, top: 120, child: content);

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
        setState(() => isCalling = true);
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
        String? currentUserId = ChatClient.getInstance.currentUserId;
        int index = list.indexWhere((element) =>
            currentUserId != null && element.userId == currentUserId);
        if (index != -1) {
          MultiCallItemView view = list[index];
          view = view.copyWith(muteVideo: !cameraOn);
          list[index] = view;
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

  Widget switchCameraButton() {
    return button('switch_camera', () {
      AgoraChatCallManager.switchCamera();
    });
  }

  Widget inviteUserButton() {
    return button('invite_user', () {
      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
        return const ContactPage(isMulti: true);
      })).then((value) {
        if (value != null && value is List<String>) {
          AgoraChatCallManager.startInviteUsers(value);
          return value;
        }
      }).then((value) {
        value?.forEach((element) {
          list.add(MultiCallItemView(userId: element));
        });
        setState(() {});
      });
    });
  }

  Widget button(String imageName, VoidCallback action) {
    return InkWell(
      onTap: action,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromRGBO(255, 255, 255, 0.2),
        ),
        child: Image.asset('images/$imageName.png'),
      ),
    );
  }
}
