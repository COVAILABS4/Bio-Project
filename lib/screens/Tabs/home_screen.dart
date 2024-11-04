import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heal_anemia/constants.dart';
import 'dart:math';
import 'package:heal_anemia/global_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String greetingMessage = '';
  String userName = '';
  String randomTip = '';
  String randomFoodSuggestion = '';

 

  // Animation Controllers
  late AnimationController _controller;
  late Animation<Offset> _greetingOffset;
  late Animation<Offset> _cardOffset1;
  late Animation<Offset> _cardOffset2;
  late String period;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    updateGreeting();

    // Initialize Animation Controller
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _greetingOffset = Tween<Offset>(
      begin: const Offset(0, -3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _cardOffset1 = Tween<Offset>(
      begin: const Offset(-2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _cardOffset2 = Tween<Offset>(
      begin: const Offset(2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {


     SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString('phone_number');
    
    print(phoneNumber);


    Provider.of<GlobalState>(context, listen: false)
        .setPhoneNumber(phoneNumber);



    final response = await http
        .get(Uri.parse('$SERVER_IP/get-data?phone_number=$phoneNumber'));
       

    if (response.statusCode == 200) {
      setState(() {
        var userData = jsonDecode(response.body);
        userName = userData['userData']['name'];
      });
    } else {
      setState(() {
        userName = "Guest";
      });
    }
  }

  void updateGreeting() {
    var hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      period = 'morning';
      greetingMessage = "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      period = 'afternoon';
      greetingMessage = "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      period = 'evening';
      greetingMessage = "Good Evening";
    } else {
      period = 'night';
      greetingMessage = "Good Night";
    }

    randomTip = getRandomFromList(tipsAndFood[period]!['tips']!);
    randomFoodSuggestion = getRandomFromList(tipsAndFood[period]!['foods']!);
  }

  String getRandomFromList(List<String> items) {
    final random = Random();
    return items[random.nextInt(items.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SlideTransition(
                  position: _greetingOffset,
                  child: Text(
                    '$greetingMessage, $userName!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SlideTransition(
                  position: _cardOffset1,
                  child:
                      _buildAnimatedCard("💡 Health Tip of the Day", randomTip),
                ),
                const SizedBox(height: 20),
                SlideTransition(
                  position: _cardOffset2,
                  child: _buildAnimatedCard(
                      "🍴 Food Suggestion", randomFoodSuggestion),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(String title, String content) {
    return AnimatedTextCard(
      title: title,
      content: content,
      period: period,
    );
  }
}

class AnimatedTextCard extends StatefulWidget {
  String title = "";
  String content = "";
  String period = "";
  // final

  AnimatedTextCard(
      {required this.title, required this.content, required this.period});

  @override
  _AnimatedTextCardState createState() => _AnimatedTextCardState();
}

class _AnimatedTextCardState extends State<AnimatedTextCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _textController;
  late int _currentCharIndex = 0;
  String _displayedText = '';
  Timer? _timer;

  String getRandomFromList(List<String> items) {
    final random = Random();
    return items[random.nextInt(items.length)];
  }

  void updateEach() {
    if (widget.title.contains("Health")) {
      widget.content = getRandomFromList(tipsAndFood[widget.period]!['tips']!);
      // randomFoodSuggestion = getRandomFromList(tipsAndFood[period]!['foods']!);
    } else {
      widget.content = getRandomFromList(tipsAndFood[widget.period]!['foods']!);
    }
  }

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startTextAnimation();
  }

  void _startTextAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_currentCharIndex < widget.content.length) {
          _displayedText = widget.content.substring(0, _currentCharIndex + 1);
          _currentCharIndex++;
        } else {
          _timer?.cancel();
          Future.delayed(const Duration(seconds: 3), () {
            _reverseTextAnimation();
          });
        }
      });
    });
  }

  void _reverseTextAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_currentCharIndex > 0) {
          _currentCharIndex--;
          _displayedText = widget.content.substring(0, _currentCharIndex);
        } else {
          _timer?.cancel();
          updateEach();
          _startTextAnimation();
        }
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(seconds: 2),
      opacity: 1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _displayedText,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
