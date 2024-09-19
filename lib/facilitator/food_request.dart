import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:railway_food_delivery_admin/notification_services.dart'; // Import the intl package

class FoodRequest extends StatefulWidget {
  const FoodRequest({super.key});

  @override
  State<FoodRequest> createState() => _FoodRequestState();
}

class _FoodRequestState extends State<FoodRequest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Requests'),
        backgroundColor: Colors.blueAccent,
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
    // Provide a default empty list if cartItems is null, expecting list of maps
    List<Map<String, dynamic>> cartItems =
        (requestData['selectedItems'] as List<dynamic>?)
                ?.map((item) => item as Map<String, dynamic>)
                .toList() ??
            [];

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
            Text('Request ID: $requestId'),
            _buildInfoRow('Name:', requestData['name']),
            _buildInfoRow('Phone:', requestData['phone']),
            _buildInfoRow('Train Number:', requestData['trainNumber']),
            _buildInfoRow('Compartment:', requestData['compartment']),
            _buildInfoRow('Seat Number:', requestData['seatNumber']),
            SizedBox(height: 10.h),
            Text('Requested Food:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            // Display each cart item with its quantity
            ...cartItems.map((item) {
              String foodName = item['name'] ?? 'Unknown';
              int quantity = item['quantity'] ?? 1;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(foodName, style: TextStyle(fontSize: 14.sp)),
                trailing: Text('Quantity: $quantity',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
              );
            }),
            SizedBox(height: 10.h),
            Text(
              'Requested on: ${_formatTimestamp(requestData['timestamp'])}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 20.h),
            Text('Status: ${requestData['status']}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptRequest(requestId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text('Accept'),
                ),
                ElevatedButton(
                  onPressed: () => _rejectRequest(requestId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
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

  // Method to format the timestamp in 12-hour format
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown';
    }
    DateTime date = timestamp.toDate();
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }

  // Method to accept the request
  void _acceptRequest(String requestId) {
    // Fetch the request document
    FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        // Extract device token of the user who placed the order
        String userDeviceToken = snapshot.data()?['deviceToken'];

        // Update the request status to 'Accepted'
        FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .update({'status': 'Accepted'}).then((_) {
          // Fetch today's shifts to get device tokens
          FirebaseFirestore.instance
              .collection('todays_shifts')
              .doc('shifts')
              .get()
              .then((shiftsSnapshot) {
            if (shiftsSnapshot.exists) {
              var shiftsData = shiftsSnapshot.data();

              // Get device tokens of chef and logistics
              String chefDeviceToken =
                  shiftsData?['active_chef']['deviceToken'];
              String logisticsDeviceToken =
                  shiftsData?['active_logistics']['deviceToken'];

              // Send notifications
              NotificationServices.sendNotificationToSelectedDriver(
                  chefDeviceToken,
                  context,
                  'New Request',
                  'You have a new request.');
              NotificationServices.sendNotificationToSelectedDriver(
                  logisticsDeviceToken,
                  context,
                  'New Request',
                  'You have a new request.');
              NotificationServices.sendNotificationToSelectedDriver(
                  userDeviceToken,
                  context,
                  'Request Accepted',
                  'Your request has been accepted.');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Request accepted')),
              );
            } else {
              print('No active shifts found');
            }
          }).catchError((error) {
            print('Error fetching today\'s shifts: $error');
          });
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error accepting request')),
          );
        });
      } else {
        print('Request not found');
      }
    }).catchError((error) {
      print('Error fetching request: $error');
    });
  }

  void _rejectRequest(String requestId) {
    String? rejectionReason;

    // Fetch the request document
    FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        // Access the request data
        final requestData = snapshot.data();
        String deviceToken = requestData?['deviceToken'];

        // Print the device token
        print('Device Token: $deviceToken');

        // Show alert dialog to enter rejection reason
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Reject Request'),
              content: TextField(
                onChanged: (value) {
                  rejectionReason = value; // Capture the input value
                },
                decoration: const InputDecoration(
                  hintText: 'Enter reason for rejection',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (rejectionReason != null &&
                        rejectionReason!.isNotEmpty) {
                      // Create a copy of the request data to store in pastRequests
                      final pastRequestData = {
                        ...?requestData,
                        'status': 'Rejected',
                        'rejectionReason': rejectionReason,
                      };

                      // Store the request data in pastRequests
                      FirebaseFirestore.instance
                          .collection('pastRequests')
                          .doc(requestId) // Use the same request ID
                          .set(pastRequestData)
                          .then((_) {
                        // Delete the original request
                        return FirebaseFirestore.instance
                            .collection('requests')
                            .doc(requestId)
                            .delete();
                      }).then((_) {
                        // Send notification
                        NotificationServices.sendNotificationToSelectedDriver(
                          deviceToken,
                          context,
                          'Sorry!! Request Rejected',
                          rejectionReason,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Request rejected')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error processing request')),
                        );
                      });
                      Navigator.of(context)
                          .pop(); // Close the dialog after submission
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a reason')),
                      );
                    }
                  },
                  child: const Text('Reject'),
                ),
              ],
            );
          },
        );
      } else {
        print('Request not found');
      }
    }).catchError((error) {
      print('Error fetching request: $error');
    });
  }
}
