import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(new MyApp());
}



class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedSplashScreen(
        splash: '[n]http://www.dev-agency.co.uk/ebloffices/wp-content/uploads/2021/05/187e3363-1b1a-4593-aa4d-5f7b9631ceb0.png',
        nextScreen: HomePage(),
        splashIconSize: 100,
        duration: 10,
        splashTransition: SplashTransition.sizeTransition,
      ),
    );
  }
}






class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final GlobalKey webViewKey = GlobalKey();



  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  bool loading = true;

  startSplashScreen() async {
    var duration = const Duration(seconds: 10);
    return Timer(
      duration,
          () {
        setState(() {
          Center(child: Icon(Icons.ac_unit,color: Colors.yellow,));
          loading = false;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    startSplashScreen();

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<bool> _exitApp(BuildContext context) async {
    var status = await webViewController!.canGoBackOrForward(steps: -5);
    if (status) {
      print("onwill goback");
      webViewController?.goBack();
      return Future.value(true);
    } else {
      // ignore: deprecated_member_use
      ScaffoldMessenger(child: const SnackBar(content: Text("No back history item")),
      );
      return Future.value(false);
    }
  }




  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      home: WillPopScope(
        onWillPop: () async {
          webViewController!.goBack();
          return await webViewController!.canGoBackOrForward(steps: -10);
        },
        child: Scaffold(
            body: SafeArea(
                child: Column(children: <Widget>[

                  Expanded(
                    child: Stack(
                      children: [
                        InAppWebView(

                          key: webViewKey,
                          initialUrlRequest:
                          URLRequest(url: Uri.parse("http://www.dev-agency.co.uk/ebloffices")),
                          initialOptions: options,
                          pullToRefreshController: pullToRefreshController,
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                          },
                          onLoadStart: (controller, url) {
                            setState(() {
                              this.url = url.toString();
                              urlController.text = this.url;
                            });
                          },
                          androidOnPermissionRequest: (controller, origin, resources) async {
                            return PermissionRequestResponse(
                                resources: resources,
                                action: PermissionRequestResponseAction.GRANT);
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            var uri = navigationAction.request.url!;

                            if (![ "http", "https", "file", "chrome",
                              "data", "javascript", "about"].contains(uri.scheme)) {
                              if (await canLaunch(url)) {
                                // Launch the App
                                await launch(
                                  url,
                                );
                                // and cancel the request
                                return NavigationActionPolicy.CANCEL;
                              }
                            }

                            return NavigationActionPolicy.ALLOW;
                          },
                          onLoadStop: (controller, url) async {
                            pullToRefreshController.endRefreshing();
                            setState(() {
                              this.url = url.toString();
                              urlController.text = this.url;
                            });
                          },
                          onLoadError: (controller, url, code, message) {
                            pullToRefreshController.endRefreshing();
                          },
                          onProgressChanged: (controller, progress) {
                            if (progress == 100) {
                              pullToRefreshController.endRefreshing();
                            }
                            setState(() {
                              this.progress = progress / 100;
                              urlController.text = this.url;
                            });
                          },
                          onUpdateVisitedHistory: (controller, url, androidIsReload) {
                            setState(() {
                              this.url = url.toString();
                              urlController.text = this.url;
                            });
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            print(consoleMessage);
                          },
                        ),
                        progress < 1.0
                            ? LinearProgressIndicator(value: progress)
                            : Container(),
                      ],
                    ),
                  ),

                ]))),
      ),
    );
  }


}