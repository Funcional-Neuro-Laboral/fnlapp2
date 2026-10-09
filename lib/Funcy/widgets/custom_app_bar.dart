import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;


class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const lavender = Color(0xFFF4F1FF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const white = Color(0xFFFFFFFF);
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double scrollOffset;
  final Color backgroundColor;

  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';

  CustomAppBar({
    required this.scrollOffset,
    this.backgroundColor = Colors.white, // Color por defecto
  });


  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final bool scrolled = scrollOffset > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: scrolled ? _FnlColors.bubbleBorder : Colors.transparent,
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botón de retroceso (lado izquierdo)
              _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),

              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Conversa con Funcy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            color: _FnlColors.blue,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const _CircleIconButton(icon: Icons.more_horiz_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
        shape: BoxShape.circle,
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          _funcyUrl,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.chat_bubble_rounded,
            size: 14,
            color: _FnlColors.violet,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: icon == Icons.more_horiz_rounded ? 20 : 16,
      color: _FnlColors.violet,
    );

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: _FnlColors.white,
        shape: const CircleBorder(
          side: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
        ),
        child: onTap == null
            ? Center(child: iconWidget)
            : InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Center(child: iconWidget),
              ),
      ),
    );
  }
}