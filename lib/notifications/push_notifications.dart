// import 'dart:io';
// import 'dart:math';

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationServices {
//   FirebaseMessaging firebaseMesaging = FirebaseMessaging.instance;

//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   void firebaseInit() {
//     FirebaseMessaging.onMessage.listen((message) {
//       if (kDebugMode) {
//         print(message.notification!.title.toString());
//         print(message.notification!.body.toString());
//         print(message.data.toString());
//         print(message.data['type']);
//         print(message.data['id']);
//       }
//       if (Platform.isIOS) {
//         forgroundMessage();
//       }

//       if (Platform.isAndroid) {
//         initLocalNotification(message);
//         showNotification(message);
//       }
//     });
//   }

//   void initLocalNotification(RemoteMessage message) async {
//     var androidInitializationSettings =
//         AndroidInitializationSettings('@mipmap/new_logo');
//     var iosInitializationSettings = DarwinInitializationSettings();

//     var initializationSettigs = InitializationSettings(
//         android: androidInitializationSettings, iOS: iosInitializationSettings);

//     await _flutterLocalNotificationsPlugin.initialize(initializationSettigs,
//         onDidReceiveNotificationResponse: (payload) {
//       // handle interaction when app is active for android
//       // handleMessage(context, message);
//     });
//   }

//   void requestNotificationPermission() async {
//     NotificationSettings settings = await firebaseMesaging.requestPermission(
//       alert: true,
//       announcement: true,
//       badge: true,
//       carPlay: true,
//       criticalAlert: true,
//       sound: true,
//       provisional: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print("User granted permission...");
//     } else if (settings.authorizationStatus ==
//         AuthorizationStatus.provisional) {
//       print("User granted provisional permission...");
//     } else {
//       print("User denied permission...");
//     }
//   }

//   Future<void> showNotification(RemoteMessage message) async {
//     AndroidNotificationChannel channel = AndroidNotificationChannel(
//       Random.secure().nextInt(100000).toString(),
//       "High Importance Notifications",
//       importance: Importance.max,
//       showBadge: true,
//       playSound: true,
//     );

//     AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails(
//       channel.id.toString(),
//       channel.name.toString(),
//       channelDescription: "Your Channel Description",
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       sound: channel.sound,
//       ticker: 'ticker',
//       // icon: "ic_launcher",
//     );

//     const DarwinNotificationDetails darwinNotificationDetails =
//         DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     NotificationDetails notificationDetails = NotificationDetails(
//         android: androidNotificationDetails, iOS: darwinNotificationDetails);

//     Future.delayed(Duration.zero, () {
//       _flutterLocalNotificationsPlugin.show(
//         0,
//         message.notification!.title,
//         message.notification!.body,
//         notificationDetails,
//       );
//     });
//   }

//   Future<String> getDeviceToken() async {
//     String? token = await firebaseMesaging.getToken();
//     return token!;
//   }

//   void isTokenRefresh() async {
//     firebaseMesaging.onTokenRefresh.listen((event) {
//       event.toString();
//       if (kDebugMode) {
//         print('refresh');
//       }
//     });
//   }

//   // Future<void> setupInteractMessage(BuildContext context) async {
//   //   RemoteMessage? initialMessage =
//   //       await FirebaseMessaging.instance.getInitialMessage();

//   //   if (initialMessage != null) {
//   //     handleMessage(context, initialMessage);
//   //   }

//   //   //when app ins background
//   //   FirebaseMessaging.onMessageOpenedApp.listen((event) {
//   //     handleMessage(context, event);
//   //   });
//   // }

//   // void handleMessage(BuildContext context, RemoteMessage message) {
//   //   if (message.data['type'] == 'msg') {
//   //     Navigator.push(
//   //       context,
//   //       MaterialPageRoute(
//   //         builder: (context) => MessageScreen(
//   //           id: message.data['id'],
//   //         ),
//   //       ),
//   //     );
//   //   }
//   // }

//   Future forgroundMessage() async {
//     await FirebaseMessaging.instance
//         .setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//   }
// }
