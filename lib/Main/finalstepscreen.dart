import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:fnlapp/Main/home.dart';
import 'dart:convert';
import '../config.dart';

class FinalStepScreen extends StatefulWidget {
  final int userId;
  final int tecnicaId;
  final int sessionId;

  const FinalStepScreen({
    Key? key,
    required this.userId,
    required this.tecnicaId,
    required this.sessionId,
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

  // Helper method para obtener el tipo de dispositivo
  DeviceType _getDeviceType(double width) {
    if (width < 600) return DeviceType.mobile;
    if (width < 1024) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // Helper method para obtener dimensiones responsivas
  ResponsiveDimensions _getResponsiveDimensions(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceType = _getDeviceType(size.width);

    switch (deviceType) {
      case DeviceType.mobile:
        return ResponsiveDimensions(
          padding: 20.0,
          headerFontSize: 18.0,
          sectionSpacing: 32.0,
          starSize: 48.0,
          moodIconSize: 40.0,
          textFieldHeight: 4,
          buttonWidth: size.width * 0.8,
          buttonHeight: 56.0,
          maxContentWidth: size.width,
          topSpacing: 60.0,
          textFieldFontSize: 15.0,
          moodTextSize: 16.0,
        );
      case DeviceType.tablet:
        return ResponsiveDimensions(
          padding: 32.0,
          headerFontSize: 22.0,
          sectionSpacing: 40.0,
          starSize: 58.0,
          moodIconSize: 48.0,
          textFieldHeight: 5,
          buttonWidth: 300.0,
          buttonHeight: 64.0,
          maxContentWidth: size.width * 0.8,
          topSpacing: 80.0,
          textFieldFontSize: 17.0,
          moodTextSize: 18.0,
        );
      case DeviceType.desktop:
        return ResponsiveDimensions(
          padding: 40.0,
          headerFontSize: 24.0,
          sectionSpacing: 48.0,
          starSize: 68.0,
          moodIconSize: 56.0,
          textFieldHeight: 6,
          buttonWidth: 320.0,
          buttonHeight: 72.0,
          maxContentWidth: 600.0,
          topSpacing: 100.0,
          textFieldFontSize: 18.0,
          moodTextSize: 20.0,
        );
    }
  }

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
    final dimensions = _getResponsiveDimensions(context);
    final deviceType = _getDeviceType(MediaQuery.of(context).size.width);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: _buildBody(dimensions, deviceType),
    );
  }

  Widget _buildBody(ResponsiveDimensions dimensions, DeviceType deviceType) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
              'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/fondo_rese%C3%B1a.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: deviceType == DeviceType.desktop
              ? _buildDesktopLayout(dimensions)
              : _buildMobileTabletLayout(dimensions),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ResponsiveDimensions dimensions) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: dimensions.maxContentWidth),
        padding: EdgeInsets.all(dimensions.padding),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: dimensions.topSpacing),
                    _buildHeaderText(dimensions),
                    SizedBox(height: dimensions.sectionSpacing),
                    _buildRatingSection(dimensions),
                    SizedBox(height: dimensions.sectionSpacing),
                    _buildCommentSection(dimensions),
                    SizedBox(height: dimensions.sectionSpacing),
                    _buildMoodSection(dimensions),
                    SizedBox(height: dimensions.sectionSpacing * 0.75),
                    _buildFeedbackMessage(dimensions),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(dimensions),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabletLayout(ResponsiveDimensions dimensions) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dimensions.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.all(dimensions.padding),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: dimensions.topSpacing),
                      _buildHeaderText(dimensions),
                      SizedBox(height: dimensions.sectionSpacing),
                      _buildRatingSection(dimensions),
                      SizedBox(height: dimensions.sectionSpacing),
                      _buildCommentSection(dimensions),
                      SizedBox(height: dimensions.sectionSpacing),
                      _buildMoodSection(dimensions),
                      SizedBox(height: dimensions.sectionSpacing * 0.75),
                      _buildFeedbackMessage(dimensions),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(dimensions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(ResponsiveDimensions dimensions) {
    return Text(
      "Califica tu experiencia con la técnica de relajación de hoy que te ofreció Funcy",
      style: TextStyle(
        color: _textColor,
        fontSize: dimensions.headerFontSize,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRatingSection(ResponsiveDimensions dimensions) {
    return Column(
      children: [
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: dimensions.starSize,
          itemPadding:
              EdgeInsets.symmetric(horizontal: dimensions.starSize * 0.05),
          glowColor: _starColor.withOpacity(0.3),
          unratedColor: const Color(0xFFB7B7B7),
          itemBuilder: (context, index) => Icon(
            Icons.star_rounded,
            color: _starColor,
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

  Widget _buildCommentSection(ResponsiveDimensions dimensions) {
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
        maxLines: dimensions.textFieldHeight,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: "Deja un comentario sobre la técnica",
          hintStyle: TextStyle(
            color: const Color(0xFF909090),
            fontSize: dimensions.textFieldFontSize,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.all(dimensions.padding * 0.8),
        ),
        style: TextStyle(
          fontSize: dimensions.textFieldFontSize,
          fontFamily: 'Inter',
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildMoodSection(ResponsiveDimensions dimensions) {
    return Column(
      children: [
        Text(
          "¿Qué tan aliviado te sientes luego de la sesión de hoy?",
          style: TextStyle(
            color: _textColor,
            fontSize: dimensions.moodTextSize,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: dimensions.sectionSpacing * 0.6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: MoodLevel.values.map((mood) {
            final isSelected = _selectedMood == mood;
            return _buildMoodButton(mood, isSelected, dimensions);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodButton(
      MoodLevel mood, bool isSelected, ResponsiveDimensions dimensions) {
    final buttonSize = dimensions.moodIconSize + 16;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isSelected ? mood.color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          border: Border.all(
            color: isSelected ? mood.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          mood.icon,
          color: isSelected ? mood.color : Colors.white.withOpacity(0.6),
          size: dimensions.moodIconSize,
        ),
      ),
    );
  }

  Widget _buildFeedbackMessage(ResponsiveDimensions dimensions) {
    if (_feedbackMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(dimensions.padding * 0.8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _feedbackMessage,
        style: TextStyle(
          fontSize: dimensions.textFieldFontSize,
          color: _textColor,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubmitButton(ResponsiveDimensions dimensions) {
    return Padding(
      padding: EdgeInsets.only(
        top: dimensions.padding * 0.4,
        bottom: dimensions.padding * 2.5,
      ),
      child: SizedBox(
        width: dimensions.buttonWidth,
        height: dimensions.buttonHeight,
        child: ElevatedButton(
          onPressed: _isFormValid && !_isLoading ? _submitFeedback : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D4BD8),
            disabledBackgroundColor: const Color(0xFFD7D7D7),
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF868686),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: dimensions.buttonHeight * 0.4,
                  width: dimensions.buttonHeight * 0.4,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Enviar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dimensions.headerFontSize + 2,
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

// Enums y clases auxiliares para la responsividad
enum DeviceType { mobile, tablet, desktop }

class ResponsiveDimensions {
  final double padding;
  final double headerFontSize;
  final double sectionSpacing;
  final double starSize;
  final double moodIconSize;
  final int textFieldHeight;
  final double buttonWidth;
  final double buttonHeight;
  final double maxContentWidth;
  final double topSpacing;
  final double textFieldFontSize;
  final double moodTextSize;

  ResponsiveDimensions({
    required this.padding,
    required this.headerFontSize,
    required this.sectionSpacing,
    required this.starSize,
    required this.moodIconSize,
    required this.textFieldHeight,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.maxContentWidth,
    required this.topSpacing,
    required this.textFieldFontSize,
    required this.moodTextSize,
  });
}
