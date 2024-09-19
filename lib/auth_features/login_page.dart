import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      _firebaseMessaging.getToken().then((token) async {
        print("Firebase Token: $token");
        await FirebaseFirestore.instance
            .collection('admin_users')
            .doc(FirebaseAuth.instance.currentUser!.email.toString())
            .update({'deviceToken': token});
      });
      _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      // If login is successful, fetch the user role
      String userEmail = userCredential.user!.email!;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];

        // Redirect based on the role

        if (role == 'Admin') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => AdminHome()));
        } else if (role == 'Chef') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => ChefHome()));
        } else if (role == 'Facilitator') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => FacilitatorHome()));
        } else if (role == 'Logistics') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => LogisticsHome()));
        } else {
          // If no role matches, show error or default page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid role')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } on FirebaseAuthException catch (e) {
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
      appBar: AppBar(
        title: const Text('Login with Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _loginWithEmailPassword();
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
