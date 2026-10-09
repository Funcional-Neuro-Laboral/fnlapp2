import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import '../models/test_notice.dart';

class _C {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const border = Color(0xFFD9DCEF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const white = Color(0xFFFFFFFF);
}

class TestNoticeDialog extends StatelessWidget {
  final TestNotice notice;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const TestNoticeDialog({
    Key? key,
    required this.notice,
    required this.onContinue,
    this.onBack,
  }) : super(key: key);

  TextStyle _text(double size,
      {FontWeight weight = FontWeight.w500, Color color = _C.blue}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }

  TextSpan _regular(String t, double size) =>
      TextSpan(text: t, style: _text(size));

  TextSpan _bold(String t, double size) =>
      TextSpan(text: t, style: _text(size, weight: FontWeight.w800));

  TextSpan _accent(String t, double size) => TextSpan(
      text: t, style: _text(size, weight: FontWeight.w800, color: _C.violet));

  Widget _buildDescription(double size) {
    switch (notice.afterQuestion) {
      case 6:
        return Text.rich(
          TextSpan(children: [
            _accent('No estás solo.\n', size),
            _bold(
              'Muchos profesionales sienten lo mismo cuando las cosas se salen de control.',
              size,
            ),
          ]),
          textAlign: TextAlign.center,
        );

      case 12:
        return Text.rich(
          TextSpan(children: [
            _regular('Según la neurociencia, puedes entrenar tu mente para ',
                size),
            _bold('reducir el estrés. ', size),
            _accent('Más del 70% ', size),
            _bold('del estrés laboral', size),
            _regular(' proviene de factores fuera de tu control.', size),
          ]),
          textAlign: TextAlign.center,
        );

      case 15:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Estás haciendo un gran trabajo.',
              textAlign: TextAlign.center,
              style: _text(size, weight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [
                _regular(
                    'Lo que estás logrando ahora te acerca a un gran salto en tu bienestar.\n',
                    size),
                _accent('Sigue adelante.', size),
              ]),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case 18:
        return Text.rich(
          TextSpan(children: [
            _regular('El cambio empieza con conocerte mejor.\n', size),
            _bold('Estás a pocos pasos de descubrir un plan hecho para ti.',
                size),
          ]),
          textAlign: TextAlign.center,
        );

      default:
        return Text(
          notice.description,
          textAlign: TextAlign.center,
          style: _text(size, weight: FontWeight.w800),
        );
    }
  }

  // ── Imagen con halo suave (igual que Funcy en el test) ────────
  Widget _buildImage(String url, double maxHeight) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: maxHeight * 0.7,
            height: maxHeight * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _C.violetSecondary.withOpacity(0.22),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Image.network(
            url,
            height: maxHeight,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: maxHeight,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _C.violetSecondary,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => SizedBox(height: maxHeight),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta blanca que contiene el mensaje ────────────────────
  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.bubbleBorder, width: 2),
        boxShadow: const [
          BoxShadow(
            color: _C.bubbleBorder,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _title(double size) {
    return Text(
      notice.title!,
      textAlign: TextAlign.center,
      style: GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _C.blue,
        height: 1.25,
      ),
    );
  }

  bool get _hasImage =>
      notice.imagePath != null && notice.imagePath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final hPad = isTablet ? 32.0 : 24.0;
    final maxContentWidth = isTablet ? 720.0 : double.infinity;
    final textSize = isTablet ? 24.0 : 20.0;
    final titleSize = isTablet ? 32.0 : 28.0;

    // Contenido central según el aviso (se conserva el orden original)
    final List<Widget> content;
    switch (notice.afterQuestion) {
      case 18:
        content = [
          if (notice.title != null) ...[
            _title(titleSize),
            const SizedBox(height: 16),
          ],
          if (_hasImage) ...[
            _buildImage(notice.imagePath!, size.height * 0.28),
            const SizedBox(height: 24),
          ],
          _card(_buildDescription(textSize)),
        ];
        break;

      case 15:
        content = [
          if (_hasImage) ...[
            _buildImage(notice.imagePath!, size.height * 0.34),
            const SizedBox(height: 24),
          ],
          _card(_buildDescription(textSize)),
        ];
        break;

      case 12:
        content = [
          _card(_buildDescription(textSize)),
          if (_hasImage) ...[
            const SizedBox(height: 24),
            _buildImage(notice.imagePath!, size.height * 0.26),
          ],
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(children: [
              _regular('En ', textSize),
              _accent('Funcy', textSize),
              _regular(', te acompañamos paso a paso para lograrlo.', textSize),
            ]),
            textAlign: TextAlign.center,
          ),
        ];
        break;

      default:
        content = [
          if (notice.title != null) ...[
            _title(titleSize),
            const SizedBox(height: 16),
          ],
          if (_hasImage) ...[
            _buildImage(notice.imagePath!, size.height * 0.30),
            const SizedBox(height: 24),
          ],
          _card(_buildDescription(textSize)),
        ];
    }

    return Container(
      color: _C.canvas,
      child: Stack(
        children: [
          // Círculos decorativos (mismo lenguaje que bienvenida y test)
          Positioned(
            top: -70,
            right: -70,
            child: IgnorePointer(child: _circle(220)),
          ),
          Positioned(
            bottom: -90,
            left: -90,
            child: IgnorePointer(child: _circle(240)),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header: botón de retroceso circular
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: onBack != null
                          ? Material(
                              color: _C.white,
                              shape: const CircleBorder(
                                side: BorderSide(
                                    color: _C.bubbleBorder, width: 2),
                              ),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onBack,
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: _C.violet,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                // Contenido central
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                            horizontal: hPad, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: content
                              .map((w) => w is ConstrainedBox
                                  ? Center(child: w)
                                  : w)
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Botón continuar
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Material(
                          color: _C.violet,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: onContinue,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    notice.buttonText,
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 20, color: Colors.white),
                                ],
                              ),
                            ),
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

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _C.lavenderDeep,
        shape: BoxShape.circle,
      ),
    );
  }
}