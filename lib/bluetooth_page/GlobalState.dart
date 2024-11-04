import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class GlobalState14 with ChangeNotifier {
  bool _isConnected = false;
  String _bluetoothID = '';
  String _deviceName = '';
  String _deviceAddress = '';
  BluetoothConnection? _connection; // Change this line to make the connection nullable

  bool get isConnected => _isConnected;
  String get bluetoothID => _bluetoothID;
  String get deviceName => _deviceName;
  String get deviceAddress => _deviceAddress;
  BluetoothConnection? get connection => _connection; // Update the getter to return a nullable connection

  void setBluetoothConnection(bool connected, String id, String name, String address, BluetoothConnection? connection) { // Update this method to accept a nullable connection
    _isConnected = connected;
    _bluetoothID = id;
    _deviceName = name;
    _deviceAddress = address;
    _connection = connection;
    notifyListeners();
  }
}
