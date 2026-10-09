import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;


class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
}

class _FnlText {
  static TextStyle message(double size,
          {FontWeight weight = FontWeight.w500,
          Color color = _FnlColors.blue}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.4,
      );

  static TextStyle button() => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _FnlColors.white,
      );
}

class IndexSummaryScreen extends StatefulWidget {
  final FutureOr<void> Function() onFinalize;
  final VoidCallback onBack;

  const IndexSummaryScreen({
    Key? key,
    required this.onFinalize,
    required this.onBack,
  }) : super(key: key);

  @override
  State<IndexSummaryScreen> createState() => _IndexSummaryScreenState();
}

class _IndexSummaryScreenState extends State<IndexSummaryScreen> {
  static const String _mascotUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/happy+3.png';

  bool _isProcessing = false;

  Future<void> _handleFinalize() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await Future<void>.sync(widget.onFinalize);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
                final isSmallHeight = constraints.maxHeight < 650;
                final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                final maxContentWidth = isTablet ? 720.0 : double.infinity;
                final mascotSize = isTablet
                    ? 240.0
                    : isSmallHeight
                        ? 140.0
                        : 200.0;
                final textSize = isTablet ? 24.0 : 20.0;

                return Column(
                  children: [
                    // Header: botón de retroceso circular
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          hPad, _FnlSpace.sm, hPad, _FnlSpace.xs),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Material(
                            color: _FnlColors.white,
                            shape: const CircleBorder(
                              side: BorderSide(
                                  color: _FnlColors.bubbleBorder, width: 2),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _isProcessing ? null : widget.onBack,
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: _FnlColors.violet,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Contenido central
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                                horizontal: hPad, vertical: _FnlSpace.sm),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MascotHalo(url: _mascotUrl, size: mascotSize),
                                const SizedBox(height: _FnlSpace.sm),
                                _SpeechBubble(
                                  child: Text.rich(
                                    TextSpan(children: [
                                      TextSpan(
                                        text:
                                            'El equilibrio entre tu trabajo y tu bienestar empieza por conocerte.\n',
                                        style: _FnlText.message(textSize,
                                            weight: FontWeight.w800),
                                      ),
                                      TextSpan(
                                        text: 'Tu cargo y responsabilidades ',
                                        style: _FnlText.message(textSize),
                                      ),
                                      TextSpan(
                                        text: 'no te definen, ',
                                        style: _FnlText.message(
                                          textSize,
                                          weight: FontWeight.w800,
                                          color: _FnlColors.violet,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'pero sí nos ayudan a crear un plan más humano y real para ti.',
                                        style: _FnlText.message(textSize),
                                      ),
                                    ]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Botón Finalizar
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          hPad, _FnlSpace.sm, hPad, _FnlSpace.md),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
                          child: _PrimaryButton(
                            label: 'Finalizar',
                            icon: Icons.arrow_forward_rounded,
                            loading: _isProcessing,
                            onTap: _handleFinalize,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
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

class _MascotHalo extends StatelessWidget {
  final String url;
  final double size;
  const _MascotHalo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
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
            url,
            height: size,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: size,
                width: size,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _FnlColors.violetSecondary,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
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
}

class _SpeechBubble extends StatelessWidget {
  final Widget child;
  const _SpeechBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            child: child,
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
                  left: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
              ),
            ),
          ),
        ),
      ],
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