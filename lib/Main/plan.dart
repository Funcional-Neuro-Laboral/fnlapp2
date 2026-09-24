import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:fnlapp/Main/step_screen.dart';
import 'package:intl/intl.dart';
import 'package:fnlapp/Main/testestres_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Util/translations.dart';
import 'package:fnlapp/SplashScreen/welcome_screen.dart' show FuncyColors;

// Constantes
class AppConstants {
  static const int totalPrograms = 21;
  static const int percentageMultiplier = 1000;
  static const int percentageDivider = 10;
  static const double cardImageHeight = 150.0;
  static const double cardBorderRadius = 20.0;
  static const double progressBarHeight = 12.0;
  static const double maxContentWidth = 480.0;
}

// Colores del tema
class AppColors {
  static const Color primary = FuncyColors.primary;
  static const Color secondary = FuncyColors.primaryLight;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color cardBackground = Colors.white;
  static const Color lockedBackground = Color(0xFFFAF9FD);
  static const Color badgeBackground = Color(0xFFDCD4F6);
  static const Color badgeText = Color(0xFF10082A);
  static const Color progressBackground = Color(0xFFEFEAF8);
  static const Color progressGradientStart = FuncyColors.primaryLight;
  static const Color progressGradientEnd = FuncyColors.primary;
}

// Modelo de datos
class Programa {
  final String? startDate;
  final String? completedDate;
  final String nombreTecnica;
  final String tipoTecnica;
  final String? descripcion;
  final String? urlImg;
  final int dia;
  final int userId;
  final int id;
  final int sessionId;
  final dynamic guia;
  final dynamic ttsUrls; // URLs de audio TTS (relación por índice con guia)
  final bool unlocked;

  Programa({
    this.startDate,
    this.completedDate,
    required this.nombreTecnica,
    required this.tipoTecnica,
    this.descripcion,
    this.urlImg,
    required this.dia,
    required this.userId,
    required this.id,
    required this.sessionId,
    this.guia,
    this.ttsUrls,
    this.unlocked = false,
  });

  factory Programa.fromMap(Map<String, dynamic> map) {
    return Programa(
      startDate: map['start_date'],
      completedDate: map['completed_date'],
      nombreTecnica: map['nombre_tecnica'] ?? 'Sin nombre',
      tipoTecnica: map['tipo_tecnica'] ?? "Sin tipo",
      descripcion: map['descripcion'],
      urlImg: map['url_img'],
      dia: int.tryParse(map['dia'].toString()) ?? 0,
      userId: int.tryParse(map['user_id'].toString()) ?? 0,
      id: int.tryParse(map['id'].toString()) ?? 0,
      sessionId:
          int.tryParse(map['session_id'].toString()) ?? 0, // Parsear sessionId
      guia: map['guia'],
      ttsUrls: map['tts_urls'] ?? map['ttsUrls'],
      unlocked: map['unlocked'] ?? false,
    );
  }

  bool get isUnlocked {
    if (!unlocked) return false;

    if (startDate != null) {
      DateTime temp = DateTime.parse(startDate!).toLocal();
      DateTime date = DateTime(temp.year, temp.month, temp.day);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      return today.isAtSameMomentAs(date) || today.isAfter(date);
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

  List<String> get parsedTtsUrls {
    try {
      dynamic raw = ttsUrls;
      if (raw is String) {
        if (raw.trim().isEmpty) return [];
        raw = json.decode(raw);
      }
      if (raw is List) {
        return raw.map((e) => e == null ? '' : e.toString().trim()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing tts_urls: $e');
      return [];
    }
  }

  String get formattedStartDate {
    if (startDate == null) return '';
    return DateFormat('dd/MM/yyyy')
        .format(DateTime.parse(startDate!).toLocal());
  }
}

class PlanScreen extends StatefulWidget {
  final NivelEstres nivelEstres;
  final bool isLoading;
  final List<dynamic> programas;
  final bool showExitTestModal;

  const PlanScreen({
    Key? key,
    required this.nivelEstres,
    required this.isLoading,
    required this.programas,
    this.showExitTestModal = false,
  }) : super(key: key);

  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _hasShownModal = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowModal();
  }

  @override
  void didUpdateWidget(PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el estado del test de salida, verificar si mostrar el modal
    if (widget.showExitTestModal && !oldWidget.showExitTestModal) {
      _checkAndShowModal();
    }
  }

  Future<void> _checkAndShowModal() async {
    if (!widget.showExitTestModal) return;

    // Verificar si ya se mostró el modal anteriormente
    final prefs = await SharedPreferences.getInstance();
    final hasShownExitTestModal =
        prefs.getBool('hasShownExitTestModal') ?? false;

    if (!hasShownExitTestModal && !_hasShownModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showExitTestModal();
        _hasShownModal = true;
      });
    }
  }

  void _showExitTestModal() async {
    // Marcar que el modal ya se mostró
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownExitTestModal', true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isTablet = screenSize.width > 600;
        final isMobile = screenSize.width <= 600;

        // Configuración responsive
        final modalWidth = isTablet
            ? screenSize.width * 0.5 // 50% en tablet
            : screenSize.width * 0.85; // 85% en móvil

        final maxWidth = isTablet ? 500.0 : 350.0;
        final padding = isTablet ? 32.0 : 24.0;
        final iconSize = isTablet ? 56.0 : 48.0;
        final titleFontSize = isTablet ? 28.0 : 24.0;
        final bodyFontSize = isTablet ? 18.0 : 16.0;
        final buttonFontSize = isTablet ? 18.0 : 16.0;
        final buttonPadding = isTablet
            ? const EdgeInsets.symmetric(horizontal: 32, vertical: 20)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: modalWidth,
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: screenSize.height * 0.7,
            ),
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '¡Felicidades!',
                              style: TextStyle(
                                color: const Color(0xFF212121),
                                fontSize: titleFontSize,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      Text(
                        'Completaste el programa con éxito, ahora puedes realizar tu test de salida para terminar tu fase.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF212121),
                          fontSize: bodyFontSize,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: isTablet ? 32 : 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(); 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TestEstresQuestionScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 280 : 240,
                          ),
                          padding: buttonPadding,
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                FuncyColors.primary,
                                FuncyColors.primaryDark,
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            shadows: [
                              BoxShadow(
                                color: FuncyColors.primary.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Test de salida',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: buttonFontSize,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón de cerrar 
                Positioned(
                  top: isTablet ? -16 : -12,
                  right: isTablet ? -16 : -12,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 12 : 8),
                      child: Icon(
                        Icons.close,
                        color: const Color(0xFF212121),
                        size: isTablet ? 28 : 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Programa> get _parsedProgramas {
    return widget.programas
        .where((p) =>
            p['nombre_tecnica'] != null && p['nombre_tecnica'].isNotEmpty)
        .map((p) => Programa.fromMap(p))
        .toList();
  }

  double get _progressPercentage {
    if (widget.programas.isEmpty) return 0;

    final completedCount =
        widget.programas.where((x) => x['completed_date'] != null).length;

    return ((completedCount /
                AppConstants.totalPrograms *
                AppConstants.percentageMultiplier)
            .round() /
        AppConstants.percentageDivider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mismo lenguaje visual del login
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FuncyColors.primaryDark,
                  FuncyColors.primary,
                  FuncyColors.primaryLight,
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: _decorativeCircle(220, Colors.white.withOpacity(0.06)),
          ),
          Positioned(
            top: 220,
            left: -80,
            child: _decorativeCircle(170, Colors.white.withOpacity(0.05)),
          ),

          SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 130.0),
                  child: SingleChildScrollView(
                    child: Center(
                      // limita el ancho de todo el contenido
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppConstants.maxContentWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 18),
                              _buildProgressSection(context),
                              const SizedBox(height: 22),
                              _buildContent(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FUNCY · TU RUTA DE 21 DÍAS',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.72),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mi Plan Diario',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    if (widget.isLoading || widget.programas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: FuncyColors.primaryDark.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressHeader(),
          const SizedBox(height: 14),
          _buildProgressBar(context),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Tu progreso",
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "${_progressPercentage}%",
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppConstants.progressBarHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.progressBackground,
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: (_progressPercentage / 100).clamp(0.0, 1.0),
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
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (widget.programas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'No hay programas disponibles',
          style: GoogleFonts.inter(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.85),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: programa.isUnlocked
          ? _buildUnlockedCard(programa, context)
          : _buildLockedCard(programa, context),
    );
  }

  Widget _buildUnlockedCard(Programa programa, BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToStepScreen(programa, context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 3.0),
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

  Widget _buildLockedCard(Programa programa, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 3.0),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      boxShadow: [
        BoxShadow(
          color: FuncyColors.primaryDark.withOpacity(0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildCardImage(Programa programa, bool isUnlocked) {
    const String lockedImageUrl =
        'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/imagen_bloqueada.png';

    // Función para generar URL de imagen por día
    String getImageUrl() {
      if (!isUnlocked) return lockedImageUrl;

      /*// Si ya tiene una URL específica en la base de datos, usarla
      if (programa.urlImg != null && programa.urlImg!.isNotEmpty) {
        return programa.urlImg!;
      }*/

      // Mapeo temporal para los 21 días
      if (programa.dia >= 1 && programa.dia <= 21) {
        return 'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/recursos_nuevos2/DIA${programa.dia}.png';
      }

      return '';
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppConstants.cardBorderRadius),
        topRight: Radius.circular(AppConstants.cardBorderRadius),
      ),
      child: Image.network(
        getImageUrl(),
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
        color:
            isUnlocked ? AppColors.cardBackground : AppColors.lockedBackground,
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
        _buildProgramInfo(programa),
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

  Widget _buildProgramInfo(Programa programa) {
    return Row(
      children: [
        Text(
          traducirTipoTecnica(programa.tipoTecnica),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 8),
        const _DotSeparator(),
        const SizedBox(width: 8),
        const Text(
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
          ttsUrls: programa.parsedTtsUrls,
          tecnicaNombre: programa.nombreTecnica,
          tecnicaTipo: programa.tipoTecnica,
          dia: programa.dia,
          userId: programa.userId,
          tecnicaId: programa.id,
          url_img: programa.urlImg ?? '',
          sessionId: programa.id, // Usar id como sessionId
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