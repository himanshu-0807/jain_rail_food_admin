import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:railway_food_delivery_admin/logistic/new_orders.dart';
import 'package:railway_food_delivery_admin/main.dart';
import 'package:railway_food_delivery_admin/past_requests.dart';

class LogisticsHome extends StatefulWidget {
  const LogisticsHome({super.key});

  @override
  State<LogisticsHome> createState() => _LogisticsHomeState();
}

class _LogisticsHomeState extends State<LogisticsHome> {
  @override
  void initState() {
    super.initState();

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
        context,
        MaterialPageRoute(builder: (context) => NewLogisticsRequests()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Logistics Dashboard', style: TextStyle(fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.delivery_dining,
                  color: Colors.blue,
                  size: 40,
                ),
                title: const Text(
                  'New Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('View and manage new orders'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  navi(context, NewLogisticsRequests());
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
                leading: const Icon(
                  Icons.history,
                  color: Colors.orange,
                  size: 40,
                ),
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
