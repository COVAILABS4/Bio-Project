import 'package:flutter/material.dart';
import 'package:heal_anemia/bluetooth_page/GlobalState.dart';
import 'package:heal_anemia/bluetooth_page/HomePage.dart';
import 'package:heal_anemia/global_state.dart';
import 'package:heal_anemia/screens/pages/register_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'Tabs/home_screen.dart';
import 'Tabs/hp_screen.dart';
import 'Tabs/profile_screen.dart';
import 'Tabs/notice_screen.dart';

import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // List of widgets for each tab
  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    HomePage(),
    ProfilePage(),
    NoticeScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


   Future<void> _requestPermissions() async {
    await [Permission.nearbyWifiDevices,Permission.location, Permission.microphone, Permission.storage , Permission.bluetooth,Permission.bluetoothAdvertise,Permission.bluetoothConnect,Permission.bluetoothScan].request();
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _requestPermissions();
  }

  // Check if the user is logged in
  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString('phone_number');
    String? dob = prefs.getString('dob');

    Provider.of<GlobalState>(context, listen: false)
        .setPhoneNumber(phoneNumber);

    if (phoneNumber == null || dob == null) {
      // If not logged in, navigate to Register Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegisterPage()),
      );
    }
  }

  // Logout function with confirmation dialog
  void _logout() async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Do you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Yes',
                  style: TextStyle(color: Colors.orangeAccent)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all saved data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegisterPage()),
      );
    }
  }

  Future<bool> _onWillPop() async {
    return false; // Prevents back navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.orangeAccent,
        automaticallyImplyLeading: false, // Hide the back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
            color: Colors.red,
          ),
        ],
      ),
      
      
      
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.battery_full),
            label: 'HB CALC',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notice',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
