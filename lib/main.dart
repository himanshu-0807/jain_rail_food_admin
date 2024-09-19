import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:railway_food_delivery_admin/admin/admin_home.dart';
import 'package:railway_food_delivery_admin/chef/chef_home.dart';
import 'package:railway_food_delivery_admin/facilitator/facilitator_home.dart';
import 'package:railway_food_delivery_admin/firebase_options.dart';
import 'package:railway_food_delivery_admin/logistic/logistics_home.dart';

import 'auth_features/login_page.dart';
import 'chef/new_requests.dart';
import 'facilitator/food_request.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // Handle background message UI updates or actions here
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(
          360, 690), // Design size of the screen (update based on your design)
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LoginPage(),
        );
      },
    );
  }
}
