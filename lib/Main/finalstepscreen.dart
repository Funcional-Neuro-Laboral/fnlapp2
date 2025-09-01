import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:fnlapp/Main/home.dart';
import 'dart:convert';
import '../config.dart';

class FinalStepScreen extends StatefulWidget {
  final int userId;
  final int tecnicaId;
  final int sessionId; // Nuevo: session_id

  const FinalStepScreen({
    Key? key,
    required this.userId,
    required this.tecnicaId,
    required this.sessionId, // Agregar sessionId
  }) : super(key: key);

  @override
  State<FinalStepScreen> createState() => _FinalStepScreenState();
}

class _FinalStepScreenState extends State<FinalStepScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  double _rating = 3.0;
  MoodLevel _selectedMood = MoodLevel.neutral;
  bool _isLoading = false;
  String _feedbackMessage = '';

  // Colores del tema
  static const Color _primaryColor = Color(0xFF4B158D);
  static const Color _backgroundOverlay = Color(0xFF2D0A4E);
  static const Color _textColor = Color(0xFFF6F6F6);
  static const Color _starColor = Color(0xFFF1D93E);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _commentController.text.trim().isNotEmpty && _rating > 0;

  Future<void> _submitFeedback() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _feedbackMessage = '';
    });

    try {
      await _sendFeedbackToServer();
      _showSuccessAndNavigate();
    } catch (e) {
      _showErrorMessage('Error de conexión: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendFeedbackToServer() async {
    // Nuevo endpoint con sessionId y userId
    final String apiUrl =
        "${Config.apiUrl2}/programs/sessions/${widget.sessionId}/complete/${widget.userId}";

    final Map<String, dynamic> requestData = {
      "comentario": _commentController.text.trim(),
      "estrellas": _rating.toInt(),
      "caritas": _selectedMood.value,
    };

    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestData),
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  void _showSuccessAndNavigate() {
    setState(() {
      _feedbackMessage = 'Comentario enviado exitosamente';
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false,
        );
      }
    });
  }

  void _showErrorMessage(String message) {
    setState(() {
      _feedbackMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
              'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/fondo_rese%C3%B1a.png'
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 80),
                        _buildHeaderText(),
                        const SizedBox(height: 40),
                        _buildRatingSection(),
                        const SizedBox(height: 40),
                        _buildCommentSection(),
                        const SizedBox(height: 50),
                        _buildMoodSection(),
                        const SizedBox(height: 32),
                        _buildFeedbackMessage(),
                      ],
                    ),
                  ),
                ),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    return const Text(
      "Califica tu experiencia con la técnica de relajación de hoy que te ofreció Funcy",
      style: TextStyle(
        color: _textColor,
        fontSize: 18,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 64,
          itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
          glowColor: const Color(0xFFF1D93E).withOpacity(0.3),
          unratedColor: const Color(0xFFB7B7B7),
          itemBuilder: (context, index) => Icon(
            Icons.star_rounded,
            color: const Color(0xFFF1D93E),
          ),
          onRatingUpdate: (rating) {
            setState(() {
              _rating = rating;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 4,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: "Deja un comentario sobre la técnica",
          hintStyle: const TextStyle(
            color: Color(0xFF909090),
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'Inter',
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildMoodSection() {
    return Column(
      children: [
        const Text(
          "¿Qué tan aliviado te sientes luego de la sesión de hoy?",
          style: TextStyle(
            color: _textColor,
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: MoodLevel.values.map((mood) {
            final isSelected = _selectedMood == mood;
            return _buildMoodButton(mood, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodButton(MoodLevel mood, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? mood.color.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? mood.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          mood.icon,
          color: isSelected ? mood.color : Colors.white.withOpacity(0.6),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildFeedbackMessage() {
    if (_feedbackMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _feedbackMessage,
        style: const TextStyle(
          fontSize: 16,
          color: _textColor,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 64),
      child: SizedBox(
        width: 240,
        height: 56,
        child: ElevatedButton(
          onPressed: _isFormValid && !_isLoading ? _submitFeedback : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D4BD8),
            disabledBackgroundColor: const Color(0xFFD7D7D7),
            foregroundColor: Colors.white,
            disabledForegroundColor: Color(0xFF868686),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : const Text(
            'Enviar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

enum MoodLevel {
  sad(1, Icons.sentiment_very_dissatisfied, Colors.red),
  neutral(2, Icons.sentiment_neutral, Colors.amber),
  happy(3, Icons.sentiment_very_satisfied, Colors.green);

  const MoodLevel(this.value, this.icon, this.color);

  final int value;
  final IconData icon;
  final Color color;
}