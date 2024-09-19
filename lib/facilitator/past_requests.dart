import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        backgroundColor: Colors.blueAccent,
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
    List<dynamic> cartItems = requestData['cartItems'];
    String status = requestData['status'];

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
            _buildInfoRow('Name:', requestData['name']),
            _buildInfoRow('Phone:', requestData['phone']),
            _buildInfoRow('Train Number:', requestData['trainNumber']),
            _buildInfoRow('Compartment:', requestData['compartment']),
            _buildInfoRow('Seat Number:', requestData['seatNumber']),
            SizedBox(height: 10.h),
            Text('Cart Items:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            ...cartItems.map((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(item['image'],
                      width: 50.w, height: 50.h, fit: BoxFit.cover),
                ),
                title: Text(item['name'], style: TextStyle(fontSize: 14.sp)),
                subtitle: Text('Quantity: ${item['quantity']}',
                    style: TextStyle(fontSize: 12.sp)),
              );
            }).toList(),
            SizedBox(height: 10.h),
            Text(
              'Requested on: ${requestData['timestamp']?.toDate() ?? 'Unknown'}',
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
