import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:test_local_notification/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('handling background message ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseMessaging.instance.getInitialMessage();
  // receive meassage in background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? mtoken = '';
  var flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    requestPermission();
    getToken();
		// 初始化 flutterLocalNotificationsPlugin
    initLocalNotification();
  }

  // get user notification permission
  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('user granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('user granted provisional permission');
    } else {
      print('user declined permission');
    }
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mtoken = token;
        print('my token is $mtoken');
      });
      // saveToken(token!);
    });
  }

  void initLocalNotification() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
		// 如果有設定icon，@mipmap / ic_launcher 要調整
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: android, iOS: ios);
    flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // receive meassage in the app
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('......message: ${message.notification?.title}--${message.notification?.body}');

      BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        message.notification!.body.toString(),
        htmlFormatBigText: true,
        contentTitle: message.notification!.title.toString(),
        htmlFormatContentTitle: true,
      );

      AndroidNotificationDetails androidPlatformChannelSpecitics = AndroidNotificationDetails(
        'dbfood',
        'dbfood',
        importance: Importance.high,
        styleInformation: bigTextStyleInformation,
        priority: Priority.high,
        playSound: true,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecitics,
        iOS: const DarwinNotificationDetails(),
      );
      await flutterLocalNotificationsPlugin.show(
        0, 
        message.notification?.title, 
        message.notification?.body, 
        platformChannelSpecifics,
        payload: message.data['body'],
      );
    });
  }

	// 這邊設定點擊推播會出現的 dialog 內容
  void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("Notfication"),
        content: Text("This is notification"),
      )
    );
  }

	// local 發送訊息
  showNotification() async {
    var _android = AndroidNotificationDetails(
      'channel id', 
			'channel NAME', 
      channelDescription: 'CHANNEL DESCRIPTION',
      priority: Priority.high,
      importance: Importance.max,
    );
    var _ios = DarwinNotificationDetails();
    var platform = NotificationDetails(android: _android, iOS: _ios);
    await flutterLocalNotificationsPlugin.show(
      0, 
			'New Video is out',             // title
			'Flutter Local Notification',   // content
			platform,
      payload: 'Nitish Kumar Singh is part time Youtuber');
  }

  // firebase 發送訊息
  sendPushMessage(String body, String title) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/flutter-notification-26237/messages:send'),
        // Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ya29.a0AX9GBdXjCXK1nZhS7awILAA_U-zmRjUKflwxjernK2fN1TlkD1AKWzoZq0CJxbs9p94gjel8UbxyzR19OCfbRRM_s1CJKwfNAMemdja4LqpzzCcrDLBQQ83G_aFGZGOCm5pGPwnBAnQLs9xV8BXzaPYfvHGhJt-HaCgYKATISAQASFQHUCsbCePu0Yz_wC29xyTbNspVbAA0167',
          // 'Authorization': 'key=AAAAw1wbu_o:APA91bG8Z6qLfNNdPt7572BrpCoAJAEr-eto7zNVP2BawEfewcvhY_ilJISAC7u6sbKhDXQt5rCLc4nwxmjEYJsEuWeAb8kujU0PyWFxDz2w9aT2TjLLVW7Cacx1wlF4Mlrb7JNyWdru',
        },
        body: jsonEncode(
          {
            "message": {
              "token": mtoken,
              // "topic": "news",
              "notification": {
                "title": title,
                "body": body,
              },
              "aps": {
                "alert" : {
                  "body" : "great match!",
                  "title" : "Portugal vs. Denmark",
                },
                "badge" : 1
              }
              // "data": {
              //   "android_channel_id": "dbfood"
              // },
              // "android": {
              //   "priority": "high"
              // }
            }
          },
        )
      );
    } catch(e) {
      // if (kDebugMode) {
        print('error push notification');
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Local Notification'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            const String titleText = 'tkb welcome you';
            const String bodyText = 'api context';
            sendPushMessage(titleText, bodyText);
          },
          child: new Text(
            'click to send message',
          ),
        )
      ),
    );
  }
}