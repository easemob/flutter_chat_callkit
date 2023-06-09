# Get Started with Agora Chat CallKit for Flutter

`agora_chat_callkit` is a video and audio component library built on top of `agora_chat_sdk` and `agora_rtc_engine`. It provides logical modules for making and receiving calls, including one-to-one voice calls, one-to-one video calls, group audio calls, and group video calls. It uses `agora_chat_sdk` to handle call invitations and negotiations. After negotiations are complete, the `AgoraChatCallManager.setRTCTokenHandler` callback is triggered, and the Agora RTC token needs to be returned. The Agora RTC token must be provided by the developer.

## Understand the tech

For a call, the call invitation is implemented via Agora Chat, while the call is made through Agora RTC. As the accounts of Agora RTC and Agora Chat are not globally recognizable at present, the accounts need to be mapped via the `AgoraChatCallManager.setUserMapperHandler` callback in `agora_chat_callkit`. When a user joins the call, the Agora RTC user ID (UID) will be returned via the callback. After you get the corresponding Agora Chat user ID, you need to return it to `agora_chat_callkit`. If there is no mapping between the two user IDs, the call will not proceed properly. See `AgoraChatCallUserMapper`.

This section describes how to implement a one-to-one call or group call. 

<div class="alert note">The `AgoraChatCallManager.initRTC` method is called before a call is made or answered.</div>

The basic process for implementing a one-to-one audio or video call is as follows:

1. The caller calls the `AgoraChatCallManager.startSingleCall` method to invite the callee to join the call. 
2. The callee receives the call invitation through the `AgoraChatCallKitEventHandler.onReceiveCall` callback and handles the call:
   - To answer the call, the callee calls the `AgoraChatCallManager.answer` method. The other party receives the `AgoraChatCallKitEventHandler.onUserJoined` event and the call starts.
   - To hang up the call, the callee calls the `AgoraChatCallManager.releaseRTC` method. The other party receives the `AgoraChatCallKitEventHandler.onCallEnd` event.

The basic process for implementing a group audio or video call is as follows:   

1. The caller calls the `AgoraChatCallManager.startInviteUsers` method to invite multiple users to join the call. 
2. The callee receives the call invitation through the `AgoraChatCallKitEventHandler.onReceiveCall` event and handles the call:
  - To answer the call, the callee calls the `AgoraChatCallManager.answer` method. The other parties receive the `AgoraChatCallKitEventHandler.onUserJoined` event and the call starts.
  - To hang up the call, the callee calls the `AgoraChatCallManager.releaseRTC` method. Group calls do not end automatically, and therefore the users need to call this method to hang up the call. 

<div class="alert note">When users join or leave the call, the UI should be modified accordingly.</div> 

## Prerequisites

In order to follow the procedure in this page, you must have the following:

- A valid Agora [account](https://docs.agora.io/en/video-calling/reference/manage-agora-account/#create-an-agora-account)
- An Agora [project](https://docs.agora.io/en/video-calling/reference/manage-agora-account/#create-an-agora-project) with an [App Key](https://docs.agora.io/en/agora-chat/get-started/enable#get-the-information-of-the-chat-project) that has [enabled the Chat service](https://docs.agora.io/en/agora-chat/get-started/enable)

If your target platform is iOS, your development environment must meet the following requirements:
- Flutter 2.10 or later
- Dart 2.16 or later
- macOS
- Xcode 12.4 or later with Xcode Command Line Tools
- CocoaPods
- An iOS simulator or a real iOS device running iOS 10.0 or later

If your target platform is Android, your development environment must meet the following requirements:
- Flutter 2.10 or later
- Dart 2.16 or later
- macOS or Windows
- Android Studio 4.0 or later with JDK 1.8 or later
- An Android simulator or a real Android device running Android SDK API level 21 or later

<div class="alert note">You can run <code>flutter doctor</code> to see if there are any platform dependencies you need to complete the setup.</div>

## Project setup

### Add the dependencies

Add the following dependencies in `pubspec.yaml`:

```
  agora_chat_sdk: 1.1.0
  agora_rtc_engine: 6.1.0
```

### Add project permissions

#### Android

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

#### iOS

Add the following lines to **info.plist**:


|Key|Type|Value|
---|---|---
`Privacy - Microphone Usage Description` | String | For microphone access
`Privacy - Camera Usage Description` | String | For camera access


### Prevent code obfuscation

In the example/android/app/proguard-rules.pro file, add the following lines to prevent code obfuscation: </application>

```
-keep class com.hyphenate.** {*;}
-dontwarn  com.hyphenate.**
```


## Implement audio and video calling

You need to make sure that the Agora Chat SDK is initialized before calling AgoraChatCallKit and AgoraChatCallKit widget at the top of your widget tree. You can add it in the `MaterialApp` builder.

```
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

### Add the Agora token callback

Agora RTC needs a token and a channel ID to join a channel. Therefore, the two parameters are required when `agora_chat_callkit` is used. `agora_chat_callkit` gets the two parameters from the `AgoraChatCallManager.setRTCTokenHandler` callback.

```
// channel: The channel to join.
// agoraAppId: The Agora app ID.
// agoraUid: The user ID (UID) of Agora RTC.
AgoraChatCallManager.setRTCTokenHandler((channel, agoraAppId, agoraUid) {
  // agoraToken: The token of the Agora RTC user.
  // agoraUid: The user ID of Agora RTC.
  return Future(() => {agoraToken, agoraUid});
});
```

### Add the user mapping callback

Set the callback of the mapping between the Agora RTC user ID and Agora Chat user ID.

```
// channel: The channel to which the Agora RTC user ID belongs.
// agoraUid: The Agora RTC user ID that corresponds to the Agora Chat user ID.
AgoraChatCallManager.setUserMapperHandler((channel, agoraUid) {
  // channel: The channel to which the Agora RTC user ID belongs.
  // agoraUid: The Agora RTC user ID that corresponds to the Agora Chat user ID.
  // userId: The Agora Chat user ID that corresponds to the Agora RTC user ID.
  return Future(() => AgoraChatCallUserMapper(channel, {agoraUid, userId}));
});
```

### Listen for callback events

Add a `AgoraChatCallKitEventHandler` listener by using the `AgoraChatCallManager.addEventListener` method. Call `AgoraChatCallManager.removeEventListener` to remove the listener when not in use.

```
AgoraChatCallManager.addEventListener(
  // Handler key. This key is used to ensure that the handler is unique.
  // This key is required when deleting the handler.
  UNIQUE_HANDLER_ID,
  // CallKit EventHandler.
  AgoraChatCallKitEventHandler(),
);
```

`AgoraChatCallKitEventHandler` is described as follows:

```
  /// AgoraChatCallKit event handler.
  ///
  /// Param [onError] Occurs when the call fails. See [AgoraChatCallError].
  ///
  /// Param [onCallEnd] Occurs when the call ends. See [AgoraChatCallEndReason].
  ///
  /// Param [onReceiveCall] Occurs when a call invitation is received.
  ///
  /// Param [onJoinedChannel] Occurs when the current user joins the call.
  /// 
  /// Param [onUserLeaved] Occurs when an active user leaves.
  ///
  /// Param [onUserJoined] Occurs when a user joins a call.
  ///
  /// Param [onUserMuteAudio] Occurs when the peer's mute status changes during an audio call.
  ///
  /// Param [onUserMuteVideo] Occurs when the peer's camera status changes during a video call.
  ///
  /// Param [onUserRemoved] Occurs when the callee rejects the call or the call times out.
  ///
  /// Param [onAnswer] Occurs when the call is answered.
  ///
  AgoraChatCallKitEventHandler({
    this.onError,
    this.onCallEnd,
    this.onReceiveCall,
    this.onJoinedChannel,
    this.onUserLeaved,
    this.onUserJoined,
    this.onUserMuteAudio,
    this.onUserMuteVideo,
    this.onUserRemoved,
    this.onAnswer,
  });
```

| Event             | Description                    |
| :---------------- | :----------------------- |
| final void Function(AgoraChatCallError error)? onError       | Occurs when the call fails. For example, the callee fails to join the channel or the call invitation fails to be sent. The operator receives the event. This event is applicable to one-to-one calls and group calls. See `AgoraChatCallError`.  |
| final void Function(String? callId, AgoraChatCallEndReason reason)? onCallEnd | Occurs when the call ends. This event is applicable only to one-to-one calls. Both the caller and callee receive this event. See `AgoraChatCallEndReason`.  |
| final void Function(int agoraUid, String? userId)? onUserLeaved | Occurs when an active user leaves. This event is applicable only to group calls. All other users in the call receive this event. In this event, `agoraUid` indicates the Agora RTC user ID and `userId` indicates the Agora Chat user ID. |
| final void Function(int agoraUid, String? userId)? onUserJoined | Occurs when a user joins a call. The user that joins the call receives this event. This event is applicable only to group calls. In this event, `agoraUid` indicates the Agora RTC user ID and `userId` indicates the Agora Chat user ID. |
| final void Function(String channel)? onJoinedChannel         | Occurs when the current user joins the call. This event is applicable only to group calls. All other users in the call receive this event. In this event, `channel` indicates the channel ID. |
| final void Function(String callId)? onAnswer                 | Occurs when the call is answered. This event is applicable only to one-to-one calls. Both the caller and callee receive this event. |
| final void Function(String userId, String callId, AgoraChatCallType callType, Map<String, String>? ext)? onReceiveCall | Occurs when a call invitation is received. This event is applicable to both one-to-one calls and groups calls. The callee receives this event. In this event, `userId` indicates the Agora Chat user ID of the caller, `callId` indicates the ID of the current call, and `callType` indicates the current call type. See `AgoraChatCallType`. |
| final void Function(int agoraUid, bool muted)? onUserMuteAudio | Occurs when the microphone status of the peer user changes. This event is applicable to both one-to-one calls and groups calls. The peer user in one-to-one calls or other users in group calls receive this event. In this event, `agoraUid` indicates the Agora RTC user ID of the peer user and `muted` indicates whether the peer microphone is muted or not. |
| final void Function(int agoraUid, bool muted)? onUserMuteVideo | Occurs when the camera status of the peer user changes. This event is applicable to both one-to-one calls and groups calls. The peer user in one-to-one calls or other users in group calls receive this event. In this event, `agoraUid` indicates the Agora RTC user ID of the peer user and `muted` indicates whether the peer camera is disabled or not. |
| final void Function(String callId, String userId, AgoraChatCallEndReason reason)? onUserRemoved | Occurs when the callee rejects the call or the call times out. This event is applicable only to groups calls. The caller receives this event. In this event, `callId` indicates the current call ID, `userId` indicates the Agora Chat user ID of the callee, and `reason` indicates the hangup reason. See `AgoraChatCallEndReason`. |

### Start a call 

Before making or answering a call, you need to first call the `AgoraChatCallManager.initRTC` method to initialize Agora RTC. 

#### Start a one-to-one call

Call the `AgoraChatCallManager.startSingleCall` method to make a one-to-one call. This method returns the `callId` parameter which can be used by the caller to hang up the call. The callee receives the `onReceiveCall` event.

```
await AgoraChatCallManager.initRTC();
try {
  // userId: The Agora Chat user ID of the callee.
  // type: The call type, which can be `AgoraChatCallType.audio_1v1` or `AgoraChatCallType.video_1v1`. 
  String callId = await AgoraChatCallManager.startSingleCall(
    userId,
    type: AgoraChatCallType.audio_1v1,
  );
} on AgoraChatCallError catch (e) {
  ...
}
```

#### Start a group call

To make a group call, you can call the `await AgoraChatCallManager.startInviteUsers` method to invite users to join
 the call. This method returns the `callId` parameter which can be used by the caller to hang up the call. The callees receive the `onReceiveCall` event.

```
await AgoraChatCallManager.initRTC();
try {
  // userList: The Agora Chat user IDs of the callees.
  String callId = await AgoraChatCallManager.startInviteUsers(userList);
} on AgoraChatCallError catch (e) {
  ...
}
```

### Receive a call

To listen for the received call invitation, the users need to first add a `AgoraChatCallKitEventHandler` listener by using the `AgoraChatCallManager.addEventListener` method. Call `AgoraChatCallManager.removeEventListener` to remove the listener when not in use.

In either a one-to-one call or group call, once a call invitation is sent, the callee receives the invitation in the `onReceiveCall` callback. The audio or video page can be displayed, depending on the call type.

```
AgoraChatCallManager.addEventListener(
  // Handler key. This key is used to ensure that the handler is unique.
  // This key is required when deleting the handler.
  UNIQUE_HANDLER_ID,
  AgoraChatCallKitEventHandler(
    // Occurs when you receive a call invitation.
    onReceiveCall(String userId, String callId, AgoraChatCallType callType, Map<String, String>? ext) {
      // Receive a call.
    }
  ),
);
```

The callee needs to choose whether to answer or reject the call:

- To answer a call, call the `AgoraChatCallManager.initRTC` method first and then the `answer` method.

In a one-to-one call, both the caller and callee receive the `onAnswer` event. In a group call, the new user that joins the call receives the `onUserJoined` event and other users in the call receive the `onJoinedChannel` event.

```
await AgoraChatCallManager.initRTC();
try {
  // callId: The call ID which can be obtained from the onReceiveCall callback.
  await AgoraChatCallManager.answer(callId);
} on AgoraChatCallError catch (e) {
  ...
}
```

- To reject the call, call the `AgoraChatCallManager.releaseRTC` method:

For a one-to-one call, the caller receives the `onError` event. For a group call, other users than the callee receive the `onUserRemoved` event.

```
try {
  // callId: The call ID which can be obtained via the `onReceiveCall` callback.
  await AgoraChatCallManager.hangup(callId);
} on AgoraChatCallError catch (e) {
  ...
}
await AgoraChatCallManager.releaseRTC();
```

### End the call

A one-to-one call ends as soon as one of the two users hangs up, while a group call ends only after the local user hangs up.

For a one-to-one call, either the caller or callee can call the `AgoraChatCallManager.releaseRTC` method to end the call. When one party ends the call, the other party receives the `onCallEnd` event.

For a group call, when a user calls the `AgoraChatCallManager.releaseRTC` method to leave a call, other users in the call receive the `onUserLeaved` event.

## Next steps

### Turn on or off the speaker

You can call the `AgoraChatCallManager.speakerOn` or `AgoraChatCallManager.speakerOff` method to turn on or turn off the speaker during a call. 

```
await AgoraChatCallManager.speakerOn();
await AgoraChatCallManager.speakerOff();
```

### Mute or unmute the microphone

You can call the `AgoraChatCallManager.mute` or `AgoraChatCallManager.unMute` method to mute or unmute the microphone during a call. When the microphone status changes, the peer user in the one-to-one call or other users in the group call receive the `AgoraChatCallKitEventHandler.onUserMuteAudio` event.

```
await AgoraChatCallManager.mute();
await AgoraChatCallManager.unMute();
```

### Turn on or off the camera

You can call the `AgoraChatCallManager.cameraOn` or `AgoraChatCallManager.cameraOff` method to turn on or turn off the camera. The peer user in the one-to-one call or other users in the group call receive the `AgoraChatCallKitEventHandler.onUserMuteVideo` event.

```
await AgoraChatCallManager.cameraOn();
await AgoraChatCallManager.cameraOff();
```

### Switch the camera

You can call the `AgoraChatCallManager.switchCamera` method to switch the front and rear cameras.

```
await AgoraChatCallManager.switchCamera();
```

### Get the local preview view  

When making a one-to-one video call or group call, you can call the `AgoraChatCallManager.getLocalVideoView` method to obtain the local camera preview widget.

```
Widget? localPreviewWidget = AgoraChatCallManager.getLocalVideoView();
```

### Get the remote video view

During a one-to-one video call or group call, if a user joins the call, you can call the `AgoraChatCallManager.getRemoteVideoView` method to obtain the video widget of this user.

```
// agoraUid: The Agora RTF user ID of a user in the call.
Widget? remoteVideoWidget = AgoraChatCallManager.getRemoteVideoView(agoraUid);
```

### Delete the listener handler

You can call the `AgoraChatCallManager.removeEventListener` method to remove callbacks when the callkit is no longer needed.

```
// UNIQUE_HANDLER_ID: The key that was set when you added AgoraChatCallKitEventHandler.
AgoraChatCallManager.removeEventListener(UNIQUE_HANDLER_ID);
```

## Push notifications

In scenarios where the app runs on the background or goes offline, use push notifications to ensure that the callee receives the call invitation. To enable push notifications, see [Set up push notifications](https://docs.agora.io/en/agora-chat/develop/offline-push?platform=flutter).

Once push notifications are enabled, when a call invitation arrives, a notification message pops out on the notification panel. Users can click the message to view the call invitation.

## Reference

### API list

This section provides other reference information that you can refer to when implementing real-time audio and video communications functionalities.

In `agora_chat_callkit`, `AgoraChatCallManager` provides the following APIs:

|  Method          | Description              |
| :-------------------------- | :------------------ |
| addEventListener          | Adds an event listener.   |
| removeEventListener       | Removes an event listener.   |
| initRTC             | Initializes the Agora RTC.         |
| startSingleCall           | Makes a one-to-one call.    |
| startInviteUsers       | Invites users to join a group call.      |
| answer          | Answers a call.        |
| releaseRTC       | Rejects a call or hangs up a call.      |
| speakerOn           | Turns on the speaker.            |
| speakerOff       | Turns off the speaker.          |
| mute          | Mutes the microphone.            |
| unMute        | Unmutes the microphone.          |
| cameraOn           | Turns on the camera.           |
| cameraOff     | Turns off the camera.        |
| switchCamera   | Switches the front and rear cameras.           |
| getLocalVideoView  | Gets the local video view.            |
| getRemoteVideoView    | Gets the remote video view.          |

`AgoraChatCallKitEventHandler` contains call-related events. For details, see [Listen for callback events](#Listen for callback events).

### Sample project

If demo is required, configure the following information in the `example/lib/config.dart` file:

```
class Config {
  static String agoraAppId = "";
  static String appkey = "";

  static String appServerDomain = "";

  static String appServerRegister = '';
  static String appServerGetAgoraToken = '';

  static String appServerTokenURL = "";
  static String appServerUserMapperURL = "";
}
```

To obtain the Agora RTC token, you need to set up an [App Server](./authentication#Deploy an app server to generate tokens) and provide a mapping service for the agora user ID and the Agora Chat user ID.
