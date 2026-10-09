import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;

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
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
}

/// Títulos y botones: Manrope. Texto corrido: Roboto.
class _FnlText {
  static TextStyle h1(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.2,
      );

  static TextStyle strong(double size, {Color color = _FnlColors.blue}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.4,
      );

  static TextStyle body(double size, {Color color = _FnlColors.body}) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle badge() => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _FnlColors.violet,
      );

  static TextStyle button() => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _FnlColors.white,
      );
}

class TestCompletionScreen extends StatefulWidget {
  final Future<void> Function() onFinalize;

  const TestCompletionScreen({
    Key? key,
    required this.onFinalize,
  }) : super(key: key);

  @override
  State<TestCompletionScreen> createState() => _TestCompletionScreenState();
}

class _TestCompletionScreenState extends State<TestCompletionScreen>
    with SingleTickerProviderStateMixin {
  static const String _mascotUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/meditating.png';

  bool isProcessing = false;
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Evita que la mascota "parpadee" al aparecer
    precacheImage(const NetworkImage(_mascotUrl), context);
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _handleFinalize() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);
    try {
      await widget.onFinalize();
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Widget _stagger(double begin, Widget child) {
    final end = (begin + 0.4).clamp(0.0, 1.0);
    final curve = Interval(begin, end, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: _intro,
      child: child,
      builder: (context, child) {
        final t = curve.transform(_intro.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
    );
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
                final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                final maxContentWidth = isTablet ? 720.0 : double.infinity;
                final mascotSize = isTablet ? 180.0 : 140.0;
                final titleSize = isTablet ? 32.0 : 28.0;
                final textSize = isTablet ? 18.0 : 16.0;

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                                hPad, _FnlSpace.md, hPad, _FnlSpace.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _stagger(0.0, _buildMascot(mascotSize)),
                                const SizedBox(height: _FnlSpace.sm),
                                _stagger(0.10, _buildHeading(titleSize)),
                                const SizedBox(height: _FnlSpace.md),
                                _stagger(
                                  0.25,
                                  _MessageCard(
                                    icon: Icons.favorite_rounded,
                                    highlight:
                                        'Cada respuesta que diste no fue solo una elección, fue una forma de conocerte mejor.',
                                    detail:
                                        'Reconocer cómo te sientes frente a tu entorno laboral ya es un paso enorme hacia el cambio.',
                                    fontSize: textSize,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _stagger(
                                  0.40,
                                  _MessageCard(
                                    icon: Icons.psychology_rounded,
                                    highlight:
                                        'El estrés, la presión o la falta de apoyo no son señales de debilidad.',
                                    detail:
                                        'Son indicadores de que estás comprometido, de que te importa hacer las cosas bien, y de que necesitas espacios más humanos para crecer.',
                                    fontSize: textSize,
                                  ),
                                ),
                                const SizedBox(height: _FnlSpace.md),
                                _stagger(0.55, _buildThanksBubble(textSize)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _stagger(0.70, _buildBottomBar(hPad, maxContentWidth)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascot(double size) {
    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.8,
            height: size * 0.8,
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
            _mascotUrl,
            height: size,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: size,
                width: size,
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
            errorBuilder: (_, __, ___) => SizedBox(height: size, width: size),
          ),
        ],
      ),
    );
  }

  // Píldora "Test completado" + título
  Widget _buildHeading(double titleSize) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _FnlColors.lavender,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: _FnlColors.violet),
              const SizedBox(width: 6),
              Text('Test completado', style: _FnlText.badge()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Has completado\n', style: _FnlText.h1(titleSize)),
            TextSpan(
              text: 'tu recorrido',
              style: _FnlText.h1(titleSize)
                  .copyWith(color: _FnlColors.violet),
            ),
          ]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildThanksBubble(double fontSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_FnlSpace.md),
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
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
            text: 'Gracias por dedicar este momento a ti. ',
            style: _FnlText.strong(fontSize, color: _FnlColors.violet),
          ),
          TextSpan(
            text:
                'Estamos preparando tu perfil personalizado para que encuentres equilibrio, propósito y calma.',
            style: _FnlText.strong(fontSize).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomBar(double hPad, double maxContentWidth) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, _FnlSpace.sm, hPad, _FnlSpace.md),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: _PrimaryButton(
            label: 'Finalizar',
            icon: Icons.arrow_forward_rounded,
            loading: isProcessing,
            onTap: _handleFinalize,
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String highlight;
  final String detail;
  final double fontSize;

  const _MessageCard({
    required this.icon,
    required this.highlight,
    required this.detail,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_FnlSpace.sm),
      decoration: BoxDecoration(
        color: _FnlColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FnlColors.border, width: 2),
        boxShadow: const [
          BoxShadow(
            color: _FnlColors.border,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _FnlColors.lavender,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _FnlColors.violet, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '$highlight\n',
                  style: _FnlText.strong(fontSize),
                ),
                TextSpan(text: detail, style: _FnlText.body(fontSize - 1)),
              ]),
            ),
          ),
        ],
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: _FnlColors.violet,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: loading ? null : onTap,
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
                      Text(label, style: _FnlText.button()),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20, color: _FnlColors.white),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}