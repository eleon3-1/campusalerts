import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('onBackgroundMessage: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FCMService _service;

  static const _images = {
    'default': 'assets/images/default.png',
    'promo': 'assets/images/promo.png',
  };

  String _title = 'Campus alerts';
  String _image = 'assets/images/default.png';
  String _handler = 'None';
  String _messageId = 'None';
  String _permission = 'Checking';
  String _status = 'Waiting for a message';
  int _received = 0;

  @override
  void initState() {
    super.initState();
    _service = FCMService(onMessage: _handleMessage);
    _startMessaging();
  }

  Future<void> _startMessaging() async {
    try {
      await _service.initialize();
      if (!mounted) return;

      setState(() {
        _permission = _service.permissionStatus?.name ?? 'Unknown';
      });
    } catch (error) {
      debugPrint('FCM setup error: $error');
      if (!mounted) return;

      setState(() {
        _permission = _service.permissionStatus?.name ?? 'Unknown';
        _status = 'Messaging setup failed. Check the terminal.';
      });
    }
  }

  void _handleMessage(RemoteMessage message, String handler) {
    if (!mounted) return;

    setState(() {
      _handler = handler;
      _messageId = message.messageId ?? 'Unavailable';
      _received++;

      final action = message.data['action'];
      final asset = message.data['asset'];

      if (action != 'update_ui') {
        _status = 'Ignored: action must be update_ui.';
        return;
      }

      final nextImage = _images[asset];

      if (nextImage == null) {
        _status = asset == null
            ? 'Ignored: missing asset.'
            : 'Ignored: unsupported asset "$asset".';
        return;
      }

      _image = nextImage;
      _title = message.notification?.title ?? 'Campus alerts';
      _status = 'UI updated.';
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Alerts',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Campus alerts'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _title,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Image.asset(
              _image,
              height: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text('Permission: $_permission'),
            Text('Last handler: $_handler'),
            Text('Receipts this launch: $_received'),
            Text('Message ID: $_messageId'),
            const SizedBox(height: 12),
            Text('Status: $_status'),
          ],
        ),
      ),
    );
  }
}