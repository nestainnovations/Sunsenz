import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const SunsenzServeApp());
}

class SunsenzServeApp extends StatelessWidget {
  const SunsenzServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunsenz',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final newVersion = NewVersionPlus(
      androidId: "in.sunsenz.service",
    ); // Replace with your app's package name
    final status = await newVersion.getVersionStatus();
    if (!mounted) return;

    if (status != null && status.canUpdate) {
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dialogTitle: 'Update Available',
        dialogText:
            'A new version of the app is available! Please update to continue.',
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
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;
  bool _isWebViewReady = false;
  bool _webViewCanGoBack = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _initializeWebView();
    _checkInternetConnection();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        if (mounted) {
          setState(() {
            _hasInternet = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasInternet = true;
          });
        }
        if (_isWebViewReady) {
          _controller.reload();
        }
      }
    });
  }

  Future<void> _initializeWebView() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          if (_shouldLaunchInExternalApp(request.url)) {
            _launchURL(request.url);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (_) {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        onPageFinished: (_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _updateWebViewBackAvailability();
          }
        },
      ),
    );
    await _controller.loadRequest(
      Uri.parse('https://service.sunsenz.com/public/en/member/login'),
      headers: const {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );
    if (mounted) {
      setState(() {
        _isWebViewReady = true;
      });
    }
  }

  Future<void> _updateWebViewBackAvailability() async {
    final canGoBack = await _controller.canGoBack();
    if (!mounted) return;
    setState(() {
      _webViewCanGoBack = canGoBack;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!mounted) return;
    if (connectivityResult.contains(ConnectivityResult.none)) {
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
    final externalSchemes = [
      'tel:',
      'mailto:',
      'https://maps.app.goo.gl/',
      'http://maps.app.goo.gl/',
    ];
    return externalSchemes.any((scheme) => url.startsWith(scheme));
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  void _onPopInvoked(bool didPop) {
    if (!didPop && _webViewCanGoBack) {
      _controller.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_webViewCanGoBack,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
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
            ? _isWebViewReady
                  ? Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF119E3E),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF119E3E),
                      ),
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
          const Icon(Icons.wifi_off, size: 100, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please check your connection and try again.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              _checkInternetConnection(); // Check connectivity again
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
