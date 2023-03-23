import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:example/config.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
          onPressed: () {
            EasyLoading.show(status: "Sign in...");
            ChatClient.getInstance.login(Config.userId, Config.password).then((value) {
              Navigator.of(context).pushNamed("home");
            }).catchError((err) {
              ChatError e = err as ChatError;
              EasyLoading.showError(e.description);
            }).whenComplete(() => EasyLoading.dismiss());
          },
          child: const Text("Login")),
    );
  }
}
