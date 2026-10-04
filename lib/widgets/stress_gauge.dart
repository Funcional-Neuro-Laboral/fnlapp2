import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/stress_level_style.dart';

/// Medidor semicircular del nivel de estrés, con tres zonas (leve, moderado,
/// alto) y un indicador que se desliza hasta el puntaje.
class StressGauge extends StatelessWidget {
  const StressGauge({
    super.key,
    required this.fraction,
    required this.zone,
    required this.accent,
    required this.semanticLabel,
    this.animate = true,
  });

  /// Posición del puntaje en la escala (0 a 1).
  final double fraction;

  /// Zona activa: 0 = leve, 1 = moderado, 2 = alto.
  final int zone;
  final Color accent;
  final String semanticLabel;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final target = fraction.clamp(0.0, 1.0).toDouble();
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 360 / 200,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: animate && !reduceMotion ? 0 : target, end: target),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            painter: _GaugePainter(markerFraction: value, zone: zone, accent: accent),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.markerFraction, required this.zone, required this.accent});

  final double markerFraction;
  final int zone;
  final Color accent;

  // Coordenadas de diseño en un lienzo de 360 x 200.
  static const _center = Offset(180, 184);
  static const _radius = 140.0;
  static const _gap = 0.012;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 360;
    canvas.save();
    canvas.scale(scale);

    final rect = Rect.fromCircle(center: _center, radius: _radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawArc(rect, math.pi, math.pi, false, track);

    final zones = [
      (0.0, StressScore.leveEnd, AppColors.zoneLeve),
      (StressScore.leveEnd, StressScore.moderadoEnd, AppColors.zoneModerado),
      (StressScore.moderadoEnd, 1.0, AppColors.zoneAlto),
    ];
    for (var i = 0; i < zones.length; i++) {
      final (from, to, color) = zones[i];
      final start = i == 0 ? from : from + _gap;
      final end = i == zones.length - 1 ? to : to - _gap;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..color = color.withValues(alpha: i == zone ? 1 : 0.25);
      canvas.drawArc(rect, math.pi + start * math.pi, (end - start) * math.pi, false, paint);
    }

    // Extremos redondeados.
    canvas.drawCircle(_pointAt(0, _radius), 11,
        Paint()..color = AppColors.zoneLeve.withValues(alpha: zone == 0 ? 1 : 0.25));
    canvas.drawCircle(_pointAt(1, _radius), 11,
        Paint()..color = AppColors.zoneAlto.withValues(alpha: zone == 2 ? 1 : 0.25));

    _drawLabel(canvas, 'Leve', 0.25, zone == 0);
    _drawLabel(canvas, 'Moderado', 0.667, zone == 1);
    _drawLabel(canvas, 'Alto', 0.93, zone == 2);

    final marker = _pointAt(markerFraction, _radius);
    canvas.drawCircle(marker, 22, Paint()..color = accent.withValues(alpha: 0.35));
    canvas.drawCircle(marker, 13, Paint()..color = Colors.white);
    canvas.drawCircle(
      marker,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = accent,
    );

    canvas.restore();
  }

  Offset _pointAt(double fraction, double radius) {
    final angle = math.pi + fraction * math.pi;
    return _center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  void _drawLabel(Canvas canvas, String text, double fraction, bool active) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          color: active ? accent : Colors.white.withValues(alpha: 0.6),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final anchor = _pointAt(fraction, 170);
    painter.paint(canvas, anchor - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.markerFraction != markerFraction ||
      oldDelegate.zone != zone ||
      oldDelegate.accent != accent;
}

/// Escala lineal de tres zonas con un marcador en el puntaje.
class StressScaleBar extends StatelessWidget {
  const StressScaleBar({
    super.key,
    required this.zone,
    required this.accent,
    this.fraction,
  });

  final int zone;
  final Color accent;

  /// Si no hay puntaje, el marcador va al centro de la zona.
  final double? fraction;

  static const _flex = [3, 2, 1];
  static const _colors = [AppColors.zoneLeve, AppColors.zoneModerado, AppColors.zoneAlto];
  static const _labels = ['Leve', 'Moderado', 'Alto'];

  @override
  Widget build(BuildContext context) {
    final position = fraction ??
        switch (zone) {
          0 => StressScore.leveEnd / 2,
          1 => (StressScore.leveEnd + StressScore.moderadoEnd) / 2,
          2 => (StressScore.moderadoEnd + 1) / 2,
          _ => 0.5,
        };
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Expanded(
                            flex: _flex[i],
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colors[i].withValues(alpha: i == zone ? 1 : 0.3),
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(i == 0 ? 999 : 0),
                                  right: Radius.circular(i == 2 ? 999 : 0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (zone >= 0)
                      Positioned(
                        left: (position * width - 11).clamp(0.0, width - 22),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: accent, width: 5),
                            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), spreadRadius: 6)],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      flex: _flex[i],
                      child: Text(
                        _labels[i],
                        textAlign: i == 2 ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: i == zone ? FontWeight.w800 : FontWeight.w600,
                          color: i == zone ? accent : Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
