import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class PastRequests extends StatefulWidget {
  const PastRequests({super.key});

  @override
  State<PastRequests> createState() => _PastRequestsState();
}

class _PastRequestsState extends State<PastRequests> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('pastRequests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No past requests available.'));
          }

          var requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var requestData = requests[index].data() as Map<String, dynamic>;
              return _buildRequestCard(requestData);
            },
          );
        },
      ),
    );
  }

  // Method to build the UI for each past request
  Widget _buildRequestCard(Map<String, dynamic> requestData) {
    List<dynamic> cartItems = requestData['selectedItems'] ?? [];
    String status = requestData['status'] ?? 'Unknown';

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
            _buildInfoRow('Request Id', requestData['requestId']),
            _buildInfoRow('Name:', requestData['name'] ?? 'N/A'),
            _buildInfoRow('Phone:', requestData['phone'] ?? 'N/A'),
            _buildInfoRow('Train No:', requestData['trainNumber'] ?? 'N/A'),
            _buildInfoRow('Compartment:', requestData['compartment'] ?? 'N/A'),
            _buildInfoRow('Seat No:', requestData['seatNumber'] ?? 'N/A'),
            SizedBox(height: 10.h),
            Text('Requested Items:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            if (cartItems.isNotEmpty)
              ...cartItems.map((item) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['name'] ?? 'Unnamed',
                          style: TextStyle(fontSize: 14.sp)),
                      Text('Qty: ${item['quantity'] ?? 0}',
                          style:
                              TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),
                );
              }).toList()
            else
              Text('No items in cart.'),
            SizedBox(height: 10.h),
            Text(
              'Requested on: ${_formatTimestamp(requestData['timestamp'])}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 10.h),
            Text(
              'Status: $status',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format the timestamp
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime); // 12-hour format
  }

  // Helper method to build the request detail rows
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
}
