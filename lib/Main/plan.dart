import 'package:flutter/material.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:fnlapp/Main/step_screen.dart';
import 'package:intl/intl.dart';
import 'package:fnlapp/Main/testestres_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Util/translations.dart';

// Constantes
class AppConstants {
  static const int totalPrograms = 21;
  static const int percentageMultiplier = 1000;
  static const int percentageDivider = 10;
  static const double cardImageHeight = 150.0;
  static const double cardBorderRadius = 24.0;
  static const double progressBarHeight = 14.0;
  static const double maxContentWidth = 480.0;
}

class AppColors {
  static const Color primary = Color(0xFF6428E8);
  static const Color secondary = Color(0xFF814CF4);
  static const Color textPrimary = Color(0xFF0B1457);
  static const Color textSecondary = Color(0xFF70779C);
  static const Color cardBackground = Colors.white;
  static const Color lockedBackground = Color(0xFFFCFBFF);
  static const Color badgeBackground = Color(0xFFF4F1FF);
  static const Color badgeText = Color(0xFF6428E8);
  static const Color progressBackground = Color(0xFFEAE4FC);
  static const Color progressGradientStart = Color(0xFF5425E8);
  static const Color progressGradientEnd = Color(0xFF814CF4);
}

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const gradientStart = Color(0xFF5425E8);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
  static const border = Color(0xFFD9DCEF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
}

class _FnlText {
  static TextStyle h1(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.2,
      );

  static TextStyle h2(double size, {Color color = _FnlColors.blue}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.25,
      );

  static TextStyle body({
    double size = 16,
    Color color = _FnlColors.body,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );

  static TextStyle label({
    double size = 14,
    Color color = _FnlColors.violet,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle button({Color color = _FnlColors.white}) =>
      GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );
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

  // Indica si el día ya fue completado
  bool get isCompleted =>
      completedDate != null && completedDate!.trim().isNotEmpty;

  bool get isUnlocked {
    if (!unlocked) return false;

    if (startDate != null) {
      // tryParse: una fecha mal formada ya no rompe toda la lista
      final parsed = DateTime.tryParse(startDate!);
      if (parsed == null) return false;

      DateTime temp = parsed.toLocal();
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
    final parsed = DateTime.tryParse(startDate!);
    if (parsed == null) return '';
    return DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }
}

class PlanScreen extends StatefulWidget {
  final NivelEstres nivelEstres;
  final bool isLoading;
  final List<dynamic> programas;
  final bool showExitTestModal;

  final Future<void> Function()? onRefresh;

  const PlanScreen({
    Key? key,
    required this.nivelEstres,
    required this.isLoading,
    required this.programas,
    this.showExitTestModal = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  static const String _baseUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/';
  static const String _funcyUrl = '${_baseUrl}funcy.png';
  static const String _happyUrl = '${_baseUrl}happy.png';

  static const double _bottomNavSpace = 130.0;

  bool _hasShownModal = false;
  bool _imagesPrecached = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowModal();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const NetworkImage(_funcyUrl), context);
      precacheImage(const NetworkImage(_happyUrl), context);
      _imagesPrecached = true;
    }
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
      _hasShownModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showExitTestModal();
      });
    }
  }

  Future<void> _handleRefresh() async {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null || _isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await onRefresh();
    } catch (e) {
      debugPrint('Error refreshing plan: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showExitTestModal() async {
    // Marcar que el modal ya se mostró
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownExitTestModal', true);

    if (!mounted) return;

    const double mascotHeight = 96;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: _FnlColors.blue.withOpacity(0.55),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
              horizontal: _FnlSpace.md, vertical: _FnlSpace.md),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: mascotHeight / 2),
                    padding: const EdgeInsets.fromLTRB(
                        _FnlSpace.md,
                        mascotHeight / 2 + _FnlSpace.sm,
                        _FnlSpace.md,
                        _FnlSpace.md),
                    decoration: BoxDecoration(
                      color: _FnlColors.white,
                      borderRadius: BorderRadius.circular(28),
                      border:
                          Border.all(color: _FnlColors.bubbleBorder, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: _FnlColors.bubbleBorder,
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '¡Felicidades!',
                            textAlign: TextAlign.center,
                            style: _FnlText.h2(24),
                          ),
                          const SizedBox(height: _FnlSpace.xs),
                          Text(
                            'Completaste el programa con éxito, ahora puedes realizar tu test de salida para terminar tu fase.',
                            textAlign: TextAlign.center,
                            style: _FnlText.body(),
                          ),
                          const SizedBox(height: _FnlSpace.md),
                          _PrimaryButton(
                            label: 'Test de salida',
                            icon: Icons.arrow_forward_rounded,
                            onTap: () {
                              Navigator.of(dialogContext).pop();
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TestEstresQuestionScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botón de cerrar
                  Positioned(
                    top: mascotHeight / 2 + 12,
                    right: 12,
                    child: Material(
                      color: _FnlColors.lavender,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: _FnlColors.violet,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: mascotHeight,
                    child: _buildMascot(_happyUrl, mascotHeight),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMascot(String url, double height) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: height * 0.7,
          height: height * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _FnlColors.violetSecondary.withOpacity(0.22),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        Image.network(
          url,
          height: height,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: height,
              width: height,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _FnlColors.violetSecondary,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => SizedBox(height: height, width: height),
        ),
      ],
    );
  }

  List<Programa> get _parsedProgramas {
    return widget.programas
        .where((p) => (p['nombre_tecnica']?.toString() ?? '').isNotEmpty)
        .map((p) => Programa.fromMap(p))
        .toList();
  }

  double get _progressPercentage {
    if (widget.programas.isEmpty) return 0;

    final completedCount = widget.programas.where((x) {
      final value = x['completed_date'];
      return value != null && value.toString().trim().isNotEmpty;
    }).length;

    return ((completedCount /
                AppConstants.totalPrograms *
                AppConstants.percentageMultiplier)
            .round() /
        AppConstants.percentageDivider);
  }

  String get _progressLabel {
    final v = _progressPercentage;
    return v == v.roundToDouble()
        ? '${v.toInt()}%'
        : '${v.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final titleSize = MediaQuery.of(context).size.width < 400 ? 28.0 : 34.0;

    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand, 
          children: [
            // Círculos decorativos
            const Positioned(
              top: -70,
              right: -70,
              child: IgnorePointer(child: _DecorCircle(size: 220)),
            ),
            const Positioned(
              bottom: -90,
              left: -90,
              child: IgnorePointer(child: _DecorCircle(size: 240)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  final availableHeight = (viewport.maxHeight - _bottomNavSpace)
                      .clamp(320.0, double.infinity);

                  final scroll = SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: _bottomNavSpace),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: availableHeight),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppConstants.maxContentWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: _FnlSpace.md,
                              vertical: _FnlSpace.md,
                            ),
                            child: _buildBody(titleSize, availableHeight),
                          ),
                        ),
                      ),
                    ),
                  );

                  if (widget.onRefresh == null) return scroll;

                  return RefreshIndicator(
                    color: _FnlColors.violet,
                    backgroundColor: _FnlColors.white,
                    onRefresh: _handleRefresh,
                    child: scroll,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double titleSize, double availableHeight) {
    final isListState = !widget.isLoading && widget.programas.isNotEmpty;

    if (isListState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(titleSize),
          const SizedBox(height: _FnlSpace.sm),
          _buildProgressSection(),
          const SizedBox(height: _FnlSpace.md),
          _buildProgramsList(),
        ],
      );
    }

    return SizedBox(
      height: availableHeight - (_FnlSpace.md * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(titleSize),
          Expanded(
            child: Center(
              child: widget.isLoading
                  ? _buildLoadingState()
                  : _buildEmptyState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double titleSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FUNCY · TU RUTA DE 21 DÍAS',
          style: _FnlText.label(size: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text('Mi Plan Diario', style: _FnlText.h1(titleSize)),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    if (widget.isLoading || widget.programas.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Tu progreso: $_progressLabel',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(_FnlSpace.md),
        decoration: BoxDecoration(
          color: _FnlColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
          boxShadow: const [
            BoxShadow(
              color: _FnlColors.bubbleBorder,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Tu progreso', style: _FnlText.h2(18)),
                Text(
                  _progressLabel,
                  style: _FnlText.h2(22, color: _FnlColors.violet),
                ),
              ],
            ),
            const SizedBox(height: _FnlSpace.sm),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final target = (_progressPercentage / 100).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      height: AppConstants.progressBarHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _FnlColors.lavenderDeep,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_FnlColors.gradientStart, _FnlColors.violetSecondary],
              ),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Semantics(
      label: 'Cargando tu plan',
      child: const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: _FnlColors.violet,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _FnlSpace.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingMascot(
            child: SizedBox(
              height: 140,
              child: _buildMascot(_funcyUrl, 140),
            ),
          ),
          const SizedBox(height: _FnlSpace.md),
          Semantics(
            header: true,
            child: Text(
              'Aún no tienes programas',
              textAlign: TextAlign.center,
              style: _FnlText.h2(20),
            ),
          ),
          const SizedBox(height: _FnlSpace.xs),
          Text(
            widget.onRefresh != null
                ? 'Tu ruta de 21 días aparecerá aquí en cuanto esté lista. Desliza hacia abajo o toca actualizar para revisar de nuevo.'
                : 'Tu ruta de 21 días aparecerá aquí en cuanto esté lista.',
            textAlign: TextAlign.center,
            style: _FnlText.body(size: 15),
          ),
          if (widget.onRefresh != null) ...[
            const SizedBox(height: _FnlSpace.md),
            SizedBox(
              width: 220,
              child: _PrimaryButton(
                label: _isRefreshing ? 'Actualizando...' : 'Actualizar',
                icon: _isRefreshing ? null : Icons.refresh_rounded,
                onTap: _isRefreshing ? null : _handleRefresh,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgramsList() {
    final parsedProgramas = _parsedProgramas;

    return Column(
      children: [
        for (final programa in parsedProgramas)
          Padding(
            padding: const EdgeInsets.only(bottom: _FnlSpace.sm),
            child: _buildProgramCard(programa),
          ),
      ],
    );
  }

  Widget _buildProgramCard(Programa programa) {
    return programa.isUnlocked
        ? _buildUnlockedCard(programa)
        : _buildLockedCard(programa);
  }

  BoxDecoration _buildCardDecoration({bool completed = false}) {
    return BoxDecoration(
      color: _FnlColors.white,
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      border: Border.all(
        color: completed ? _FnlColors.violet : _FnlColors.border,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: completed
              ? _FnlColors.violet.withOpacity(0.35)
              : _FnlColors.border,
          offset: Offset(0, completed ? 2 : 4),
          blurRadius: 0,
        ),
      ],
    );
  }

  Widget _buildUnlockedCard(Programa programa) {
    return Semantics(
      button: true,
      label: 'Día ${programa.dia}: ${programa.nombreTecnica}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _navigateToStepScreen(programa),
        child: Container(
          width: double.infinity,
          decoration: _buildCardDecoration(completed: programa.isCompleted),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AppConstants.cardBorderRadius - 2),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildCardImage(programa, true),
                    _buildCardContent(programa, true),
                  ],
                ),
                _buildDayBadge(programa),
                if (programa.isCompleted) _buildCompletedCheck(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedCard(Programa programa) {
    return Container(
      width: double.infinity,
      decoration: _buildCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius - 2),
        child: Stack(
          children: [
            Column(
              children: [
                _buildCardImage(programa, false),
                _buildCardContent(programa, false),
              ],
            ),
            _buildLockChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(Programa programa, bool isUnlocked) {
    const String lockedImageUrl =
        'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/recursos_nuevos2/locked.jpg';

    // Función para generar URL de imagen por día
    String getImageUrl() {
      if (!isUnlocked) return lockedImageUrl;

      /*// Si ya se tiene una URL específica en la base de datos, usarla
      if (programa.urlImg != null && programa.urlImg!.isNotEmpty) {
        return programa.urlImg!;
      }*/

      // Mapeo temporal para los 21 días
      if (programa.dia >= 1 && programa.dia <= 21) {
        return 'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/recursos_nuevos2/DIA${programa.dia}.jpg';
      }

      return '';
    }

    return SizedBox(
      width: double.infinity,
      height: AppConstants.cardImageHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            getImageUrl(),
            width: double.infinity,
            height: AppConstants.cardImageHeight,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: _FnlColors.lavender,
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _FnlColors.violetSecondary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: _FnlColors.lavender,
                child: Icon(
                  isUnlocked
                      ? Icons.image_not_supported_rounded
                      : Icons.lock_rounded,
                  color: _FnlColors.violetSecondary,
                  size: 48,
                ),
              );
            },
          ),
          // Sombreado violeta sobre la imagen de los días completados
          if (isUnlocked && programa.isCompleted)
            ColoredBox(color: _FnlColors.violet.withOpacity(0.28)),
        ],
      ),
    );
  }

  Widget _buildCardContent(Programa programa, bool isUnlocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_FnlSpace.sm),
      color: isUnlocked && programa.isCompleted
          ? _FnlColors.lavender
          : _FnlColors.white,
      child: isUnlocked
          ? _buildUnlockedContent(programa)
          : _buildLockedContent(programa),
    );
  }

  Widget _buildUnlockedContent(Programa programa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(programa.nombreTecnica, style: _FnlText.h2(16)),
        const SizedBox(height: 6),
        Text(
          programa.descripcion ?? '',
          style: _FnlText.body(size: 14),
        ),
        const SizedBox(height: 12),
        _buildProgramInfo(programa),
      ],
    );
  }

  Widget _buildLockedContent(Programa programa) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(programa.nombreTecnica, style: _FnlText.h2(16)),
        const SizedBox(height: 6),
        Text(
          programa.startDate == null
              ? 'Esta lección se desbloqueará al día siguiente de haber completado la anterior.'
              : 'Esta lección se desbloqueará el ${programa.formattedStartDate}',
          style: _FnlText.body(size: 14),
        ),
      ],
    );
  }

  Widget _buildProgramInfo(Programa programa) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          traducirTipoTecnica(programa.tipoTecnica),
          style: _FnlText.label(size: 13),
        ),
        const _DotSeparator(),
        const Icon(Icons.timer_outlined, size: 16, color: _FnlColors.body),
        Text('5 - 10 min', style: _FnlText.body(size: 13)),
      ],
    );
  }

  Widget _buildDayBadge(Programa programa) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _FnlColors.lavender,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: _FnlColors.violet,
            ),
            const SizedBox(width: 6),
            Text(
              'Día ${programa.dia.toString().padLeft(2, '0')}',
              style: _FnlText.label(),
            ),
          ],
        ),
      ),
    );
  }

  // Check circular en la esquina superior derecha de la imagen
  Widget _buildCompletedCheck() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _FnlColors.violet,
          shape: BoxShape.circle,
          border: Border.all(color: _FnlColors.white, width: 2),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 20,
          color: _FnlColors.white,
        ),
      ),
    );
  }

  // Candado para las lecciones bloqueadas
  Widget _buildLockChip() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _FnlColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
        ),
        child: const Icon(
          Icons.lock_rounded,
          size: 16,
          color: _FnlColors.body,
        ),
      ),
    );
  }

  void _navigateToStepScreen(Programa programa) {
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

class _DecorCircle extends StatelessWidget {
  final double size;
  const _DecorCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _FnlColors.lavenderDeep,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FloatingMascot extends StatefulWidget {
  final Widget child;
  const _FloatingMascot({required this.child});

  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -8 * _curve.value),
        child: child,
      ),
    );
  }
}

/// Separador de puntos.
class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: _FnlColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: enabled
              ? _FnlColors.violet
              : _FnlColors.violet.withOpacity(0.55),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: _FnlText.button(),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20, color: _FnlColors.white),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}