// screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:heal_anemia/constants.dart';
import 'package:video_player/video_player.dart';
import 'dashboard.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize the video player controller
    _controller = VideoPlayerController.asset(VIDEO_PATH)
      ..initialize().then((_) {
        // Ensure the video is loaded before starting playback
        setState(() {});
        _controller.play(); // Start playing the video automatically
      });

    // Listen for when the video ends
    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        _navigateToDashboard(); // Navigate to the main dashboard when video ends
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(), // Show loading spinner until video is ready
      ),
    );
  }
}
