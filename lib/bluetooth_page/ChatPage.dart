import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:heal_anemia/constants.dart';
import 'package:heal_anemia/global_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'GlobalState.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _Message {
  int whom;
  String text;
  _Message(this.whom, this.text);
}

class _ChatPageState extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;
  List<_Message> messages = List<_Message>.empty(growable: true);
  final ScrollController listScrollController = ScrollController();
  bool isConnecting = true;
  bool get isConnected => connection?.isConnected ?? false;
  bool isDisconnecting = false;
  bool isSendingData = false;

  late String gender;

  // int age = 20; // Store the user's age
  String anemiaGrade = ''; // Store the anemia grade message

  double hp_value = 0.0;

  @override
  void initState() {
    super.initState();
    getGender();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initConnection());
  }

  Future<void> getGender() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString('phone_number');

    print("-=-=-=$phoneNumber");

    final url = Uri.parse('$SERVER_IP/get-gender?phone_number=$phoneNumber');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          gender = data['gender']; // Ensure gender is set properly
        });
        print("Gender: $gender");
      } else {
        print('Error: Unable to fetch gender.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _initConnection() {
    connection = Provider.of<GlobalState>(context, listen: false).connection;
    if (connection != null) {
      setState(() {
        isConnecting = false;
      });
      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected by remote request');
        }
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverName = Provider.of<GlobalState>(context).deviceName;
    return Scaffold(
      appBar: AppBar(
        title: Text(serverName),
        backgroundColor: Colors.blueGrey,
        automaticallyImplyLeading: false, // Hide the back button
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(12.0),
                controller: listScrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isSentMessage = message.whom == clientID;
                  return Align(
                    alignment: isSentMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSentMessage
                            ? Colors.greenAccent.withOpacity(0.5)
                            : Colors.blueAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSentMessage ? Colors.green : Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (isSendingData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "Sending data...",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: isConnected ? _getData : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  "GET DATA",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Result Box
            if (anemiaGrade.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Haemoglobin (Hb) : ${hp_value} g/dL"),
                    Text(
                      "Anemia Grade Result",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      anemiaGrade,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "SAVE",
                    style: TextStyle(fontSize: 18, color: Colors.white),

                    // selectionColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _clearData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    "CLEAR",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    String receivedText = utf8.decode(data).replaceAll('\n', '').trim();
    if (receivedText.isNotEmpty) {
      setState(() {
        messages.add(_Message(1, receivedText));
        anemiaGrade = _getAnemiaGrade(receivedText);

        print(anemiaGrade);
      });
    }
  }

  String _getAnemiaGrade(String receivedText) {
    print("Received Text: $receivedText");
    double hemoglobinLevel = double.tryParse(receivedText) ?? 0.0;

    setState(() {
      hp_value = hemoglobinLevel;
    });
    // print("Hemoglobin Level: $receivedText");

    if (hemoglobinLevel < 6.5) {
      return "Life-threatening Anemia: less than 6.5 g/dL";
    } else if (hemoglobinLevel >= 6.5 && hemoglobinLevel <= 7.9) {
      return "Severe Anemia: 6.5 to 7.9 g/dL";
    } else if (hemoglobinLevel >= 8.0 && hemoglobinLevel < 10.0) {
      return "Moderate Anemia: 8.0 to 10.0 g/dL";
    } else if (gender.toLowerCase() == "female" &&
        10 <= hemoglobinLevel &&
        hemoglobinLevel <= 12) {
      return "Mild : 10.0 g/dL to 12.0 g/dL for women";
    } else if (gender.toLowerCase() == "male" &&
        10 <= hemoglobinLevel &&
        hemoglobinLevel < 14) {
      return "Mild : 10.0 g/dL to 14.0 g/dL for men";
    } else if (gender.toLowerCase() == "female" &&
        12 <= hemoglobinLevel &&
        hemoglobinLevel <= 16) {
      return "Normal : 12.0 g/dL to 16.0 g/dL for women";
    } else if (gender.toLowerCase() == "male" &&
        14 <= hemoglobinLevel &&
        hemoglobinLevel <= 18) {
      return "Normal : 14.0 g/dL to 18.0 g/dL for women";
    } else {
      return "Above 18";
    }
  }

  void _getData() async {
    try {
      setState(() {
        isSendingData = true;
      });

      // Sending the custom message with "get-data" and age
      String message = "get-data";
      connection!.output.add(Uint8List.fromList(utf8.encode(message)));
      await connection!.output.allSent;
    } catch (e) {
      print("Failed to send message: $e");
    } finally {
      setState(() {
        isSendingData = false;
      });
    }
  }

  void _saveData() async {
    try {
      // Prepare the JSON payload
      final String ip = '$SERVER_IP/save-hp'; // API endpoint

      // Get current date and time
      final now = DateTime.now();

      // Format time to HH:MM
      String formattedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Format date to DD/MM/YYYY
      String formattedDate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

      // Prepare hp_data
      final Map<String, dynamic> hpData = {
        'time': formattedTime, // Only HH:MM format
        'date': formattedDate, // DD/MM/YYYY format
        'hp_value':
            hp_value, // double.tryParse(anemiaGrade.split(' ')[0]) ?? 0.0, // Extracting hemoglobin value
        'grade': anemiaGrade,
      };

      String? phoneNumber =
          Provider.of<GlobalState>(context, listen: false).phoneNumber;

      // print(phoneNumber);

      final Map<String, dynamic> postData = {
        'phone_number': phoneNumber,
        'hp_data': hpData, // Send hp_data directly
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse(ip),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      // Check the response
      if (response.statusCode == 200) {
        // Handle success
        print('Data saved successfully: ${response.body}');
        // Optionally show a success message to the user
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data saved successfully!'),
        ));
      } else {
        // Handle error
        print('Failed to save data: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save data!'),
        ));
      }
    } catch (e) {
      print("Error while saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error while saving data!'),
      ));
    }
  }

  void _clearData() {
    setState(() {
      messages.clear();
      anemiaGrade = ''; // Clear the displayed anemia grade
    });
  }
}
