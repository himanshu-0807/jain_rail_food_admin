import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:railway_food_delivery_admin/admin/admin_home.dart';
import 'package:railway_food_delivery_admin/chef/chef_home.dart';
import 'package:railway_food_delivery_admin/facilitator/facilitator_home.dart';
import 'package:railway_food_delivery_admin/logistic/logistics_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isLoading = false;

  void _loginWithEmailPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Attempting to log in with email: ${_emailController.text}");
      UserCredential? userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        String userEmail = userCredential.user!.email!;
        print("Login successful. User email: $userEmail");

        _firebaseMessaging.getToken().then((token) async {
          print("Firebase Token: $token");
          await FirebaseFirestore.instance
              .collection('admin_users')
              .doc(userEmail)
              .update({'deviceToken': token});
          print("Device token updated in Firestore.");
        });

        // Fetch user role
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('admin_users')
            .doc(userEmail)
            .get();

        if (userDoc.exists) {
          String role = userDoc['role'];
          print("User role: $role");

          // Redirect based on the role
          if (role == 'Admin') {
            print("Redirecting to AdminHome");
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => AdminHome()));
          } else if (role == 'Chef') {
            print("Redirecting to ChefHome");
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => ChefHome()));
          } else if (role == 'Facilitator') {
            print("Redirecting to FacilitatorHome");
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => FacilitatorHome()));
          } else if (role == 'Logistics') {
            print("Redirecting to LogisticsHome");
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => LogisticsHome()));
          } else {
            print("Invalid role");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid role')),
            );
          }
        } else {
          print("User document does not exist");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
      } else {
        print("Login failed: User not found");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed: User not found')),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Login failed: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 150,
                color: Colors.orange,
              ),
              Text(
                'Jain Meal Admin Login',
                style: TextStyle(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 40),

              // Email field
              _buildTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email,
                isObscure: false,
              ),
              const SizedBox(height: 16),

              // Password field
              _buildTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock,
                isObscure: true,
              ),
              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: 250.w,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithEmailPassword,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.orange)
                      : const Text(
                          'Login',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Optional: Add a "Forgot Password?" link here
              TextButton(
                onPressed: () async {
                  final TextEditingController emailController =
                      TextEditingController();

                  // Show a dialog to get the email for password reset
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Reset Password'),
                        content: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Enter your email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                // Send password reset email using Firebase
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(
                                  email: emailController.text.trim(),
                                );

                                // Notify the user that the reset email has been sent
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Password reset email sent!'),
                                  ),
                                );
                                Navigator.of(context).pop(); // Close the dialog
                              } catch (e) {
                                // Handle error (e.g., invalid email)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to send password reset email'),
                                  ),
                                );
                              }
                            },
                            child: Text('Send'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isObscure,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      obscureText: isObscure,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $hint';
        }
        return null;
      },
    );
  }
}
