import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agora_project/voice_call_screen.dart';
import 'package:agora_project/services/api_service.dart';

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // If you need to wake up the app and join immediately,
  // you might need more complex logic or a full screen intent (Android).
}

class CallManager {
  static final CallManager _instance = CallManager._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Need to be set from main.dart
  GlobalKey<NavigatorState>? navigatorKey;

  factory CallManager() {
    return _instance;
  }

  CallManager._internal();

  Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM Token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    if (token != null) {
      await ApiService().registerFcmToken(token);
    }

    // Handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      _handleMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleMessage(message);
    });

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'call_initiation') {
      final channelName = message.data['channel_name'];
      final agoraToken = message.data['agora_token'];
      final callerId = message.data['caller_id'];

      // Navigate to Call Screen
      if (navigatorKey?.currentState != null) {
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (context) => VoiceCallScreen(
              appId:
                  "YOUR_AGORA_APP_ID", // TODO: Fetch from config/server or hardcode
              token: agoraToken,
              channelName: channelName,
            ),
          ),
        );
      }
    }
  }
}
