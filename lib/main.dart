import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(milliseconds: 3000), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/Logo-RBG.png',
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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  void _onWebViewCreated(WebViewController controller) {
    _controller = controller;
    _controller.loadUrl('https://test.sunsenz.com/public/en/member/login');
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
              'Sunsenz Service',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: const Color(0xFFD91818),
        ),
        body: Stack(
          children: [
            WebView(
              initialUrl: 'https://test.sunsenz.com/public/en/member/login',
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: _onWebViewCreated,
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                });
              },
              navigationDelegate: (NavigationRequest request) {
                if (_shouldLaunchInExternalApp(request.url)) {
                  _launchURL(request.url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF119E3E)),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
