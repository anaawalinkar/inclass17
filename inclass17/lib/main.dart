import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// Background message handler (must be top-level function)
Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(const MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  const MessagingTutorial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

// Notification type configuration
class NotificationConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final String label;

  NotificationConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.label,
  });
}

class NotificationTypeHandler {
  static NotificationConfig getConfig(String? type, String? category) {
    // Handle different notification types
    switch (type?.toLowerCase()) {
      case 'important':
        return NotificationConfig(
          backgroundColor: Colors.red.shade50,
          textColor: Colors.red.shade900,
          icon: Icons.warning,
          label: 'Important',
        );
      case 'wisdom':
        return NotificationConfig(
          backgroundColor: Colors.purple.shade50,
          textColor: Colors.purple.shade900,
          icon: Icons.lightbulb,
          label: 'Wisdom',
        );
      case 'motivational':
      case 'inspiration':
        return NotificationConfig(
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade900,
          icon: Icons.emoji_events, // Trophy icon
          label: 'Motivational',
        );
      case 'regular':
      default:
        return NotificationConfig(
          backgroundColor: Colors.grey.shade100,
          textColor: Colors.grey.shade900,
          icon: Icons.message,
          label: 'Regular',
        );
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  String? notificationText;
  String? fcmToken;
  List<Map<String, String>> notificationHistory = [];

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    
    // Request notification permissions
    messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    messaging.subscribeToTopic("messaging");
    
    // Get and display FCM token
    messaging.getToken().then((value) {
      print('FCM Token: $value');
      setState(() {
        fcmToken = value;
      });
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message received");
      print(event.notification?.body);
      print(event.data.values);
      
      // Extract notification type and category from data
      String? notificationType = event.data['type'];
      String? category = event.data['category'];
      
      // Get configuration based on type
      NotificationConfig config = NotificationTypeHandler.getConfig(
        notificationType,
        category,
      );

      // Add to history
      setState(() {
        notificationHistory.insert(0, {
          'title': event.notification?.title ?? 'Notification',
          'body': event.notification?.body ?? '',
          'type': notificationType ?? 'regular',
          'category': category ?? '',
        });
      });

      // Show custom dialog based on notification type
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: config.backgroundColor,
            title: Row(
              children: [
                Icon(
                  config.icon,
                  color: config.textColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.notification?.title ?? 'Notification',
                    style: TextStyle(
                      color: config.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.notification?.body ?? '',
                  style: TextStyle(
                    color: config.textColor,
                    fontSize: 16,
                  ),
                ),
                if (category != null && category.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: config.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Category: $category',
                      style: TextStyle(
                        color: config.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  "Ok",
                  style: TextStyle(color: config.textColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });

    // Handle notification when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
      print(message.notification?.body);
      
      // Extract notification type and category
      String? notificationType = message.data['type'];
      String? category = message.data['category'];
      
      NotificationConfig config = NotificationTypeHandler.getConfig(
        notificationType,
        category,
      );

      // Show dialog when app is opened from notification
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: config.backgroundColor,
            title: Row(
              children: [
                Icon(
                  config.icon,
                  color: config.textColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.notification?.title ?? 'Notification',
                    style: TextStyle(
                      color: config.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message.notification?.body ?? '',
              style: TextStyle(
                color: config.textColor,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "Ok",
                  style: TextStyle(color: config.textColor),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });

    // Check if app was opened from a notification (when app was terminated)
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from notification: ${message.notification?.body}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      fcmToken ?? 'Loading token...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Copy this token and use it in Firebase Console to send test notifications',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notification History Section
            const Text(
              'Notification History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (notificationHistory.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No notifications received yet.\nSend a test notification from Firebase Console.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              ...notificationHistory.map((notification) {
                NotificationConfig config = NotificationTypeHandler.getConfig(
                  notification['type'],
                  notification['category'],
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: config.backgroundColor,
                  child: ListTile(
                    leading: Icon(
                      config.icon,
                      color: config.textColor,
                    ),
                    title: Text(
                      notification['title'] ?? '',
                      style: TextStyle(
                        color: config.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification['body'] ?? '',
                          style: TextStyle(
                            color: config.textColor,
                          ),
                        ),
                        if (notification['category'] != null &&
                            notification['category']!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: config.textColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification['category']!,
                              style: TextStyle(
                                color: config.textColor,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
