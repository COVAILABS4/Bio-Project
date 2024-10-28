import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider for state management
import 'screens/dashboard.dart';
import 'global_state.dart'; // Import the global state file

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GlobalState(), // Provide the GlobalState
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch:
            Colors.blue, // Set the primary color to blue or any color you like
        scaffoldBackgroundColor: Colors.white, // Set background color to white
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // AppBar background color
          foregroundColor: Colors.black, // AppBar text color
        ),
        // You can add more theme customizations here if needed
      ),
      home: SafeArea(child: DashboardScreen()),
    );
  }
}
