# Get Started with Agora Chat UIKit for Flutter

## Overview

`agora_chat_callkit` is a video and audio component library built on top of `agora_chat_sdk` and `agora_rtc_engine`. It provides logic modules for making and receiving calls, including 1v1 voice calls, 1v1 video calls, and multi-party audio and video calls. It uses agora_chat_sdk to handle call invitations and negotiations. After negotiations are complete, the AgoraChatCallManager.setRTCTokenHandler method is called back, and the agoraToken needs to be returned. The agoraToken must be provided by the developer.

In a 1v1 audio/video call, the caller invites the receiver to join the call using the `AgoraChatCallManager#startSingleCall` method. The receiver receives the call invitation through the `AgoraChatCallKitEventHandler#onReceiveCall` callback, and can then handle the call using the `AgoraChatCallManager#answer` or `AgoraChatCallManager#hangup` methods. When hanging up, the `AgoraChatCallManager#hangup` method must be called, and the other party will receive the `AgoraChatCallKitEventHandler#onCallEnd` callback.

In multi-party audio and video calls, the `AgoraChatCallManager#startInviteUsers` is used to invite multiple users to the call. The called party will receive the call invitation through the `AgoraChatCallKitEventHandler#onReceiveCall` method, and can handle the call by using `AgoraChatCallManager#answer` or `AgoraChatCallManager#hangup`. When other users join or leave the call during the call, the `AgoraChatCallKitEventHandler#onUserJoined` and `AgoraChatCallKitEventHandler#onUserLeaved` methods will be called back, and UI should be modified accordingly. Multi-party calls do not end automatically, so when it is necessary to end the call, the `AgoraChatCallManager#hangup` method must be called actively.

When conducting a 1v1 video call or a group video call, use the `AgoraChatCallManager#getLocalVideoView` method to obtain the local video view and the `AgoraChatCallManager#getRemoteVideoView` method to obtain the remote video view.

## Dependencies

```dart
dependencies:
  agora_chat_sdk: 1.1.0
  agora_rtc_engine: 6.1.0
```

## Permissions

### Android

```
<manifest>
...
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<!-- The Agora SDK requires Bluetooth permissions in case users are using Bluetooth devices.-->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WAKE_LOCK"/>
...
</manifest>
```

### iOS

Open info.plist and add:

```
Privacy - Microphone Usage Description, and add a note in the Value column.
Privacy - Camera Usage Description, and add a note in the Value column.
```

## Prevent code obfuscation

In the quick_start/android/app/proguard-rules.pro file, add the following lines to prevent code obfuscation:
```
-keep class com.hyphenate.** {*;}
-dontwarn  com.hyphenate.**
```

## Getting started

Integrate callkit, which can be downloaded locally or integrated through git.

### Local integration

```dart
dependencies:
    agora_chat_callkit:
        path: `<#callkit path#>`
```

### Github integration

```dart
dependencies:
    agora_chat_callkit:
        git:
            url: https://github.com/easemob/flutter_chat_callkit.git
            ref: dev
```

## Usage

To obtain `agoraToken`, you need to set up an AppServer and provide a mapping service for agoraUid and userId. In the demo, you can specify the AppServer by configuring `example/lib/config.dart`.

You need to make sure the agora chat sdk is initialized before calling AgoraChatCallKit and AgoraChatCallKit widget at the top of you widget tree. You can add it in the `MaterialApp` builder.

```dart
import 'package:agora_chat_callkit/agora_chat_callkit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child){
         return AgoraChatCallKit(
            agoraAppId: <--Add Your Agora App Id Here-->,
            child: child!,
          );
      },
      home: const MyHomePage(title: 'Flutter Demo'),
    );
  }
}
```

## example

See the example for the effect.

### quick start

If demo is required, configure the following information in the `example/lib/config.dart` file:

```dart
class Config {
  static String agoraAppId = "";
  static String appkey = "";

  static String appServerTokenURL = "";
  static String appServerUserMapperURL = "";
  static String appServerHost = "";
}
```

Add event listeners, which are located in the home.dart file in the demo.

```
  void initState() {
    super.initState();

    AgoraChatCallManager.setRTCTokenHandler((channel, agoraAppId, agoraUid) {
      return requestAppServerToken(channel, agoraAppId, agoraUid);
    });

    AgoraChatCallManager.setUserMapperHandler((channel, agoraUid) {
      return requestAppServerUserMapper(channel, agoraUid);
    });

    AgoraChatCallManager.addEventListener(
        "home",
        AgoraChatCallKitEventHandler(
          onReceiveCall: onReceiveCall,
          onCallEnd: (callId, reason) {
            debugPrint('call end: reason: $reason');
          },
          onAnswer: (callId) {
            debugPrint('call answer: $callId');
          },
        ));
  }

```

## License

The sample projects are under the MIT license.