import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../Funcy/screens/chat_screen.dart';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavenderDeep = Color(0xFFEAE4FC);
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

  static TextStyle body({double size = 16}) => GoogleFonts.roboto(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: _FnlColors.body,
        height: 1.5,
      );

  static TextStyle label({double size = 12, double letterSpacing = 1.3}) =>
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

  ChatWidget(
      {required this.userId,
      required this.username,
      required this.onChatToggle});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/enthusiastic.png';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: Stack(
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
                // Si la altura no está acotada, se usa la de la pantalla
                final height = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : MediaQuery.of(context).size.height;

                final isTablet = width > 600;
                final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
                final maxContentWidth = isTablet ? 560.0 : 480.0;

                final imageSize = math.min(
                  width < 400
                      ? 220.0
                      : width < 600
                          ? 260.0
                          : 300.0,
                  height * 0.32,
                ).clamp(120.0, 300.0).toDouble();

                final titleSize = width < 400
                    ? 28.0
                    : width < 600
                        ? 32.0
                        : 36.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding:
                          EdgeInsets.fromLTRB(hPad, _FnlSpace.md, hPad, 110),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, (1 - t) * 16),
                            child: child,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'ASISTENTE VIRTUAL',
                              textAlign: TextAlign.center,
                              style: _FnlText.label(),
                            ),
                            const SizedBox(height: _FnlSpace.xs),
                            Text(
                              '¡Conversa con Funcy!',
                              textAlign: TextAlign.center,
                              style: _FnlText.h1(titleSize),
                            ),
                            const SizedBox(height: _FnlSpace.xs),
                            Text(
                              'Tu consejero virtual',
                              textAlign: TextAlign.center,
                              style: _FnlText.body(size: isTablet ? 20 : 18),
                            ),
                            const SizedBox(height: _FnlSpace.lg),
                            _buildMascot(imageSize),
                            const SizedBox(height: _FnlSpace.lg),
                            Center(
                              child: _PrimaryButton(
                                label: 'Ir al chat',
                                icon: Icons.arrow_forward_rounded,
                                loading: _isOpeningChat,
                                expand: false,
                                width: 150,
                                onTap: () => _startChat(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Mascota con halo
  Widget _buildMascot(double imageSize) {
    return SizedBox(
      height: imageSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: imageSize * 0.8,
            height: imageSize * 0.8,
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
            height: imageSize,
            width: imageSize,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: imageSize,
                width: imageSize,
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
                SizedBox(height: imageSize, width: imageSize),
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool loading;
  final bool expand;

  final double? width;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.width,
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
              valueColor: AlwaysStoppedAnimation<Color>(_FnlColors.violet),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: _FnlText.button().copyWith(color: _FnlColors.violet),
              ),
              if (icon != null) ...[
                const SizedBox(width: 7),
                Icon(
                  icon,
                  size: 18,
                  color: _FnlColors.violet,
                ),
              ],
            ],
          );

    final button = Material(
      color: _FnlColors.violet.withOpacity(0.12),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: loading ? null : onTap,
        splashColor: _FnlColors.violet.withOpacity(0.12),
        highlightColor: _FnlColors.violet.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: _FnlColors.violet.withOpacity(0.28),
              width: 1.3,
            ),
          ),
          child: content,
        ),
      ),
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: button,
      );
    }


    return SizedBox(
      width: width ?? 150,
      height: 56,
      child: button,
    );
  }
}