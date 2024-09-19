import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:railway_food_delivery_admin/facilitator/food_request.dart';
import 'package:railway_food_delivery_admin/facilitator/manage_food_menu.dart';
import 'package:railway_food_delivery_admin/facilitator/past_requests.dart';

class FacilitatorHome extends StatefulWidget {
  const FacilitatorHome({super.key});

  @override
  State<FacilitatorHome> createState() => _FacilitatorHomeState();
}

class _FacilitatorHomeState extends State<FacilitatorHome> {
  void initState() {
    // TODO: implement initState
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show an alert dialog when a notification is received in the foreground
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
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => FoodRequest()));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ManageFoodMenu()));
              },
              child: Text('Manage Food Menu')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => FoodRequest()));
              },
              child: Text('Requests')),
          ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PastRequests()));
              },
              child: Text('Past Requests')),
        ],
      ),
    );
  }
}
