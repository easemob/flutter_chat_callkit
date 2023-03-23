import 'package:example/config.dart';
import 'package:example/home.dart';
import 'package:example/login.dart';
import 'package:flutter/material.dart';
import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var options =
      ChatOptions(appKey: Config.appkey, debugModel: true, autoLogin: true);
  await ChatClient.getInstance.init(options);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: EasyLoading.init(
        builder: (context, child) {
          return AgoraChatCallKit(
            agoraAppId: Config.agoraAppId,
            child: child!,
          );
        },
      ),
      title: 'Callkit demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Callkit demo'),
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: ((context) {
          if (settings.name == 'login') {
            return const LoginPage();
          } else if (settings.name == 'home') {
            return const HomePage();
          } else {
            return Container();
          }
        }));
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _hasSignIn = false;
  bool _hasLoaded = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: ChatClient.getInstance.isLoginBefore(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _hasSignIn = snapshot.data!;
          }
          return _hasLoaded
              ? getWidget(_hasSignIn)
              : Stack(
                  children: [
                    AnimatedOpacity(
                      opacity: snapshot.hasData ? 0 : 1,
                      duration: const Duration(seconds: 1),
                      child: welcomeWidget(),
                      onEnd: () {
                        if (mounted) {
                          setState(() {
                            _hasLoaded = true;
                          });
                        }
                      },
                    ),
                    Positioned.fill(child: getWidget(_hasSignIn)),
                  ],
                );
        },
      ),
    );
  }

  Widget welcomeWidget() {
    return Container(
      color: Colors.red,
      child: const Icon(
        Icons.abc,
      ),
    );
  }

  Widget getWidget(bool hasSignIn) {
    if (hasSignIn) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}
