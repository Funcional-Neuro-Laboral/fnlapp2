import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:fnlapp/Main/home.dart';
import 'dart:convert';
import '../config.dart';

class FinalStepScreen extends StatefulWidget {
  final int userId;
  final int tecnicaId;

  FinalStepScreen({required this.userId, required this.tecnicaId});

  @override
  _FinalStepScreenState createState() => _FinalStepScreenState();
}

class _FinalStepScreenState extends State<FinalStepScreen> {
  final TextEditingController commentController = TextEditingController();
  double _rating = 3;
  double _little_face = 3;
  bool _isButtonEnabled = false;
  String _feedbackMessage = '';

  void _checkInput() {
    setState(() {
      _isButtonEnabled = commentController.text.isNotEmpty && _rating > 0;
    });
  }

  Future<void> _sendData() async {

    int caritaValue = 2; // Valor por defecto, carita feliz
    if (_little_face == 1) {
      caritaValue = 1; // Carita triste
    } else if (_little_face == 3) {
      caritaValue = 3; // Carita neutra
    }

    final String apiUrl =
        "${Config.apiUrl}/userprograma/${widget.userId}/${widget.tecnicaId}";

    final Map<String, dynamic> data = {
      "comentario": commentController.text,
      "estrellas": _rating.toInt(),
      "caritas": caritaValue,
    };

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        setState(() {
          _feedbackMessage = 'Comentario y calificación enviados exitosamente';
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          _feedbackMessage = 'Error al enviar los datos: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Error de red: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B158D),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Final de la técnica',
          style: TextStyle(fontSize: 16.0, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/login.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.03),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Califica tu experiencia con la técnica de relajación de hoy que te ofreció Funcy",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  RatingBar.builder(
                    initialRating: 3,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                    unratedColor: Colors.blueGrey,
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                        _checkInput();
                      });
                    },
                  ),
                  

                  SizedBox(height: screenHeight * 0.04),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Deja un comentario sobre la técnica",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _checkInput();
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: _isButtonEnabled ? _sendData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B158D),
                      disabledBackgroundColor: const Color(0xFFE3DCE4),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.2,
                        vertical: screenHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                    ),
                    child: Text(
                      'Enviar',
                      style: TextStyle(fontSize: screenWidth * 0.045),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.09),
                  Text(
                    "¿Qué tan aliviado te sientes luego de la sesión de hoy?",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[300],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02), // Espaciado entre la pregunta y las caritas
                  Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _little_face = 1; // Calificación para la carita triste
                          _checkInput();
                        });
                      },
                      child: Icon(
                        Icons.sentiment_very_dissatisfied, // Carita triste
                        color: _little_face == 1 ? Colors.red : Colors.grey,
                        size: screenWidth * 0.12, // Ajusta el tamaño de las caritas
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.07),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _little_face = 2; // Calificación para la carita neutra
                          _checkInput();
                        });
                      },
                      child: Icon(
                        Icons.sentiment_neutral, // Carita neutra
                        color: _little_face == 2 ? Colors.yellow : Colors.grey,
                        size: screenWidth * 0.12,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.07),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _little_face = 3; // Calificación para la carita feliz
                          _checkInput();
                        });
                      },
                      child: Icon(
                        Icons.sentiment_very_satisfied, // Carita feliz
                        color: _little_face == 3 ? Colors.green : Colors.grey,
                        size: screenWidth * 0.12,
                      ),
                    ),
                  ],
                ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    _feedbackMessage,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
