import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:flutter/foundation.dart';

class AgoraChatManagerEventHandler {}

class AgoraChatManager {
  AgoraChatManager(this.eventHandler) {
    ChatClient.getInstance.chatManager.addEventHandler(
      key,
      ChatEventHandler(
        onCmdMessagesReceived: onMessageReceived,
        onMessagesReceived: onMessageReceived,
      ),
    );
  }

  final String key = "AgoraChatCallKit";
  final AgoraChatManagerEventHandler eventHandler;

  void onMessageReceived(List<ChatMessage> list) {
    for (var msg in list) {
      _parseMsg(msg);
    }
  }

  void _parseMsg(ChatMessage message) async {}
}
