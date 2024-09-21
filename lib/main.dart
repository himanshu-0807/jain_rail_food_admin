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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Design size of the screen
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          theme: ThemeData(
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all(Colors.black), // Set to black
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            appBarTheme: AppBarTheme(
              titleTextStyle: TextStyle(
                fontSize: 20.sp,
                color: Colors.white,
              ),
              foregroundColor: Colors.white,
              backgroundColor: Colors.orange,
            ),
            checkboxTheme: CheckboxThemeData(
              checkColor: WidgetStateProperty.all(
                  Colors.white), // Color of the check mark
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.orange; // Color of the checkbox when checked
                }
                return Colors.white; // Color of the checkbox when unchecked
              }),
            ),
            tabBarTheme: TabBarTheme(
              indicatorColor: Colors.white,
              labelColor: Colors.white, // Color of the selected tab text
              unselectedLabelColor:
                  Colors.white54, // Color of the unselected tab text
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: LoginPage(),
        );
      },
    );
  }
}
