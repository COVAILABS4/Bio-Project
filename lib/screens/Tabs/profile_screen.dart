import 'package:flutter/material.dart';
import 'package:heal_anemia/global_state.dart';
import 'package:heal_anemia/constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditMode = false;

  // Controllers for editable fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();

  List<String> addedDiagnoses = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  String? selectedGender; // Add this variable for gender selection

  Future<void> fetchUserData() async {
    String? phoneNumber =
        Provider.of<GlobalState>(context, listen: false).phoneNumber;

    final response = await http
        .get(Uri.parse('$SERVER_IP/get-data?phone_number=$phoneNumber'));

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
        isLoading = false;
        // Initialize controllers with existing user data
        if (userData != null) {
          nameController.text = userData!['userData']['name'];
          addressController.text = userData!['userData']['address'];
          aadhaarController.text = userData!['userData']['adhaar_number'];
          heightController.text = userData!['userData']['height'].toString();
          weightController.text = userData!['userData']['weight'].toString();
          selectedGender = userData!['userData']['gender'];
          addedDiagnoses =
              List<String>.from(userData!['userData']['diagnosis']);
        }
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data')),
      );
    }
  }

  Future<void> submitUserData() async {
    String? phoneNumber =
        Provider.of<GlobalState>(context, listen: false).phoneNumber;

    // Make API call to set data
    final response = await http.post(
      Uri.parse('$SERVER_IP/set-data'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'userData': {
          'name': nameController.text,
          'gender': selectedGender,
          'age': userData!['userData']['age'], // Assuming age is not editable
          'address': addressController.text,
          'adhaar_number': aadhaarController.text,
          'height': heightController.text,
          'weight': weightController.text,
          'diagnosis': addedDiagnoses,
        },
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User data updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false, // Hide the back button
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                if (isEditMode) {
                  submitUserData();
                  fetchUserData();
                }
                isEditMode = !isEditMode;
              });
            },
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData != null
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isEditMode
                            ? _buildTextField('Name', nameController)
                            : _styledInfoBox(
                                'Name', userData!['userData']['name']),
                        isEditMode
                            ? _buildGenderDropdown()
                            : _styledInfoBox(
                                'Gender', userData!['userData']['gender']),
                        isEditMode
                            ? _buildTextField('Address', addressController)
                            : _styledInfoBox(
                                'Address', userData!['userData']['address']),
                        isEditMode
                            ? _buildTextField(
                                'Aadhaar Number', aadhaarController)
                            : _styledInfoBox('Aadhaar Number',
                                userData!['userData']['adhaar_number']),
                        isEditMode
                            ? _buildTextField('Height (cm)', heightController,
                                keyboardType: TextInputType.number)
                            : _styledInfoBox('Height',
                                '${userData!['userData']['height']} cm'),
                        isEditMode
                            ? _buildTextField('Weight (kg)', weightController,
                                keyboardType: TextInputType.number)
                            : _styledInfoBox('Weight',
                                '${userData!['userData']['weight']} kg'),
                        SizedBox(height: 20),
                        isEditMode
                            ? _buildDiagnosisInput()
                            : _styledInfoBox('Diagnosis',
                                userData!['userData']['diagnosis'].join(', ')),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                )
              : Center(child: Text('No user data found')),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Gender",
          labelStyle: TextStyle(color: Colors.orangeAccent),
          border: OutlineInputBorder(),
          fillColor: Colors.white,
          filled: true,
        ),
        value: selectedGender ?? userData!['userData']['gender'],
        items: ['MALE', 'FEMALE'].map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedGender = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select your gender';
          }
          return null;
        },
      ),
    );
  }

  Widget _styledInfoBox(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withOpacity(0.1),
          border: Border.all(color: Colors.orangeAccent, width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$title: ',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.orangeAccent),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orangeAccent, width: 2.0),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDiagnosisInput() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: diagnosisController,
                decoration: InputDecoration(
                  labelText: "Diagnosis",
                  labelStyle: TextStyle(color: Colors.orangeAccent),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.orangeAccent, width: 2.0),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  if (diagnosisController.text.isNotEmpty) {
                    setState(() {
                      addedDiagnoses.add(diagnosisController.text);
                      diagnosisController.clear();
                    });
                  }
                },
                color: Colors.orangeAccent,
                tooltip: 'Add Diagnosis',
                padding: EdgeInsets.zero,
              ),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(0),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8.0,
          children: addedDiagnoses.map((diagnosis) {
            return Chip(
              label: Text(diagnosis),
              backgroundColor: Colors.orangeAccent[100],
              deleteIcon: Icon(Icons.clear, size: 18.0),
              onDeleted: () {
                setState(() {
                  addedDiagnoses.remove(diagnosis);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
