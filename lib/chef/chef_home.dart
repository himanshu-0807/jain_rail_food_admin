import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:railway_food_delivery_admin/chef/new_requests.dart';

class ChefHome extends StatefulWidget {
  const ChefHome({super.key});

  @override
  State<ChefHome> createState() => _ChefHomeState();
}

class _ChefHomeState extends State<ChefHome> {
  void initState() {
    // TODO: implement initState
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Show an alert dialog when a notification is received in the foreground
      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title:
              Text(message.notification!.title ?? 'New Notification'),
              content:
              Text(message.notification!.body ?? 'No message content'),
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
                    MaterialPageRoute(builder: (context) => NewChefRequests()));
              },
              child: Text('New orders'))
        ],
      ),
    );
  }
}
