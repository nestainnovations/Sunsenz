import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
          fit: BoxFit.contain, // Ensure the image scales properly
          width: double.infinity, // Make the image fit the width
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://service.sunsenz.com/public/en/member/login'));
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
                fontWeight: FontWeight.bold, // Make the text bold
                fontSize: 24, // Increase the font size
                color: Colors.white, // Change the text color to white
              ),
            ),
          ),
          backgroundColor: const Color(0xFFD91818), // Change the AppBar background color to #D91818
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
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
