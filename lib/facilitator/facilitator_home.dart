import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:railway_food_delivery_admin/facilitator/food_request.dart';
import 'package:railway_food_delivery_admin/facilitator/manage_food_menu.dart';
import 'package:railway_food_delivery_admin/main.dart';
import 'package:railway_food_delivery_admin/past_requests.dart';

class FacilitatorHome extends StatefulWidget {
  const FacilitatorHome({super.key});

  @override
  State<FacilitatorHome> createState() => _FacilitatorHomeState();
}

class _FacilitatorHomeState extends State<FacilitatorHome> {
  String? userName;
  String? userRole;

  @override
  void initState() {
    super.initState();
    fetchUser();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground');

      if (message.data.isNotEmpty) {
        print('Data: ${message.data}');

        // Access title and body from data
        String title = message.data['title'] ?? 'New Notification';
        String body = message.data['body'] ?? 'No message content';

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                  child: const Text('OK'),
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
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => FoodRequest()));
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
        title: const Text('Facilitator Dashboard'),
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
            const SizedBox(height: 20), // Add some space
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading:
                    const Icon(Icons.fastfood, color: Colors.green, size: 40),
                title: const Text(
                  'Manage Food Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Edit and manage available food items'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navi(context, ManageFoodMenu());
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
                leading: const Icon(Icons.assignment,
                    color: Colors.orange, size: 40),
                title: const Text(
                  'New Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View new food requests'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navi(context, FoodRequest());
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
                    const Icon(Icons.history, color: Colors.blue, size: 40),
                title: const Text(
                  'Past Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Check past food requests'),
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
