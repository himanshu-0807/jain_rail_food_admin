import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:railway_food_delivery_admin/notification_services.dart'; // Import the intl package

class NewLogisticsRequests extends StatefulWidget {
  const NewLogisticsRequests({super.key});

  @override
  State<NewLogisticsRequests> createState() => _NewLogisticsRequestsState();
}

class _NewLogisticsRequestsState extends State<NewLogisticsRequests> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', whereIn: ['Accepted', 'Dispatched']).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No orders available.'));
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
            Text('Requested Food:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            ...cartItems.map((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['name'] ?? 'Unknown',
                    style: TextStyle(fontSize: 14.sp)),
                trailing: Text('Quantity: ${item['quantity'] ?? 1}',
                    style: TextStyle(fontSize: 12.sp)),
              );
            }).toList(),
            SizedBox(height: 10.h),
            Text(
              'Requested on: ${_formatTimestamp(orderData['timestamp'])}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 10.h),
            Text('Status: ${orderData['status']}'),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, orderData),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Green color for "Delivered"
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text('Delivered'),
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
  Future<void> _updateOrderStatus(
      String orderId, Map<String, dynamic> orderData) async {
    try {
      print('Starting order status update process for order ID: $orderId');
      print('Original Order data: $orderData');

      // Update the status in the orderData map
      orderData['status'] = 'Delivered';

      // Fetch the request document to get the user's device token
      DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .doc(orderId)
          .get();

      if (requestSnapshot.exists) {
        // Extract the user's device token
        String userDeviceToken =
            (requestSnapshot.data() as Map<String, dynamic>)['deviceToken'];

        // First, update the status to 'Delivered' in the 'requests' collection
        print('Updating status to "Delivered" in "requests" collection...');
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(orderId)
            .update({'status': 'Delivered'});
        print('Status updated successfully in requests.');

        // Move the updated order data to 'pastRequests' collection
        print(
            'Moving order data with updated status to "pastRequests" collection...');
        await FirebaseFirestore.instance
            .collection('pastRequests')
            .doc(orderId)
            .set(orderData);
        print('Order data moved successfully to pastRequests.');

        // Remove the order from the 'requests' collection
        print('Removing order from "requests" collection...');
        await FirebaseFirestore.instance
            .collection('requests')
            .doc(orderId)
            .delete();
        print('Order removed successfully from requests.');

        // Send notification to the user
        NotificationServices.sendNotificationToSelectedDriver(
            userDeviceToken,
            context,
            'Order Status Update',
            'Your order has been delivered successfully');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order marked as Delivered'),
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
      print('Error occurred while updating order status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status'),
        ),
      );
    }
  }
}
