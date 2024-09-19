import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

class ManageStaff extends StatefulWidget {
  const ManageStaff({super.key});

  @override
  State<ManageStaff> createState() => _ManageStaffState();
}

class _ManageStaffState extends State<ManageStaff> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'Facilitator'; // Default role
  final List<String> _roles = ['Facilitator', 'Chef', 'Logistics', 'Admin'];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false; // Loading state

  // Function to show a loading indicator
  void _toggleLoading(bool status) {
    setState(() {
      _isLoading = status;
    });
  }

  // Function to save staff details to Firestore
  Future<void> _saveStaffToFirestore() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      _toggleLoading(true); // Show loading

      // Create user with Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user details to Firestore
      await _firestore.collection('admin_users').doc(email).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': email,
        'role': _selectedRole,
        'createdAt': Timestamp.now(),
        "deviceToken": ""
      });

      IconSnackBar.show(context,
          label: 'User Added !!', snackBarType: SnackBarType.success);
    } catch (e) {
      IconSnackBar.show(context,
          label: 'Error Adding Staff !!', snackBarType: SnackBarType.fail);
    } finally {
      _toggleLoading(false); // Hide loading
    }
  }

  // Show add staff dialog
  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(), // Show loading indicator
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'User Role',
                    border: OutlineInputBorder(),
                  ),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_emailController.text.isNotEmpty) {
                  await _saveStaffToFirestore(); // Save data to Firestore
                  Navigator.of(context).pop(); // Close dialog after saving
                } else {
                  IconSnackBar.show(context,
                      label: 'Email is required! !!',
                      snackBarType: SnackBarType.alert);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editStaff(DocumentSnapshot staff) async {
    _nameController.text = staff['name'];
    _phoneController.text = staff['phone'];
    _selectedRole = staff['role'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Staff'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(), // Show loading indicator
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'User Role',
                    border: OutlineInputBorder(),
                  ),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRole = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                _toggleLoading(true); // Show loading
                await _firestore
                    .collection('admin_users')
                    .doc(staff.id)
                    .update({
                  'name': _nameController.text,
                  'phone': _phoneController.text,
                  'role': _selectedRole,
                });
                _toggleLoading(false); // Hide loading

                IconSnackBar.show(context,
                    label: 'Staff details updated successfully !!',
                    snackBarType: SnackBarType.success);

                Navigator.of(context).pop(); // Close dialog after saving
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStaff(String staffId, String email) async {
    bool confirmDelete = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Staff'),
          content: const Text('Are you sure you want to delete this staff?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                confirmDelete = true;
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      _toggleLoading(true); // Show loading

      // Delete from Firestore
      await _firestore.collection('admin_users').doc(staffId).delete();

      // Show success message
      IconSnackBar.show(context,
          label: 'Staff details deleted successfully! !!',
          snackBarType: SnackBarType.success);

      _toggleLoading(false); // Hide loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Staff'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('admin_users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No staff members available.'));
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot staff = snapshot.data!.docs[index];

                  return ListTile(
                    title: Text(staff['name']),
                    subtitle: Text('${staff['role']} | ${staff['phone']}'),
                    trailing: PopupMenuButton(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editStaff(staff);
                        } else if (value == 'delete') {
                          _deleteStaff(staff.id, staff['email']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStaffDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
