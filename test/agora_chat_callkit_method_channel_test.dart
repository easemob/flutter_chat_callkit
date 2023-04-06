import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora_chat_callkit/agora_chat_callkit_method_channel.dart';

void main() {
  MethodChannelAgoraChatCallkit platform = MethodChannelAgoraChatCallkit();
  const MethodChannel channel = MethodChannel('agora_chat_callkit');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
