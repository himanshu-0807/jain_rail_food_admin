import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:railway_food_delivery_admin/chef/new_requests.dart';
import 'package:railway_food_delivery_admin/main.dart';
import 'package:railway_food_delivery_admin/past_requests.dart';

class ChefHome extends StatefulWidget {
  const ChefHome({super.key});

  @override
  State<ChefHome> createState() => _ChefHomeState();
}

class _ChefHomeState extends State<ChefHome> {
  String? userName;
  String? userRole;

  void initState() {
    super.initState();
    fetchUser();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(message.notification!.title ?? 'New Notification'),
              content: Text(message.notification!.body ?? 'No message content'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification clicked!');
      // Handle app navigation or other actions when the user clicks on the notification
    });
  }

  Future<void> fetchUser() async {
    DocumentSnapshot data = await FirebaseFirestore.instance
        .collection('admin_users')
        .doc(FirebaseAuth.instance.currentUser!.email)
        .get();

    if (data.exists) {
      var userData = data.data() as Map<String, dynamic>;
      setState(() {
        userName = userData['name']; // Adjust based on your Firestore schema
        userRole = userData['role']; // Adjust based on your Firestore schema
      });
      print('User data: $userData');
    } else {
      print('User not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chef Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome ${userName ?? 'User'},', // Display user name or fallback
              style: TextStyle(fontSize: 20.sp),
            ),
            SizedBox(
              height: 10.h,
            ),
            Text(
              'Role: ${userRole ?? 'Not Assigned'}', // Display user role or fallback
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.restaurant_menu,
                    color: Colors.green, size: 40),
                title: const Text(
                  'New Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View and handle incoming requests'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navi(context, NewChefRequests());
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading:
                    const Icon(Icons.history, color: Colors.orange, size: 40),
                title: const Text(
                  'Past Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View and check past orders'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navi(context, PastRequests());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
