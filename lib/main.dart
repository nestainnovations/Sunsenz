import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:new_version_plus/new_version_plus.dart';

void main() {
  runApp(SunsenzServeApp());
}

class SunsenzServeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunsenz',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  void _checkVersion() async {
    final newVersion = NewVersionPlus(androidId: "in.sunsenz.service"); // Replace with your app's package name
    final status = await newVersion.getVersionStatus();

    if (status != null && status.canUpdate) {
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dialogTitle: 'Update Available',
        dialogText: 'A new version of the app is available! Please update to continue.',
        updateButtonText: 'Update Now',
        dismissButtonText: 'Later',
        dismissAction: () {
          _navigateToHome();
        },
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/Logo-RBG.png', // Replace with your actual logo path
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        setState(() {
          _hasInternet = false;
        });
      } else {
        setState(() {
          _hasInternet = true;
          _controller.reload();
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _hasInternet = false;
      });
    } else {
      setState(() {
        _hasInternet = true;
      });
    }
  }

  bool _shouldLaunchInExternalApp(String url) {
    final externalSchemes = ['tel:', 'mailto:', 'https://maps.app.goo.gl/', 'http://maps.app.goo.gl/'];
    return externalSchemes.any((scheme) => url.startsWith(scheme));
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'Moopens Service',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: const Color(0xFFD91818),
        ),
        body: _hasInternet
            ? Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri('https://service.sunsenz.com/public/en/member/login'),
                      headers: {
                        "Cache-Control": "no-cache",
                        "Pragma": "no-cache",
                        "Expires": "0",
                      },
                    ),
                    initialSettings: InAppWebViewSettings(
                      useShouldOverrideUrlLoading: true,
                      cacheEnabled: true,
                      javaScriptEnabled: true,
                      clearCache: false,
                      useOnDownloadStart: true,
                      transparentBackground: true,
                    ),
                    onWebViewCreated: (controller) {
                      _controller = controller;
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      var url = navigationAction.request.url.toString();
                      if (_shouldLaunchInExternalApp(url)) {
                        _launchURL(url);
                        return NavigationActionPolicy.CANCEL;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _isLoading = true;
                      });
                    },
                    onLoadStop: (controller, url) async {
                      setState(() {
                        _isLoading = false;
                      });
                    },
                  ),
                  _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF119E3E),
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              )
            : _noInternetPage(),
      ),
    );
  }

  Widget _noInternetPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 100, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'No Internet Connection',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 10),
          Text(
            'Please check your connection and try again.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              _checkInternetConnection(); // Check connectivity again
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}