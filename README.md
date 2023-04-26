# Get Started with Agora Chat CallKit for Flutter

## Overview

`agora_chat_callkit` is a video and audio component library built on top of `agora_chat_sdk` and `agora_rtc_engine`. It provides logic modules for making and receiving calls, including 1v1 voice calls, 1v1 video calls, and multi-party audio and video calls. It uses agora_chat_sdk to handle call invitations and negotiations. After negotiations are complete, the `AgoraChatCallManager.setRTCTokenHandler` method is called back, and the agoraToken needs to be returned. The agoraToken must be provided by the developer.

Because the accounts of Agora and AgoraChat are not universal at present, the call invitation is made through the message of AgoraChat, while the call is made through Agora. Therefore, their accounts need to be mapped in `agora_chat_callkit`. Map them through the `AgoraChatCallManager.setUserMapperHandler` callback, When the user joins the call, the agora uid will be called back. After you get the AgoraChat userId, you need to return its corresponding AgoraChat userId to `agora_chat_callkit`, This is required, if there is no mapping, the call will not proceed properly. see `AgoraChatCallUserMapper`.

The `AgoraChatCallManager.initRTC` method is called before a call is made or answered. The `AgoraChatCallManager.releaseRTC` method is called when the call function is no longer used.

In a 1v1 audio/video call, the caller invites the receiver to join the call using the `AgoraChatCallManager.startSingleCall` method. The receiver receives the call invitation through the `AgoraChatCallKitEventHandler.onReceiveCall` callback, and can then handle the call using the `AgoraChatCallManager.answer` or `AgoraChatCallManager.hangup` methods. When hanging up, the `AgoraChatCallManager.hangup` method must be called, and the other party will receive the `AgoraChatCallKitEventHandler.onCallEnd` callback.

In multi-party audio and video calls, the `AgoraChatCallManager.startInviteUsers` is used to invite multiple users to the call. The called party will receive the call invitation through the `AgoraChatCallKitEventHandler.onReceiveCall` method, and can handle the call by using `AgoraChatCallManager.answer` or `AgoraChatCallManager.hangup`. When other users join or leave the call during the call, the `AgoraChatCallKitEventHandler.onUserJoined` and `AgoraChatCallKitEventHandler.onUserLeaved` methods will be called back, and UI should be modified accordingly. Multi-party calls do not end automatically, so when it is necessary to end the call, the `AgoraChatCallManager.hangup` method must be called actively.

When conducting a 1v1 video call or a group video call, use the `AgoraChatCallManager.getLocalVideoView` method to obtain the local video view and the `AgoraChatCallManager.getRemoteVideoView` method to obtain the remote video view.

## Dependencies

```dart
dependencies:
  agora_chat_sdk: 1.1.0
  agora_rtc_engine: 6.1.0
```

## Permissions

### Android

```xml
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

```xml
Privacy - Microphone Usage Description, and add a note in the Value column.
Privacy - Camera Usage Description, and add a note in the Value column.
```

## Prevent code obfuscation

In the example/android/app/proguard-rules.pro file, add the following lines to prevent code obfuscation:

```xml
-keep class com.hyphenate.** {*;}
-dontwarn  com.hyphenate.**
```

## Getting started

Integrate callkit, which can be downloaded locally or integrated through git.

### Local integration (temporary)

```dart
dependencies:
    agora_chat_callkit:
        path: `<#callkit path#>`
```

### Github integration (temporary)

```dart
dependencies:
    agora_chat_callkit:
        git:
            url: https://github.com/easemob/flutter_chat_callkit.git
            ref: dev
```

## Usage

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

### Added agoraToken callback

Agora needs token and channel id when joining channel, so these two parameters are also needed when join channel in agora_chat_callkit. agora_chat_callkit gets these two parameters with the `AgoraChatCallManager.setRTCTokenHandler` callback.

```dart
// channel: The channel to be joined.
// agoraAppId: agora app id.
// agoraUid: agora userId
AgoraChatCallManager.setRTCTokenHandler((channel, agoraAppId, agoraUid) {
  // agoraToken: agora userId token;
  // agoraUid: agora userId
  return Future(() => {agoraToken, agoraUid});
});
```

### Added User mapper callback

Set the callback of the mapping between agora uid and agora chat userId.

```dart
// channel: Indicates the channel to which agoraUid belongs.
// agoraUid: The agoraUid corresponding to the userId is required.
AgoraChatCallManager.setUserMapperHandler((channel, agoraUid) {
  // channel: Indicates the channel to which agoraUid belongs.
  // agoraUid: The agoraUid corresponding to the userId is required.
  // userId: The agoraUid indicates the corresponding agoraChat userId.
  return Future(() => AgoraChatCallUserMapper(channel, {agoraUid, userId}));
});
```

### Added Call Event handler callback

Add a `AgoraChatCallKitEventHandler` listener through the `AgoraChatCallManager.addEventListener` method. Call `AgoraChatCallManager.removeEventListener` to remove the listener when not in use.

```dart
AgoraChatCallManager.addEventListener(
  // Handler key. This key is used to ensure that the handler is unique.
  // This key is required when deleting the handler.
  UNIQUE_HANDLER_ID,
  // CallKit EventHandler.
  AgoraChatCallKitEventHandler(),
);
```

AgoraChatCallKitEventHandler description.

```dart
  /// AgoraChatCallKit event handler.
  ///
  /// Param [onError] Call back when the call fails, See [AgoraChatCallError].
  ///
  /// Param [onCallEnd] Call back when the call ends, See [AgoraChatCallEndReason].
  ///
  /// Param [onReceiveCall] Call back when you receive a call invitation.
  ///
  /// Param [onJoinedChannel] The current user joins the call callback.
  ///
  /// Param [onUserLeaved] Call back when an active user leaves.
  ///
  /// Param [onUserJoined] Callback when a user joins a call.
  ///
  /// Param [onUserMuteAudio] Callback when the peer's mute status changes.
  ///
  /// Param [onUserMuteVideo] Callback when the peer's camera status changes.
  ///
  /// Param [onUserRemoved] Callback when the user rejects the call or the call times out.
  ///
  /// Param [onAnswer] Call back when the call is answered.
  ///
  AgoraChatCallKitEventHandler({
    this.onError,
    this.onCallEnd,
    this.onReceiveCall,
    this.onJoinedChannel,
    this.onUserLeaved,
    this.onUserJoined,
    this.onUserMuteAudio,****
    this.onUserMuteVideo,
    this.onUserRemoved,
    this.onAnswer,
  });
```

|Event| Description|
--|--
final void Function(AgoraChatCallError error)? onError| Callback when the call fails, see `AgoraChatCallError`.
final void Function(String? callId, AgoraChatCallEndReason reason)? onCallEnd| Call end callback, see `AgoraChatCallEndReason`.
final void Function(int agoraUid, String? userId)? onUserLeaved| This is only possible when multi call are callback. The call is called back when another user who has joined the call leaves. `agoraUid` Agora uid. `userId` AgoraChat userId.
final void Function(int agoraUid, String? userId)? onUserJoined| Callbacks when the user joins the call. `agoraUid` Agora uid. `userId` AgoraChat userId.
final void Function(String channel)? onJoinedChannel| Callback when the current account joins a call. `channel` channel id.
final void Function(String callId)? onAnswer| During a 1v1 call, the callback is made when you or the other party call `AgoraChatCallManager.answer` method to join the call.
final void Function(String userId, String callId, AgoraChatCallType callType, Map<String, String>? ext)? onReceiveCall| Call back when you receive a call invitation. `userId` the caller id AgoraChat userId, `callId` current call id. `callType` current call type, see `AgoraChatCallType`.
final void Function(int agoraUid, bool muted)? onUserMuteAudio| The callback is made when the peer microphone status changes. `agoraUid` peer agora uid. `muted` mute status.
final void Function(int agoraUid, bool muted)? onUserMuteVideo| The callback is made when the peer camera status changes. `agoraUid` peer agora uid. `muted` camera status.
final void Function(String callId, String userId, AgoraChatCallEndReason reason)? onUserRemoved| This is only possible when multi call are callback. Hang up the callback when the other party does not enter the call. `callId` current call id. Rejector AgoraChat userId. `reason` hangup reason. see `AgoraChatCallEndReason`.

### Start single call

When you need to make or answer a call, you need to call the `AgoraChatCallManager.initRTC` method first.

Make a 1v1 call using the `AgoraChatCallManager.startSingleCall` method, the method returns `callId`, which, for the caller, is used as an argument to hang up the call.

```dart
await AgoraChatCallManager.initRTC();
try {
  // userId: caller Id
  // type: AgoraChatCallType, It can be audio_1v1 or video_1v1.
  String callId = await AgoraChatCallManager.startSingleCall(
    userId,
    type: type,
  );
} on AgoraChatCallError catch (e) {
  ...
}
```

### Start multi call

When you need to make or answer a call, you need to call the `AgoraChatCallManager.initRTC` method first.

When you initiate a multi call, you can invite other users through `await AgoraChatCallManager.startInviteUsers`. The method returns `callId`, which, for the caller, is used as an argument to hang up the call.

```dart
await AgoraChatCallManager.initRTC();
try {
  // userId: caller Id
  // userList: The userId list.
  String callId = await AgoraChatCallManager.startInviteUsers(userList);
} on AgoraChatCallError catch (e) {
  ...
}
```

### Receive call

Add a `AgoraChatCallKitEventHandler` listener through the `AgoraChatCallManager.addEventListener` method. Call `AgoraChatCallManager.removeEventListener` to remove the listener when not in use.

```dart
AgoraChatCallManager.addEventListener(
  // Handler key. This key is used to ensure that the handler is unique.
  // This key is required when deleting the handler.
  UNIQUE_HANDLER_ID,
  AgoraChatCallKitEventHandler(
    // Call back the method when you receive an invitation.
    onReceiveCall(String userId, String callId, AgoraChatCallType callType, Map<String, String>? ext) {
      // receive a call.
    }
  ),
);
```

### Answer call

Upon receiving the onReceiveCall callback, the audio and video page can be displayed according to the callType.

When you need answer call, you need to call the `AgoraChatCallManager.initRTC` method first.

```dart
await AgoraChatCallManager.initRTC();
try {
  // callId: in the onReceiveCall method callback.
  await AgoraChatCallManager.answer(callId);
} on AgoraChatCallError catch (e) {
  ...
}
```

### Hangup call

At the end of the call, you need to call the `AgoraChatCallManager.releaseRTC` method.

```dart
try {
  // callId: in the onReceiveCall method callback.
  await AgoraChatCallManager.hangup(callId);
} on AgoraChatCallError catch (e) {
  ...
}
await AgoraChatCallManager.releaseRTC();
```

### Turn on Speaker

You can use the `AgoraChatCallManager.speakerOn` method to turn on speaker and the `AgoraChatCallManager.speakerOff` method to turn off speaker during a call.

Enable speaker

```dart
await AgoraChatCallManager.speakerOn();
```

Disable speaker

```dart
await AgoraChatCallManager.speakerOff();
```

### Mute microphone

You can use the `AgoraChatCallManager.mute` method to disable microphone and the `AgoraChatCallManager.unMute` method to enable microphone during a call. When the status of the microphone changes, users in other calls can receive the status change callback by listening `AgoraChatCallKitEventHandler.onUserMuteAudio`.

Mute microphone

```dart
await AgoraChatCallManager.mute();
```

Unmute microphone

```dart
await AgoraChatCallManager.unMute();
```

### Turn off camera

Turn on the camera, when you call `AgoraChatCallManager.cameraOn`, and turn the camera when you call `AgoraChatCallManager.cameraOff`, the other party will receive a `AgoraChatCallKitEventHandler.onUserMuteVideo` callback.

Turn on camera

```dart
await AgoraChatCallManager.cameraOn();
```

Turn off camera

```dart
await AgoraChatCallManager.cameraOff();
```

### Switch camera

You can switch the front and rear cameras by calling the `AgoraChatCallManager.switchCamera` method.

Switch camera

```dart
await AgoraChatCallManager.switchCamera();
```

### Get local preview view

When using 1v1 video calls or multi calls, you can use the `AgoraChatCallManager.getLocalVideoView` method to obtain the local camera preview widget.

```dart
Widget? localPreviewWidget = AgoraChatCallManager.getLocalVideoView();
```

### Remote video view

When using 1v1 video calls or multi calls, When the other party joins the call, you can use the `AgoraChatCallManager.getRemoteVideoView` method to obtain each other's video widget.

```dart
// agoraUid: joined user's agora uid.
Widget? remoteVideoWidget = AgoraChatCallManager.getRemoteVideoView(agoraUid);
```

### Delete listener handler

Call `AgoraChatCallManager.removeEventListener` to remove callbacks when callkit is no longer needed.

```dart
// UNIQUE_HANDLER_ID: The key that was set when you added AgoraChatCallKitEventHandler.
AgoraChatCallManager.removeEventListener(UNIQUE_HANDLER_ID);
```

## Push notifications
In scenarios where the app runs on the background or goes offline, use push notifications to ensure that the callee receives the call invitation. To enable push notifications, see [Set up push notifications](https://docs.agora.io/en/agora-chat/develop/offline-push?platform=flutter).

Once push notifications are enabled, when a call invitation arrives, a notification message pops out on the notification panel. Users can click the message to see the call invitation.



## Example

See the example for the effect.

### Quick start

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

To obtain `agoraToken`, you need to set up an AppServer and provide a mapping service for agoraUid and userId.

## License

The sample projects are under the MIT license.