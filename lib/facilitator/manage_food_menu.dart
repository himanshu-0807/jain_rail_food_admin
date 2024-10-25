import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart'; // For picking images

class ManageFoodMenu extends StatelessWidget {
  const ManageFoodMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Food Menu'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Today's Menu"),
              Tab(text: 'Saved Menu'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TodaysMenuPage(),
            SavedMenuPage(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          elevation: 0,
          onPressed: () {
            _showAddFoodDialog(context); // Call the dialog function
          },
          child: const Icon(Icons.add),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                30.0), // Adjust the value for the desired roundness
          ),
        ),
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddFoodDialog();
      },
    );
  }
}

class AddFoodDialog extends StatefulWidget {
  @override
  _AddFoodDialogState createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  Future<void> _uploadImageAndSaveData() async {
    if (_nameController.text.isNotEmpty && _descController.text.isNotEmpty) {
      try {
        // Upload image to Firebase Storage
        String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

        // Save data to Firestore
        CollectionReference foodItems =
            FirebaseFirestore.instance.collection('food_items');
        await foodItems.doc(uniqueId).set({
          'name': _nameController.text,
          'description': _descController.text,
          'createdAt': Timestamp.now(),
          'id': uniqueId
        });

        IconSnackBar.show(context,
            label: 'New menu item added successfully!',
            snackBarType: SnackBarType.success);
        Navigator.of(context).pop(); // Close dialog
      } catch (e) {
        IconSnackBar.show(context,
            label: 'Failed to add menu item. Please try again.',
            snackBarType: SnackBarType.fail);
      }
    } else {
      IconSnackBar.show(context,
          label: 'Please fill all fields and select an image.',
          snackBarType: SnackBarType.fail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Menu Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description/Ingredients',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _uploadImageAndSaveData,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class TodaysMenuPage extends StatefulWidget {
  const TodaysMenuPage({super.key});

  @override
  _TodaysMenuPageState createState() => _TodaysMenuPageState();
}

class _TodaysMenuPageState extends State<TodaysMenuPage> {
  final Set<String> _selectedItems = {}; // Set to store selected item IDs
  bool _selectAll = false; // For Select All checkbox

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('todays_menu').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No items for today."));
        }

        final items = snapshot.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: (bool? value) {
                          setState(() {
                            _selectAll = value ?? false;
                            if (_selectAll) {
                              _selectedItems.addAll(items.map((doc) => doc.id));
                            } else {
                              _selectedItems.clear();
                            }
                          });
                        },
                      ),
                      const Text('Select All'),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: _selectedItems.isEmpty ? null : _bulkDelete,
                      child: const Text(
                        'Delete Selected',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final data = item.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(data['name'] ?? 'No Name'),
                    subtitle: Text(data['description'] ?? 'No Description'),
                    trailing: Checkbox(
                      value: _selectedItems.contains(item.id),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedItems.add(item.id);
                          } else {
                            _selectedItems.remove(item.id);
                          }
                        });
                      },
                    ),
                    onLongPress: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text(
                              'Are you sure you want to delete this item?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        await FirebaseFirestore.instance
                            .collection('todays_menu')
                            .doc(item.id)
                            .delete();

                        IconSnackBar.show(context,
                            label: 'Item deleted successfully!',
                            snackBarType: SnackBarType.success);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bulkDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Deletion'),
        content:
            const Text('Are you sure you want to delete all selected items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      for (String id in _selectedItems) {
        await FirebaseFirestore.instance
            .collection('todays_menu')
            .doc(id)
            .delete();
      }

      setState(() {
        _selectedItems.clear();
        _selectAll = false;
      });

      IconSnackBar.show(context,
          label: 'Selected items deleted successfully!',
          snackBarType: SnackBarType.success);
    }
  }
}

// Widget for "Saved Menu" tab

class SavedMenuPage extends StatefulWidget {
  const SavedMenuPage({super.key});

  @override
  _SavedMenuPageState createState() => _SavedMenuPageState();
}

class _SavedMenuPageState extends State<SavedMenuPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _selectedItems = [];
  Set<String> _todaysMenuIds = Set(); // To keep track of items in today's menu

  @override
  void initState() {
    super.initState();
    _fetchTodaysMenuIds();
  }

  Future<void> _fetchTodaysMenuIds() async {
    try {
      final snapshot = await _firestore.collection('todays_menu').get();
      setState(() {
        _todaysMenuIds = snapshot.docs.map((doc) => doc.id).toSet();
      });
    } catch (e) {
      IconSnackBar.show(context,
          label: 'Failed to fetch today\'s menu. Please try again.',
          snackBarType: SnackBarType.fail);
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      // Delete item from food_items collection
      await _firestore.collection('food_items').doc(itemId).delete();
      // Optionally, delete item from todays_menu if present
      if (_todaysMenuIds.contains(itemId)) {
        await _firestore.collection('todays_menu').doc(itemId).delete();
      }
      // Show a snackbar on success
      IconSnackBar.show(context,
          label: 'Item has been deleted.', snackBarType: SnackBarType.success);
      // Refresh the menu IDs
      _fetchTodaysMenuIds();
    } catch (e) {
      IconSnackBar.show(context,
          label: 'Failed to delete item. Please try again.',
          snackBarType: SnackBarType.fail);
    }
  }

  Future<void> _moveToTodaysMenu() async {
    if (_selectedItems.isNotEmpty) {
      try {
        for (String itemId in _selectedItems) {
          // Fetch item data from saved_food_items
          DocumentSnapshot doc =
              await _firestore.collection('food_items').doc(itemId).get();
          if (doc.exists) {
            // Cast data to Map<String, dynamic>
            Map<String, dynamic> itemData = doc.data() as Map<String, dynamic>;

            // Add item data to todays_menu
            await _firestore
                .collection('todays_menu')
                .doc(itemId)
                .set(itemData);
          }
        }
        // Optionally, show a snackbar on success
        IconSnackBar.show(context,
            label: 'Selected items have been copied to Today\'s Menu.',
            snackBarType: SnackBarType.success);
        // Clear selected items
        _fetchTodaysMenuIds();
        setState(() {
          _selectedItems.clear();
        });
      } catch (e) {
        IconSnackBar.show(context,
            label: 'Failed to move items. Please try again.',
            snackBarType: SnackBarType.fail);
      }
    } else {
      IconSnackBar.show(context,
          label: 'No items selected.', snackBarType: SnackBarType.fail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('food_items').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No saved items.'));
              }

              var items = snapshot.data!.docs;
              return ListView(
                children: items.map((doc) {
                  bool isSelected = _selectedItems.contains(doc.id) ||
                      _todaysMenuIds.contains(
                          doc.id); // Checked if already in today's menu
                  return ListTile(
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedItems.add(doc.id);
                          } else {
                            _selectedItems.remove(doc.id);
                          }
                        });
                      },
                    ),
                    title: Text(doc['name']),
                    subtitle: Text(doc['description']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // Confirm deletion
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Confirm Deletion'),
                              content: Text(
                                  'Are you sure you want to delete this item?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deleteItem(doc.id);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 250.w,
            height: 45.h,
            child: ElevatedButton(
              onPressed: _moveToTodaysMenu,
              child: const Text(
                'Move to Today\'s Menu',
                style:
                    TextStyle(color: Colors.white), // Set text color to white
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.orange, // Set background color to orange
              ),
            ),
          ),
        ),
      ],
    );
  }
}
