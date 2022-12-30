import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:test_local_notification/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

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

	// 這邊設定發送推播的內容
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Local Notification'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: showNotification,
          child: new Text(
            'click to send message',
          ),
        )
      ),
    );
  }
}