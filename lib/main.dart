import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'auth_features/login_page.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Local Notifications
  var initializationSettingsAndroid =
      AndroidInitializationSettings('mipmap/launcher_icon');
  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

void navi(context, Widget NextPage) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => NextPage,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from right to left
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    ),
  );
}

void naviWithReplace(context, Widget NextPage) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => NextPage,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from right to left
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android notification details
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    playSound: true,
    enableVibration: true,
    importance: Importance.max,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notification'),
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  // Always show notification using data payload
  String title = message.data['title'] ?? 'New Notification';
  String body = message.data['body'] ?? 'No message content';

  // Show notification
  await flutterLocalNotificationsPlugin.show(
    message.messageId.hashCode, // Use message ID to avoid duplicates
    title,
    body,
    platformChannelSpecifics,
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(
            progressIndicatorTheme:
                ProgressIndicatorThemeData(color: Colors.orange),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.orange; // Orange when checked
                }
                return Colors.white; // White when unchecked
              }),
              checkColor:
                  WidgetStateProperty.all(Colors.white), // White tick mark
            ),
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: Colors.orange, // Set the cursor color to orange
              selectionColor: Colors.orange
                  .withOpacity(0.3), // Optional: Highlight selection color
              selectionHandleColor:
                  Colors.orange, // Optional: Handle color when selecting text
            ),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.orange, // Set focused border color to orange
                  width: 2.0, // Optional: Set the border thickness
                ),
                borderRadius:
                    BorderRadius.circular(8.0), // Optional: Rounded border
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors
                      .grey, // Optional: Set the border color when not focused
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              labelStyle:
                  TextStyle(color: Colors.orange), // Label color when focused
            ),
            appBarTheme: AppBarTheme(
              iconTheme: IconThemeData(color: Colors.white),
              backgroundColor: Colors.orange,
              titleTextStyle: TextStyle(fontSize: 20.sp, color: Colors.white),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            tabBarTheme: TabBarTheme(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.white),
          ),
          debugShowCheckedModeBanner: false,
          home: LoginPage(),
        );
      },
    );
  }
}
