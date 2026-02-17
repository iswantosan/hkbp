import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize Flutter Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Top-level function untuk show notification (dipanggil dari background handler)
@pragma('vm:entry-point')
Future<void> showBackgroundNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'hkbp_notifications',
    'HKBP Notifications',
    channelDescription: 'Notifications for HKBP Pondok Kopi',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    platformChannelSpecifics,
  );
}

// Top-level function untuk background message handler
// Harus top-level function, tidak boleh di dalam class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
  
  // Show notification untuk background message
  if (message.notification != null) {
    await showBackgroundNotification(
      message.notification!.title ?? 'HKBP Pondok Kopi',
      message.notification!.body ?? '',
    );
  }
}

/// Initialize Local Notifications
Future<void> initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      debugPrint('Notification tapped: ${response.payload}');
    },
  );

  // Create notification channel untuk Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'hkbp_notifications', // id
    'HKBP Notifications', // name
    description: 'Notifications for HKBP Pondok Kopi',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// Setup Firebase Cloud Messaging
Future<void> setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  // Initialize local notifications
  await initializeLocalNotifications();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request permission untuk notification
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  debugPrint('User granted permission: ${settings.authorizationStatus}');

  // Setup foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
      
      // Tampilkan local notification saat app aktif (foreground)
      _showLocalNotification(
        message.notification!.title ?? 'HKBP Pondok Kopi',
        message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  });

  // Setup message opened handler (ketika user tap notification)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification?.title}');
    
    // Handle navigation atau action berdasarkan data message
    _handleMessageOpened(message);
  });

  // Check if app was opened from terminated state
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('App opened from terminated state');
    debugPrint('Initial message data: ${initialMessage.data}');
    _handleMessageOpened(initialMessage);
  }

  // Get FCM token
  String? token = await messaging.getToken();
  debugPrint('FCM Token: $token');
  
  // Listen untuk token refresh
  messaging.onTokenRefresh.listen((newToken) {
    debugPrint('FCM Token refreshed: $newToken');
    // Kirim token baru ke server jika diperlukan
  });
}

/// Show local notification
Future<void> _showLocalNotification(
  String title,
  String body, {
  String? payload,
}) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'hkbp_notifications', // channel id
    'HKBP Notifications', // channel name
    channelDescription: 'Notifications for HKBP Pondok Kopi',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    platformChannelSpecifics,
    payload: payload,
  );
}

/// Handle message opened (dari notification tap)
void _handleMessageOpened(RemoteMessage message) {
  // Handle navigation atau action berdasarkan data
  // Contoh: jika ada 'route' di data, navigate ke route tersebut
  if (message.data.containsKey('route')) {
    String route = message.data['route'];
    debugPrint('Navigate to route: $route');
    // Navigator.pushNamed(context, route);
  }
  
  // Contoh: jika ada 'type' di data, handle berdasarkan type
  if (message.data.containsKey('type')) {
    String type = message.data['type'];
    debugPrint('Message type: $type');
    
    switch (type) {
      case 'news':
        // Navigate to news detail
        break;
      case 'event':
        // Navigate to event detail
        break;
      default:
        break;
    }
  }
}

