import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:fnlapp/Main/home.dart';
import '../Util/api_service.dart';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
  static const border = Color(0xFFD9DCEF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const disabledText = Color(0xFF9AA0C0);
  static const star = Color(0xFFF1D93E); 
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
}

class _FnlText {
  static TextStyle h2(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.25,
      );

  static TextStyle body({double size = 16, Color color = _FnlColors.blue}) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle button({Color color = _FnlColors.white}) =>
      GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

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
  static const String _happyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/happy.png';

  final TextEditingController _commentController = TextEditingController();
  late final AnimationController _animationController;
  late final List<Animation<double>> _staggered;

  double _rating = 3.0;
  MoodLevel _selectedMood = MoodLevel.neutral;
  bool _isLoading = false;
  bool _submitted = false; // evita un segundo envío mientras se navega
  bool _imagesPrecached = false;
  String _feedbackMessage = '';
  bool _feedbackIsError = false;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _staggered = List.generate(4, (i) {
      final start = i * 0.14;
      return CurvedAnimation(
        parent: _animationController,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
            curve: Curves.easeOut),
      );
    });
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const NetworkImage(_happyUrl), context);
      _imagesPrecached = true;
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _commentController.text.trim().isNotEmpty && _rating > 0;

  Future<void> _submitFeedback() async {
    if (!_isFormValid || _isLoading || _submitted) return;

    setState(() {
      _isLoading = true;
      _feedbackMessage = '';
      _feedbackIsError = false;
    });

    try {
      await _sendFeedbackToServer();
      if (!mounted) return;
      _submitted = true;
      _showSuccessAndNavigate();
    } catch (e) {
      debugPrint('Error al enviar feedback: $e');
      _showErrorMessage(
          'No se pudo enviar tu comentario. Revisa tu conexión e inténtalo de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendFeedbackToServer() async {
    final Map<String, dynamic> requestData = {
      "comentario": _commentController.text.trim(),
      "estrellas": _rating.toInt(),
      "caritas": _selectedMood.value,
    };

    final apiService = ApiService();
    final response = await apiService.put(
      'programs/sessions/${widget.sessionId}/complete/${widget.userId}',
      requestData,
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  void _showSuccessAndNavigate() {
    setState(() {
      _feedbackMessage = 'Comentario enviado exitosamente';
      _feedbackIsError = false;
    });

    _navTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: Stack(
        children: [
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
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final isSmallHeight = constraints.maxHeight < 700;
                final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                final maxContentWidth = isTablet ? 720.0 : double.infinity;
                final mascotSize = isTablet
                    ? 160.0
                    : isSmallHeight
                        ? 96.0
                        : 120.0;

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                                hPad, _FnlSpace.md, hPad, _FnlSpace.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _stagger(0, _buildHeader(mascotSize, isTablet)),
                                const SizedBox(height: _FnlSpace.md),
                                _stagger(1, _buildRatingCard(isTablet)),
                                const SizedBox(height: _FnlSpace.sm),
                                _stagger(2, _buildCommentField(isTablet)),
                                const SizedBox(height: _FnlSpace.sm),
                                _stagger(3, _buildMoodCard(isTablet)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildBottomBar(hPad, maxContentWidth),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stagger(int index, Widget child) {
    final animation = _staggered[index];
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _FnlColors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _FnlColors.border, width: 2),
      boxShadow: const [
        BoxShadow(
          color: _FnlColors.border,
          offset: Offset(0, 4),
          blurRadius: 0,
        ),
      ],
    );
  }

  Widget _buildHeader(double mascotSize, bool isTablet) {
    return Column(
      children: [
        SizedBox(
          height: mascotSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: mascotSize * 0.8,
                height: mascotSize * 0.8,
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
                _happyUrl,
                height: mascotSize,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: mascotSize,
                    width: mascotSize,
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
                errorBuilder: (_, __, ___) =>
                    SizedBox(height: mascotSize, width: mascotSize),
              ),
            ],
          ),
        ),
        const SizedBox(height: _FnlSpace.xs),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
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
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Califica tu experiencia con la técnica de '
                          'relajación de hoy que te ofreció ',
                      style: _FnlText.h2(isTablet ? 24 : 20),
                    ),
                    TextSpan(
                      text: 'Funcy',
                      style: _FnlText.h2(isTablet ? 24 : 20)
                          .copyWith(color: _FnlColors.violet),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              top: 2,
              child: Transform.rotate(
                angle: 0.785398, // 45°
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _FnlColors.white,
                    border: Border(
                      top: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                      left:
                          BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Estrellas
  Widget _buildRatingCard(bool isTablet) {
    final double maxStar = isTablet ? 56 : 48;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: _FnlSpace.md, horizontal: _FnlSpace.sm),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double starSize =
              (constraints.maxWidth / 5 / 1.1).clamp(32.0, maxStar);

          return Center(
            child: RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: starSize,
              itemPadding: EdgeInsets.symmetric(horizontal: starSize * 0.05),
              glowColor: _FnlColors.star.withOpacity(0.3),
              unratedColor: _FnlColors.border,
              itemBuilder: (context, index) => const Icon(
                Icons.star_rounded,
                color: _FnlColors.star,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
          );
        },
      ),
    );
  }

  // Comentario
  Widget _buildCommentField(bool isTablet) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: _commentController,
      minLines: 3,
      maxLines: isTablet ? 6 : 5,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      cursorColor: _FnlColors.violet,
      style: _FnlText.body(),
      decoration: InputDecoration(
        filled: true,
        fillColor: _FnlColors.white,
        hintText: 'Deja un comentario sobre la técnica',
        hintStyle: _FnlText.body(color: _FnlColors.body),
        contentPadding: const EdgeInsets.all(_FnlSpace.sm),
        enabledBorder: border(_FnlColors.border, 1),
        focusedBorder: border(_FnlColors.violet, 2),
        border: border(_FnlColors.border, 1),
      ),
    );
  }

  // Estado de ánimo
  Widget _buildMoodCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_FnlSpace.md),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            '¿Qué tan aliviado te sientes luego de la sesión de hoy?',
            textAlign: TextAlign.center,
            style: _FnlText.h2(isTablet ? 20 : 18),
          ),
          const SizedBox(height: _FnlSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MoodLevel.values
                .map((mood) => _buildMoodButton(mood, isTablet))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(MoodLevel mood, bool isTablet) {
    final bool isSelected = _selectedMood == mood;
    final double boxSize = isTablet ? 88 : 72;

    return Semantics(
      button: true,
      selected: isSelected,
      label: mood.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedMood = mood;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: isSelected ? _FnlColors.lavender : _FnlColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 2,
              color: isSelected ? _FnlColors.violet : _FnlColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? _FnlColors.violet.withOpacity(0.35)
                    : _FnlColors.border,
                offset: Offset(0, isSelected ? 2 : 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(
            mood.icon,
            size: isTablet ? 48 : 40,
            color: isSelected ? _FnlColors.violet : _FnlColors.disabledText,
          ),
        ),
      ),
    );
  }

  // Mensaje de éxito / error
  Widget _buildFeedbackMessage() {
    if (_feedbackMessage.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: _FnlSpace.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: _FnlSpace.sm, vertical: 12),
        decoration: BoxDecoration(
          color: _FnlColors.lavender,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              _feedbackIsError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              size: 20,
              color: _FnlColors.violet,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _feedbackMessage,
                style: _FnlText.body(size: 14)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botón principal fijo abajo
  Widget _buildBottomBar(double hPad, double maxContentWidth) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, _FnlSpace.xs, hPad, _FnlSpace.md),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _buildFeedbackMessage(),
              ),
              // El botón se habilita solo con comentario escrito
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _commentController,
                builder: (context, value, _) {
                  final bool canSubmit = _isFormValid &&
                      !_isLoading &&
                      !_submitted;
                  return _PrimaryButton(
                    label: 'Enviar',
                    icon: Icons.arrow_forward_rounded,
                    loading: _isLoading || _submitted,
                    enabled: canSubmit,
                    onTap: _submitFeedback,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum MoodLevel {
  sad(1, Icons.sentiment_very_dissatisfied, Colors.red, 'Nada aliviado'),
  neutral(2, Icons.sentiment_neutral, Colors.amber, 'Poco aliviado'),
  happy(3, Icons.sentiment_very_satisfied, Colors.green, 'Muy aliviado');

  const MoodLevel(this.value, this.icon, this.color, this.label);

  final int value;
  final IconData icon;
  final Color color;

  /// Solo para accesibilidad (lectores de pantalla).
  final String label;
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final Color fg = enabled ? _FnlColors.white : _FnlColors.disabledText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: (enabled || loading) ? _FnlColors.violet : _FnlColors.border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_FnlColors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: _FnlText.button(color: fg)),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20, color: fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}