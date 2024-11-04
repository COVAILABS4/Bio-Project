import 'package:flutter/material.dart';
import 'package:heal_anemia/constants.dart';
import 'package:heal_anemia/screens/pages/login_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dashboard.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedRegionCode = "+1"; // Default region code

  // Function to register the user
  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      String phoneNumber = '$_selectedRegionCode${_phoneController.text}';
      String dob = _dobController.text;

      // Make an API call to /register
      final response = await http.post(
        Uri.parse('$SERVER_IP/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': phoneNumber, 'dob': dob}),
      );

      if (response.statusCode == 201) {
        // Registration successful, navigate to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        // Show error message based on response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonDecode(response.body)['message'])),
        );
      }
    }
  }

  // Function to show a date picker for DOB
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Centered and rounded logo
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    // shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(REGISTER_LOGO),
                      fit: BoxFit.fitHeight,
                    ),
                   
                  ),
                ),
                const SizedBox(height: 30),

                // Region selection and phone number input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.orangeAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedRegionCode,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRegionCode = newValue!;
                          });
                        },
                        items: <String>["+1", "+91", "+44", "+81", "+86"]
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        underline: Container(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date of Birth input with date picker
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Date of Birth (DD/MM/YYYY)",
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Register button with enhanced styling
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 15),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Register",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                // Already have an account? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        // Navigate to login screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
