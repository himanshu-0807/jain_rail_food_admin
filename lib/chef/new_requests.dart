import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:railway_food_delivery_admin/notification_services.dart'; // Import the intl package

class NewChefRequests extends StatefulWidget {
  const NewChefRequests({super.key});

  @override
  State<NewChefRequests> createState() => _NewChefRequestsState();
}

class _NewChefRequestsState extends State<NewChefRequests> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Requests'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status',
                isEqualTo:
                    'Accepted') // Change this to 'New' or any other status for new requests
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No new orders.'));
          }

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderData = orders[index].data() as Map<String, dynamic>;
              String orderId = orders[index].id; // Get the document ID
              return _buildOrderCard(orderData, orderId);
            },
          );
        },
      ),
    );
  }

  // Method to build the UI for each order
  Widget _buildOrderCard(Map<String, dynamic> orderData, String orderId) {
    List<dynamic> cartItems = orderData['selectedItems'] ?? [];

    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', orderData['name']),
            _buildInfoRow('Phone:', orderData['phone']),
            _buildInfoRow('Train Number:', orderData['trainNumber']),
            _buildInfoRow('Compartment:', orderData['compartment']),
            _buildInfoRow('Seat Number:', orderData['seatNumber']),
            SizedBox(height: 10.h),
            Text('Cart Items:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ...cartItems.map((item) {
              // Handle cart item as a Map
              String foodName = item['name'] ?? 'Unknown';
              int quantity = item['quantity'] ?? 1;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(foodName, style: TextStyle(fontSize: 14.sp)),
                trailing: Text('Quantity: $quantity',
                    style: TextStyle(fontSize: 12.sp)),
              );
            }),
            SizedBox(height: 10.h),
            Text(
              "Status : ${orderData['status']}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Requested on: ${_formatTimestamp(orderData['timestamp'])}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(orderId, 'Dispatched'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, // Green color for "Dispatched"
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text('Dispatched'),
                ),
                ElevatedButton(
                  onPressed: () => _updateOrderStatus(orderId, 'Rejected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Red color for "Rejected"
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the order detail rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  // Method to format the timestamp in 12-hour format
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown';
    }
    DateTime date = timestamp.toDate();
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }

  // Method to update the order status in Firestore
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      // Fetch the request document to get the user's device token
      DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .doc(orderId)
          .get();

      if (requestSnapshot.exists) {
        // Extract the user's device token
        String userDeviceToken =
            (requestSnapshot.data() as Map<String, dynamic>)['deviceToken'];

        // Fetch today's shifts to get the chef's device token
        DocumentSnapshot shiftsSnapshot = await FirebaseFirestore.instance
            .collection('todays_shifts')
            .doc('shifts')
            .get();

        String active_logistics = (shiftsSnapshot.data()
            as Map<String, dynamic>)['active_logistics']['deviceToken'];

        // Update order status
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(orderId)
            .update({'status': status});

        // Send notifications
        NotificationServices.sendNotificationToSelectedDriver(active_logistics,
            context, 'Order Status Updated', 'The order has been dispatched.');
        NotificationServices.sendNotificationToSelectedDriver(userDeviceToken,
            context, 'Order Status Updated', 'The order has been dispatched.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $status'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order not found'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status'),
        ),
      );
    }
  }
}
