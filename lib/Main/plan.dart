import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:fnlapp/Main/step_screen.dart';
import 'package:intl/intl.dart';

// Constantes
class AppConstants {
  static const int totalPrograms = 21;
  static const int percentageMultiplier = 1000;
  static const int percentageDivider = 10;
  static const double cardImageHeight = 150.0;
  static const double cardBorderRadius = 12.0;
  static const double progressBarHeight = 12.0;
}

// Colores del tema
class AppColors {
  static const Color primary = Color(0xFF6F3EA2);
  static const Color secondary = Color(0xFF8A6FE0);
  static const Color background = Color(0xFFF6F6F6);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color cardBackground = Colors.white;
  static const Color lockedBackground = Color(0xFFFFFFFF);
  static const Color badgeBackground = Color(0xFFDCD4F6);
  static const Color badgeText = Color(0xFF10082A);
  static const Color progressBackground = Color(0xFFEFEFEF);
  static const Color progressGradientStart = Color(0xFFDCD4F6);
  static const Color progressGradientEnd = Color(0xFF8A6FE0);
}

// Modelo de datos
class Programa {
  final String? startDate;
  final String? completedDate;
  final String nombreTecnica;
  final String? descripcion;
  final String? urlImg;
  final int dia;
  final int userId;
  final int id;
  final dynamic guia;

  Programa({
    this.startDate,
    this.completedDate,
    required this.nombreTecnica,
    this.descripcion,
    this.urlImg,
    required this.dia,
    required this.userId,
    required this.id,
    this.guia,
  });

  factory Programa.fromMap(Map<String, dynamic> map) {
    return Programa(
      startDate: map['start_date'],
      completedDate: map['completed_date'],
      nombreTecnica: map['nombre_tecnica'] ?? 'Sin nombre',
      descripcion: map['descripcion'],
      urlImg: map['url_img'],
      dia: int.tryParse(map['dia'].toString()) ?? 0,
      userId: int.tryParse(map['user_id'].toString()) ?? 0,
      id: int.tryParse(map['id'].toString()) ?? 0,
      guia: map['guia'],
    );
  }

  bool get isUnlocked {
    if (startDate != null) {
      DateTime temp = DateTime.parse(startDate!).toLocal();
      DateTime date = DateTime(temp.year, temp.month, temp.day);
      return DateTime.now().isAfter(date);
    }
    return false;
  }

  List<String> get parsedSteps {
    try {
      if (guia is String) {
        return List<String>.from(json.decode(guia));
      } else if (guia is List) {
        return List<String>.from(guia);
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing steps: $e');
      return [];
    }
  }

  String get formattedStartDate {
    if (startDate == null) return '';
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(startDate!).toLocal());
  }
}

class PlanScreen extends StatelessWidget {
  final NivelEstres nivelEstres;
  final bool isLoading;
  final List<dynamic> programas;

  const PlanScreen({
    Key? key,
    required this.nivelEstres,
    required this.isLoading,
    required this.programas,
  }) : super(key: key);

  List<Programa> get _parsedProgramas {
    return programas
        .where((p) => p['nombre_tecnica'] != null && p['nombre_tecnica'].isNotEmpty)
        .map((p) => Programa.fromMap(p))
        .toList();
  }

  double get _progressPercentage {
    if (programas.isEmpty) return 0;

    final completedCount = programas
        .where((x) => x['completed_date'] != null)
        .length;

    return ((completedCount / AppConstants.totalPrograms *
        AppConstants.percentageMultiplier).round() /
        AppConstants.percentageDivider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 130.0),
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 20.0
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildProgressSection(context),
                      const SizedBox(height: 20),
                      _buildContent(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Mi Plan Diario',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    if (isLoading || programas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressHeader(),
        const SizedBox(height: 16),
        _buildProgressBar(context),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Tu progreso",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "${_progressPercentage}%",
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        height: AppConstants.progressBarHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.progressBackground,
        ),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: AppConstants.progressBarHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.progressBackground,
              ),
            ),
            FractionallySizedBox(
              widthFactor: _progressPercentage / 100,
              child: Container(
                height: AppConstants.progressBarHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.progressGradientStart,
                      AppColors.progressGradientEnd,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      );
    }

    if (programas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'No hay programas disponibles',
          style: GoogleFonts.poppins(
            fontSize: 16.0,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return _buildProgramsList(context);
  }

  Widget _buildProgramsList(BuildContext context) {
    final parsedProgramas = _parsedProgramas;

    return Column(
      children: parsedProgramas
          .map((programa) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: _buildProgramCard(programa, context),
      ))
          .toList(),
    );
  }

  Widget _buildProgramCard(Programa programa, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.9;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: programa.isUnlocked
          ? _buildUnlockedCard(programa, context, cardWidth)
          : _buildLockedCard(programa, context, cardWidth),
    );
  }

  Widget _buildUnlockedCard(Programa programa, BuildContext context, double cardWidth) {
    return GestureDetector(
      onTap: () => _navigateToStepScreen(programa, context),
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
        decoration: _buildCardDecoration(),
        child: Stack(
          children: [
            Column(
              children: [
                _buildCardImage(programa, true),
                _buildCardContent(programa, true),
              ],
            ),
            _buildDayBadge(programa),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard(Programa programa, BuildContext context, double cardWidth) {
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          _buildCardImage(programa, false),
          _buildCardContent(programa, false),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 2,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildCardImage(Programa programa, bool isUnlocked) {

    const String lockedImageUrl = 'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/imagen_bloqueada.png'; // Imagen de bloqueo

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppConstants.cardBorderRadius),
        topRight: Radius.circular(AppConstants.cardBorderRadius),
      ),
      child: Image.network(
        isUnlocked ? (programa.urlImg ?? '') : lockedImageUrl,
        width: double.infinity,
        height: AppConstants.cardImageHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: AppConstants.cardImageHeight,
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.grey[300] : Colors.grey[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.cardBorderRadius),
                topRight: Radius.circular(AppConstants.cardBorderRadius),
              ),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
              size: 50,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(Programa programa, bool isUnlocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.cardBackground : AppColors.lockedBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.cardBorderRadius),
          bottomRight: Radius.circular(AppConstants.cardBorderRadius),
        ),
      ),
      child: isUnlocked
          ? _buildUnlockedContent(programa)
          : _buildLockedContent(programa),
    );
  }

  Widget _buildUnlockedContent(Programa programa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          programa.nombreTecnica,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          programa.descripcion ?? '',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.31,
          ),
        ),
        const SizedBox(height: 8),
        _buildProgramInfo(),
      ],
    );
  }

  Widget _buildLockedContent(Programa programa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          programa.nombreTecnica,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          programa.startDate == null
              ? 'Esta lección se desbloqueará al día siguiente de haber completado la anterior.'
              : 'Esta lección se desbloqueará el ${programa.formattedStartDate}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.31,
          ),
        ),
      ],
    );
  }

  Widget _buildProgramInfo() { //Futuro usar value
    return Row(
      children: const [
        Text(
          'Relajación guiada',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(width: 8),
        _DotSeparator(),
        SizedBox(width: 8),
        Text(
          '5 - 10 min',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDayBadge(Programa programa) {
    return Positioned(
      top: 13,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const ShapeDecoration(
          color: AppColors.badgeBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: AppColors.badgeText,
            ),
            const SizedBox(width: 4),
            Text(
              'Día ${programa.dia.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.badgeText,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStepScreen(Programa programa, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StepScreen(
          steps: programa.parsedSteps,
          tecnicaNombre: programa.nombreTecnica,
          dia: programa.dia,
          userId: programa.userId,
          tecnicaId: programa.id,
          url_img: programa.urlImg ?? '',
        ),
      ),
    );
  }
}

// Widget helper para el separador de puntos
class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const ShapeDecoration(
        color: Color(0xFFC6C6C6),
        shape: OvalBorder(),
      ),
    );
  }
}