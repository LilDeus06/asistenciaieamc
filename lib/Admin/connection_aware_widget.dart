import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionAwareWidget extends StatefulWidget {
  final Widget child;
  final int inactivitySeconds;

  const ConnectionAwareWidget({
    Key? key, 
    required this.child, 
    this.inactivitySeconds = 20
  }) : super(key: key);

  @override
  _ConnectionAwareWidgetState createState() => _ConnectionAwareWidgetState();
}

class _ConnectionAwareWidgetState extends State<ConnectionAwareWidget> with WidgetsBindingObserver {
  bool _isConnected = true;
  Timer? _inactivityTimer;
  int _secondsInactive = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startInactivityTimer();
    _updateConnectionStatus(true);
  }

  @override
  void dispose() {
    _disposed = true;
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _updateConnectionStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _updateConnectionStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      _updateConnectionStatus(true);
      _resetInactivityTimer();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      _secondsInactive++;
      if (_secondsInactive >= widget.inactivitySeconds) {
        _updateConnectionStatus(false);
      }
    });
  }

  void _resetInactivityTimer() {
    if (_disposed) return;
    _secondsInactive = 0;
    if (!_isConnected) {
      _updateConnectionStatus(true);
    }
  }

  Future<void> _updateConnectionStatus(bool connected) async {
    if (_disposed) return;
    if (_isConnected != connected) {
      setState(() {
        _isConnected = connected;
      });
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('USUARIOS')
              .doc(user.uid)
              .update({'isConnected': connected});
          print('Connection status updated: $connected');
        } catch (e) {
          print('Error updating connection status: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(),
      onScaleStart: (_) => _onUserInteraction(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  void _onUserInteraction() {
    if (_disposed) return;
    print('User interaction detected');
    _resetInactivityTimer();
  }
}