import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'service.dart';

class FCMService {
  FCMService({required this.onMessage});

  final void Function(RemoteMessage message, String handler) onMessage;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  bool _started = false;
  bool _disposed = false;

  AuthorizationStatus? permissionStatus;
  String? token;

  Future<void> initialize() async {
    if (_started || _disposed) return;
    _started = true;

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) {
        if (!_disposed) {
          onMessage(message, 'onMessage');
        }
      },
    );

    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        if (!_disposed) {
          onMessage(message, 'onMessageOpenedApp');
        }
      },
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (_disposed) return;

    if (initialMessage != null) {
      onMessage(initialMessage, 'getInitialMessage');
    }

    final settings = await _messaging.requestPermission();

    if (_disposed) return;

    permissionStatus = settings.authorizationStatus;
    debugPrint('Notification : ${settings.authorizationStatus.name}');

    token = await _messaging.getToken();
    if (_disposed) return;

    debugPrint('FCM token: $token');
  }

  void dispose() {
    _disposed = true;
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
  }
}