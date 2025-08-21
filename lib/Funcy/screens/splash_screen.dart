import 'package:flutter/material.dart';
import 'chat_screen.dart';

class SplashScreen extends StatelessWidget {
  final int userId;
  final String username; // Agregar username

  SplashScreen({required this.userId, required this.username}); // Requerir username

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: userId,
            username: username, // Pasar username
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.network(
          'http://funkyrecursos.s3.us-east-2.amazonaws.com/assets/logo_funcy_splash.png',
          width: 160,
          height: 180,
        ),
      ),
    );
  }
}