import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:railway_food_delivery_admin/notification_services.dart';

class ManageShifts extends StatefulWidget {
  const ManageShifts({super.key});

  @override
  State<ManageShifts> createState() => _ManageShiftsState();
}

class _ManageShiftsState extends State<ManageShifts> {
  String? selectedFacilitator;
  String? selectedChef;
  String? selectedLogistics;

  Future<Map<String, List<Map<String, dynamic>>>> fetchUsersByRole() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('admin_users').get();
    final List<Map<String, dynamic>> users = snapshot.docs
        .map((doc) => {
              'name': doc['name'],
              'role': doc['role'],
              'phone': doc['phone'],
              'deviceToken': doc['deviceToken'],
              'id': doc.id
            })
        .toList();

    final Map<String, List<Map<String, dynamic>>> categorizedUsers = {
      'Facilitator': [],
      'Chef': [],
      'Logistics': []
    };

    for (var user in users) {
      if (user['role'] == 'Facilitator') {
        categorizedUsers['Facilitator']?.add(user);
      } else if (user['role'] == 'Chef') {
        categorizedUsers['Chef']?.add(user);
      } else if (user['role'] == 'Logistics') {
        categorizedUsers['Logistics']?.add(user);
      }
    }

    return categorizedUsers;
  }

  // Fetch current shift data from Firestore
  Future<Map<String, Map<String, dynamic>>?> fetchTodaysShifts() async {
    final DocumentSnapshot shiftsSnapshot = await FirebaseFirestore.instance
        .collection('todays_shifts')
        .doc('shifts')
        .get();

    if (shiftsSnapshot.exists) {
      final Map<String, dynamic> data =
          shiftsSnapshot.data() as Map<String, dynamic>;
      return {
        'Facilitator': data['active_facilitator'],
        'Chef': data['active_chef'],
        'Logistics': data['active_logistics'],
      };
    }

    return null;
  }

  // Function to handle submitting the shifts to Firestore
  Future<void> submitShifts(
      String facilitatorId, String chefId, String logisticsId) async {
    // Fetch the selected users' data
    final facilitator = await FirebaseFirestore.instance
        .collection('admin_users')
        .doc(facilitatorId)
        .get();
    final chef = await FirebaseFirestore.instance
        .collection('admin_users')
        .doc(chefId)
        .get();
    final logistics = await FirebaseFirestore.instance
        .collection('admin_users')
        .doc(logisticsId)
        .get();

    // Check if any user has an empty device token
    if (facilitator['deviceToken'] == null ||
        facilitator['deviceToken'] == '' ||
        chef['deviceToken'] == null ||
        chef['deviceToken'] == '' ||
        logistics['deviceToken'] == null ||
        logistics['deviceToken'] == '') {
      // Show error message if any device token is missing
      IconSnackBar.show(
        context,
        label: 'Unverified User Selected !!',
        snackBarType: SnackBarType.fail,
      );

      // Prevent the operation from proceeding
      return;
    }

    final Map<String, dynamic> todaysShifts = {
      'active_facilitator': {
        'name': facilitator['name'],
        'phone': facilitator['phone'],
        'deviceToken': facilitator['deviceToken']
      },
      'active_chef': {
        'name': chef['name'],
        'phone': chef['phone'],
        'deviceToken': chef['deviceToken']
      },
      'active_logistics': {
        'name': logistics['name'],
        'phone': logistics['phone'],
        'deviceToken': logistics['deviceToken']
      }
    };

    // Send notifications to the assigned users
    NotificationServices.sendNotificationToSelectedDriver(
        facilitator['deviceToken'],
        context,
        'Update !!',
        'You are assigned as Facilitator for today');

    NotificationServices.sendNotificationToSelectedDriver(chef['deviceToken'],
        context, 'Update !!', 'You are assigned as Chef for today');

    NotificationServices.sendNotificationToSelectedDriver(
        logistics['deviceToken'],
        context,
        'Update !!',
        'You are assigned as Logistics for today');

    // Update the 'todays_shifts' collection
    await FirebaseFirestore.instance
        .collection('todays_shifts')
        .doc('shifts')
        .set(todaysShifts);

    IconSnackBar.show(context,
        label: 'Shift Changed', snackBarType: SnackBarType.success);

    // Refresh the screen by resetting selected values and re-fetching data
    setState(() {
      selectedFacilitator = null;
      selectedChef = null;
      selectedLogistics = null;
    });
  }

  // Function to open dialog and allow role selection
  void openRoleSelectionDialog(BuildContext context, String role,
      List<Map<String, dynamic>> users, String? selectedId) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedUser = selectedId;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select $role'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: users.map((user) {
                  return RadioListTile(
                    title: Text(user['name']),
                    value: user['id'],
                    groupValue: selectedUser,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedUser = value as String?;
                      });
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      if (role == 'Facilitator') {
                        selectedFacilitator = selectedUser;
                      } else if (role == 'Chef') {
                        selectedChef = selectedUser;
                      } else if (role == 'Logistics') {
                        selectedLogistics = selectedUser;
                      }
                    });
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Shifts'),
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>?>(
        future: fetchTodaysShifts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final todaysShifts = snapshot.data;

          return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: fetchUsersByRole(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (userSnapshot.hasError) {
                return Center(child: Text('Error: ${userSnapshot.error}'));
              }

              final categorizedUsers = userSnapshot.data ?? {};

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionWidget(
                      title: "Today's Facilitator",
                      user: todaysShifts?['Facilitator'],
                      onEditPressed: () {
                        openRoleSelectionDialog(
                            context,
                            'Facilitator',
                            categorizedUsers['Facilitator']!,
                            selectedFacilitator);
                      },
                    ),
                    SectionWidget(
                      title: "Today's Chef",
                      user: todaysShifts?['Chef'],
                      onEditPressed: () {
                        openRoleSelectionDialog(context, 'Chef',
                            categorizedUsers['Chef']!, selectedChef);
                      },
                    ),
                    SectionWidget(
                      title: "Today's Logistics",
                      user: todaysShifts?['Logistics'],
                      onEditPressed: () {
                        openRoleSelectionDialog(context, 'Logistics',
                            categorizedUsers['Logistics']!, selectedLogistics);
                      },
                    ),
                    Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: InkWell(
                          onTap: selectedFacilitator != null &&
                                  selectedChef != null &&
                                  selectedLogistics != null
                              ? () {
                                  submitShifts(selectedFacilitator!,
                                      selectedChef!, selectedLogistics!);
                                }
                              : null,
                          child: Container(
                            child: Center(
                              child: Text(
                                'Submit Shifts',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17.sp,
                                    color: Colors.white),
                              ),
                            ),
                            width: double.infinity,
                            height: 50.h,
                            decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(15.r)),
                          ),
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Widget to display users in a section and an Edit button
class SectionWidget extends StatelessWidget {
  final String title;
  final Map<String, dynamic>? user;
  final VoidCallback onEditPressed;

  const SectionWidget({
    super.key,
    required this.title,
    required this.user,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                      onPressed: onEditPressed, icon: const Icon(Icons.edit)),
                ],
              ),
            ),
            const Divider(),
            if (user != null)
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(user!['name']),
                subtitle: Text(user!['phone']),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No user selected.'),
              ),
          ],
        ),
      ),
    );
  }
}
