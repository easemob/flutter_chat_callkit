import 'package:flutter_test/flutter_test.dart';
import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:agora_chat_callkit/agora_chat_callkit_platform_interface.dart';
import 'package:agora_chat_callkit/agora_chat_callkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAgoraChatCallkitPlatform
    with MockPlatformInterfaceMixin
    implements AgoraChatCallkitPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AgoraChatCallkitPlatform initialPlatform = AgoraChatCallkitPlatform.instance;

  test('$MethodChannelAgoraChatCallkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAgoraChatCallkit>());
  });

  test('getPlatformVersion', () async {
    AgoraChatCallkit agoraChatCallkitPlugin = AgoraChatCallkit();
    MockAgoraChatCallkitPlatform fakePlatform = MockAgoraChatCallkitPlatform();
    AgoraChatCallkitPlatform.instance = fakePlatform;

    expect(await agoraChatCallkitPlugin.getPlatformVersion(), '42');
  });
}
