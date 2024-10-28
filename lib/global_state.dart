import 'package:flutter/material.dart';

class GlobalState with ChangeNotifier {
  String? _phoneNumber;

  String? get phoneNumber => _phoneNumber;

  void setPhoneNumber(String? phoneNumber) {
    _phoneNumber = phoneNumber;
    notifyListeners();
  }
}
