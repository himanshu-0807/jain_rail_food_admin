import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:railway_food_delivery_admin/notification_services.dart'; // Import the intl package

class OngoingRequest extends StatefulWidget {
  const OngoingRequest({super.key});

  @override
  State<OngoingRequest> createState() => _OngoingRequestState();
}

class _OngoingRequestState extends State<OngoingRequest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ongoing Food Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('requests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No requests available.'));
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var requestData = requests[index].data() as Map<String, dynamic>;
              return _buildRequestCard(requestData, requests[index].id);
            },
          );
        },
      ),
    );
  }

  // Method to build the UI for each request
  Widget _buildRequestCard(Map<String, dynamic> requestData, String requestId) {
    List<Map<String, dynamic>> cartItems =
        (requestData['selectedItems'] as List<dynamic>?)
                ?.map((item) => item as Map<String, dynamic>)
                .toList() ??
            [];

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request ID: $requestId',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            _buildInfoRow('Name:', requestData['name']),
            _buildInfoRow('Phone:', requestData['phone']),
            _buildInfoRow('Train No:', requestData['trainNumber']),
            _buildInfoRow('Compartment:', requestData['compartment']),
            _buildInfoRow('Seat No:', requestData['seatNumber']),
            _buildInfoRow('Arrival Station:', requestData['station']),
            _buildInfoRow('Arrival Time:', requestData['arrivalTime']),
            _buildInfoRow(
                'Special Request',
                requestData['specialRequest'] == ''
                    ? 'No Special Request'
                    : requestData['specialRequest']),
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
              'Requested on: ${_formatTimestamp(requestData['timestamp'])}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 16.h),
            Text('Status: ${requestData['status']}',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  // Helper method to build the request detail rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Align the text at the top
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

  // Method to accept the request
}
