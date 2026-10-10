import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../Funcy/screens/chat_screen.dart';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
}

class _FnlText {
  static TextStyle h1(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.2,
      );

  static TextStyle h2(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.25,
      );

  static TextStyle body({double size = 16, Color color = _FnlColors.body}) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle label({double size = 12, double letterSpacing = 1.2}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: _FnlColors.violet,
        letterSpacing: letterSpacing,
      );

  static TextStyle button() => GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _FnlColors.white,
      );
}

class ChatWidget extends StatefulWidget {
  final int userId;
  final String username;
  final Function(bool) onChatToggle;

  const ChatWidget({
    Key? key,
    required this.userId,
    required this.username,
    required this.onChatToggle,
  }) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/enthusiastic.png';

  static const double _bottomNavSpace = 120.0;

  bool _imagesPrecached = false;
  bool _isOpeningChat = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      precacheImage(const NetworkImage(_funcyUrl), context);
      _imagesPrecached = true;
    }
  }

  String get _firstName {
    final trimmed = widget.username.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get _greetingTitle {
    final name = _firstName;
    return name.isEmpty ? '¡Hola!' : '¡Hola, $name!';
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

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
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : MediaQuery.of(context).size.height;

                  final isTablet = width > 600;
                  final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                  final maxContentWidth = isTablet ? 520.0 : 480.0;

                  final titleSize = width < 400
                      ? 28.0
                      : width < 600
                          ? 32.0
                          : 36.0;

                  final mascotSize = math
                      .min(170.0, (height - _bottomNavSpace) * 0.22)
                      .clamp(100.0, 180.0)
                      .toDouble();

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 16),
                            child: child,
                          ),
                        ),
                        child: CustomScrollView(
                          physics: const ClampingScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  hPad,
                                  _FnlSpace.md,
                                  hPad,
                                  _bottomNavSpace,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeader(titleSize),
                                    Expanded(
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: _FnlSpace.sm),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _buildHeroCard(mascotSize),
                                              const SizedBox(
                                                  height: _FnlSpace.sm),
                                              const _DisclaimerNote(),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double titleSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FUNCY · ASISTENTE VIRTUAL', style: _FnlText.label()),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text('Conversa con Funcy', style: _FnlText.h1(titleSize)),
        ),
      ],
    );
  }

  /// Tarjeta principal: la mascota sobresale por arriba y dentro van el
  /// saludo, el mensaje y la acción principal.
  Widget _buildHeroCard(double mascotSize) {
    final overlap = mascotSize / 2;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: EdgeInsets.only(top: overlap),
          padding: EdgeInsets.fromLTRB(
            _FnlSpace.md,
            overlap + _FnlSpace.sm,
            _FnlSpace.md,
            _FnlSpace.md,
          ),
          decoration: BoxDecoration(
            color: _FnlColors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: _FnlColors.bubbleBorder,
                offset: Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  _greetingTitle,
                  textAlign: TextAlign.center,
                  style: _FnlText.h2(24),
                ),
              ),
              const SizedBox(height: _FnlSpace.xs),
              Text(
                'Estoy aquí para escucharte. Cuéntame cómo te sientes hoy.',
                textAlign: TextAlign.center,
                style: _FnlText.body(size: 15),
              ),
              const SizedBox(height: _FnlSpace.md),
              _PrimaryButton(
                label: 'Empezar a conversar',
                icon: Icons.arrow_forward_rounded,
                loading: _isOpeningChat,
                onTap: () => _startChat(context),
              ),
            ],
          ),
        ),
        _FloatingMascot(
          child: _buildMascot(mascotSize),
        ),
      ],
    );
  }

  // Mascota con halo
  Widget _buildMascot(double size) {
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _FnlColors.violetSecondary.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Image.network(
            _funcyUrl,
            height: size,
            width: size,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
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

  Future<void> _startChat(BuildContext context) async {
    if (_isOpeningChat) return;
    setState(() => _isOpeningChat = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userId: widget.userId,
            username: widget.username,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
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

class _DisclaimerNote extends StatelessWidget {
  const _DisclaimerNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _FnlSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: _FnlColors.body,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Funcy es un asistente virtual y no reemplaza la atención de un profesional.',
              textAlign: TextAlign.center,
              style: _FnlText.body(size: 12),
            ),
          ),
        ],
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

    final content = loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_FnlColors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
          );

    return Semantics(
      button: true,
      enabled: !loading,
      label: label,
      excludeSemantics: true,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: loading
              ? _FnlColors.violet.withOpacity(0.7)
              : _FnlColors.violet,
          boxShadow: [
            BoxShadow(
              color: _FnlColors.violet.withOpacity(0.28),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: loading ? null : onTap,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}