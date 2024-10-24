import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
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
        title: Text('Requests'),
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
            _buildInfoRow('Request Id:', orderData['requestId']),
            _buildInfoRow('Name:', orderData['name']),
            _buildInfoRow('Phone:', orderData['phone']),
            _buildInfoRow('Train Number:', orderData['trainNumber']),
            _buildInfoRow('Compartment:', orderData['compartment']),
            _buildInfoRow('Seat Number:', orderData['seatNumber']),
            _buildInfoRow('Arrival Station:', orderData['station']),
            _buildInfoRow('Arrival Time:', orderData['arrivalTime']),
            _buildInfoRow(
                'Special Request',
                orderData['specialRequest'] == ''
                    ? 'No Special Request'
                    : orderData['specialRequest']),
            SizedBox(height: 10.h),
            Text('Requested Food:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ...cartItems.map((item) {
              String foodName = item['name'] ?? 'Unknown';
              int quantity = item['quantity'] ?? 1;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(foodName, style: TextStyle(fontSize: 14.sp)),
                    Text('Qty: $quantity',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 10.h),
            Text(
              'Requested on: ${_formatTimestamp(orderData['timestamp'])}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 10.h),
            Text('Status: ${orderData['status']}'),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: () => _updateOrderStatus(orderId, orderData),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align the text at the top
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Flexible(
            child: Text(
              value,
              softWrap: true, // Allows the text to wrap to a new line
              maxLines: null, // No limit on the number of lines
              style: TextStyle(
                color: Colors.black, // Customize text style if needed
              ),
            ),
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

      // Fetch the request document to get the current status and user's device token
      DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .doc(orderId)
          .get();

      if (requestSnapshot.exists) {
        // Extract the order's current status and user's device token
        Map<String, dynamic> requestData =
            requestSnapshot.data() as Map<String, dynamic>;
        String currentStatus = requestData['status'];
        String userDeviceToken = requestData['deviceToken'];

        // Check if the current status is 'Dispatched'
        if (currentStatus == 'Dispatched') {
          // Proceed with marking the order as 'Delivered'
          orderData['status'] = 'Delivered';

          // Update the status to 'Delivered' in the 'requests' collection
          print('Updating status to "Delivered" in "requests" collection...');
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(orderId)
              .update({'status': 'Delivered'});
          print('Status updated successfully in requests.');

          // Move the updated order data to the 'pastRequests' collection
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
              'Your order has been delivered successfully.');

          // Show success message
          IconSnackBar.show(context,
              label: 'Order marked as Delivered',
              snackBarType: SnackBarType.success);
        } else {
          // If the status is not 'Dispatched', show a message that it's yet to be dispatched
          IconSnackBar.show(context,
              label: 'Order yet to be dispatched',
              snackBarType: SnackBarType.alert);
        }
      } else {
        IconSnackBar.show(context,
            label: 'Order not found', snackBarType: SnackBarType.fail);
      }
    } catch (e) {
      print('Error occurred while updating order status: $e');
      IconSnackBar.show(context,
          label: 'Failed to update order status',
          snackBarType: SnackBarType.fail);
    }
  }
}
