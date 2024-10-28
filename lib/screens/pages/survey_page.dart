import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heal_anemia/constants.dart';
import 'package:heal_anemia/screens/dashboard.dart';
import 'package:http/http.dart' as http;

class SurveyPage extends StatefulWidget {
  final String phoneNumber;
  const SurveyPage({super.key, required this.phoneNumber});

  @override
  _SurveyPageState createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKeys = List.generate(3, (_) => GlobalKey<FormState>());
  final Map<String, dynamic> surveyData = {
    'name': '',
    'gender': '',
    'age': '',
    'address': '',
    'adhaar_number': '',
    'height': '',
    'weight': '',
    'diagnosis': [],
  };
  int _currentPage = 0;

  final TextEditingController diagnosisController = TextEditingController();
  List<String> addedDiagnoses = [];
  final List<String> _questions = [
    'Personal Details',
    'Address Details',
    'Health Information',
  ];

  void _nextPage() {
    if (_formKeys[_currentPage].currentState!.validate()) {
      setState(() {
        if (_currentPage < _questions.length - 1) {
          _currentPage++;
        } else {
          _submitSurvey();
        }
      });
    }
  }

  Future<void> _submitSurvey() async {
    final response = await http.post(
      Uri.parse('$SERVER_IP/submit-survey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': widget.phoneNumber,
        'userData': surveyData,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Survey submitted successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit survey")),
      );
    }
  }

  Widget _buildPageContent() {
    if (_currentPage == 0) {
      return Column(
        children: [
          _buildTextField("Name", (value) => surveyData['name'] = value),
          _buildGenderDropdown(),
          _buildTextField("Age", (value) => surveyData['age'] = value,
              keyboardType: TextInputType.number),
        ],
      );
    } else if (_currentPage == 1) {
      return Column(
        children: [
          _buildTextField("Address", (value) => surveyData['address'] = value),
          _buildTextField(
              "Aadhaar Number", (value) => surveyData['adhaar_number'] = value,
              keyboardType: TextInputType.number),
        ],
      );
    } else {
      return Column(
        children: [
          _buildTextField(
              "Height (cm)", (value) => surveyData['height'] = value,
              keyboardType: TextInputType.number),
          _buildTextField(
              "Weight (kg)", (value) => surveyData['weight'] = value,
              keyboardType: TextInputType.number),
          _buildDiagnosisInput(),
        ],
      );
    }
  }

  Widget _buildGenderDropdown() {
    String? selectedGender;

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
        value: selectedGender,
        items: ['MALE', 'FEMALE'].map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            surveyData['gender'] = value;
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

  Widget _buildTextField(String label, Function(String) onChanged,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
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
        onChanged: onChanged,
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
                      surveyData['diagnosis'] = addedDiagnoses;
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
              deleteIcon: Icon(Icons.close, color: Colors.red),
              onDeleted: () {
                setState(() {
                  addedDiagnoses.remove(diagnosis);
                  surveyData['diagnosis'] = addedDiagnoses;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Survey"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        // Make content scrollable to prevent overflow
        child: Form(
          key: _formKeys[_currentPage],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                Text(
                  _questions[_currentPage],
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent),
                ),
                SizedBox(height: 20),
                _buildPageContent(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == _questions.length - 1
                      ? "Finish"
                      : "Next"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orangeAccent,
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
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
