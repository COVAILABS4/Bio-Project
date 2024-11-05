import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:heal_anemia/global_state.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'DeviceConnectionPage.dart';
import 'ChatPage.dart';
import 'package:open_settings_plus/open_settings_plus.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  bool _isBluetoothOn = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    // Request permissions for Bluetooth if not granted
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request();

    // Check if Bluetooth is enabled
    bool isBluetoothOn = await _bluetooth.isEnabled as bool;
    setState(() {
      _isBluetoothOn = isBluetoothOn;
    });

    // Listen to Bluetooth state changes
    _bluetooth.onStateChanged().listen((state) {
      setState(() {
        _isBluetoothOn = state == BluetoothState.STATE_BLE_TURNING_ON;
      });
    });
  }

  Future<void> _openBluetoothSettings() async {
    await OpenSettingsPlusAndroid()
        .bluetooth(); // Opens the app's Bluetooth settings
  }

  @override
  Widget build(BuildContext context) {
    return _isBluetoothOn
        ? Consumer<GlobalState>(
            builder: (context, globalState, child) => Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false, // Hide the back button
                title: Text(
                  'BLE Terminal',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                backgroundColor: Colors.blueGrey[800],
                actions: [
                  IconButton(
                    icon: Icon(
                      globalState.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: globalState.isConnected
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      size: 28,
                    ),
                    onPressed: () {
                      if (!globalState.isConnected) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return DeviceConnectionDialog();
                          },
                        );
                      } else {
                        globalState.setBluetoothConnection(
                            false, '', '', '', null);
                      }
                    },
                  ),
                ],
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: globalState.isConnected
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueGrey.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      "Connected to:",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.blueGrey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "${globalState.deviceName}",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey[900],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "MAC Address: ${globalState.deviceAddress}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Text(
                              "Please connect to the device.",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey[700]),
                            ),
                          ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 5,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: globalState.isConnected
                          ? ChatPage()
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bluetooth_disabled,
                                      color: Colors.redAccent, size: 50),
                                  SizedBox(height: 10),
                                  Text(
                                    "No device connected.",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text('BLE Terminal'),
              backgroundColor: Colors.blueGrey[800],
              automaticallyImplyLeading: false, // Hide the back button
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                // Re-check Bluetooth status
                bool isBluetoothOn = await _bluetooth.isEnabled as bool;

                // Optionally, you can reload the list of available devices or refresh other states as needed

                setState(() {
                  _isBluetoothOn = isBluetoothOn;
                  // Add any other state updates if needed, such as fetching device list, etc.
                });
              },
              child: Icon(Icons.refresh),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Bluetooth is off. Please enable it to proceed.",
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _openBluetoothSettings,
                    child: Text("Open Bluetooth Settings"),
                  ),
                ],
              ),
            ),
          );
  }
}
