import 'package:flutter/material.dart';
import 'package:heal_anemia/global_state.dart';
import 'package:heal_anemia/constants.dart';
import 'package:heal_anemia/screens/pages/survey_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedRegion; // For storing the selected region
  final List<String> _regions = [
    'Region 1',
    'Region 2',
    'Region 3',
    'Region 4'
  ];
  String _selectedCountryCode = '+1'; // Default country code

  final List<String> _countryCodes = [
    '+1', '+91', '+44', '+61', // Add more country codes as needed
  ];

  // Function to log in the user
  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      String phoneNumber = _phoneController.text;
      String dob = _dobController.text;
      String region = _selectedRegion ?? '';
      String countryCode = _selectedCountryCode;

      // Make an API call to /login
      final response = await http.post(
        Uri.parse('$SERVER_IP/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': '$countryCode$phoneNumber',
          'dob': dob,
          'region': region,
        }),
      );

      // Decode the response
      final responseData = jsonDecode(response.body);

      // Show message from response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseData['message'])),
      );

      if (response.statusCode == 200) {
        // Successful login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('phone_number', "$countryCode$phoneNumber");
        prefs.setString('dob', dob);
        // prefs.setString('region', region);

        print(responseData);

        // Update global state with the full phone number
        Provider.of<GlobalState>(context, listen: false)
            .setPhoneNumber("$countryCode$phoneNumber");

        // Check if the user is new
        if (responseData['newUser'] == true) {
          // Navigate to SurveyPage
          print(region);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => SurveyPage(
                      phoneNumber: "$countryCode$phoneNumber",
                    )), // Ensure SurveyPage is defined
          );
        } else {
          // Navigate to Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
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
        title: const Text("Login"),
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
                      image: AssetImage(
                          LOGIN_LOGO), // Replace with the actual image path
                      fit: BoxFit.fitHeight,
                    ),
                    
                  ),
                ),
                const SizedBox(height: 30),

                // Phone Number with Country Code input
                Row(
                  children: [
                    // Country code dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.orangeAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCountryCode = newValue!;
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

                    // Phone Number input field
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
                const SizedBox(height: 20),

                // Login button with enhanced styling
                ElevatedButton(
                  onPressed: _loginUser,
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
                    "Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
