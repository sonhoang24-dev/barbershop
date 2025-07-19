import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late StreamSubscription _subscription;
  bool _isOffline = false;
  bool _showReconnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();

    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    bool hasConnection = await InternetConnectionChecker().hasConnection;
    if (mounted) {
      setState(() {
        if (_isOffline && hasConnection) {
          _showReconnected = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showReconnected = false;
              });
            }
          });
        }
        _isOffline = !hasConnection;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        if (_isOffline)
          Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 100, color: Colors.red),
                  const SizedBox(height: 30),
                  const Text(
                    "Không có kết nối mạng!",
                    style: TextStyle(fontSize: 20, color: Colors.black, decoration: TextDecoration.none),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _checkConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

                    ),
                  ),
                ],
              ),
            ),
          ),

        // Thông báo có lại kết nối
        if (_showReconnected)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Colors.green[600],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Đã kết nối Internet',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
