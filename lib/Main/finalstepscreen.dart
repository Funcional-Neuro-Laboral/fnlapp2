import 'package:flutter/material.dart';
import 'package:fnlapp/Main/home.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../Util/api_service.dart';
import '../widgets/app_buttons.dart';
import '../widgets/state_views.dart';
import 'plan.dart' show totalProgramDays;

/// Cierre de la actividad del día: celebración, cómo se siente el usuario y
/// comentario opcional. Al guardar, el día queda completado.
class FinalStepScreen extends StatefulWidget {
  final int userId;
  final int tecnicaId;
  final int sessionId;
  final int? dia;

  const FinalStepScreen({
    Key? key,
    required this.userId,
    required this.tecnicaId,
    required this.sessionId,
    this.dia,
  }) : super(key: key);

  @override
  State<FinalStepScreen> createState() => _FinalStepScreenState();
}

class _FinalStepScreenState extends State<FinalStepScreen> {
  final TextEditingController _commentController = TextEditingController();
  int? _feeling; // 1 (peor) a 5 (mucho mejor)
  bool _isLoading = false;

  static const _feelings = [
    (Icons.sentiment_very_dissatisfied_rounded, 'Peor que antes'),
    (Icons.sentiment_dissatisfied_rounded, 'Un poco peor'),
    (Icons.sentiment_neutral_rounded, 'Igual que antes'),
    (Icons.sentiment_satisfied_rounded, 'Mejor'),
    (Icons.sentiment_very_satisfied_rounded, 'Mucho mejor'),
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool skipped}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final feeling = _feeling ?? 3;
    final comment = _commentController.text.trim();
    final requestData = {
      'comentario': (skipped || comment.isEmpty) ? 'Sin comentario' : comment,
      'estrellas': feeling,
      // El servidor usa 3 caritas: 1 = mal, 2 = igual, 3 = bien.
      'caritas': feeling <= 2 ? 1 : (feeling == 3 ? 2 : 3),
    };

    try {
      await ApiService().put(
        'programs/sessions/${widget.sessionId}/complete/${widget.userId}',
        requestData,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dia = widget.dia;
    final percent = dia == null ? null : ((dia / totalProgramDays) * 100).round();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 172,
                          height: 172,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 156,
                                height: 156,
                                decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                              ),
                              const FuncyImage(FuncyPose.celebra, size: 172, semanticLabel: 'Funcy celebrando con confeti'),
                              Positioned(
                                right: 10,
                                bottom: 12,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          header: true,
                          child: Text(
                            dia == null ? '¡Actividad completada!' : '¡Día $dia completado!',
                            style: textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bien hecho. Cuéntanos cómo te sientes para seguir mejorando tu plan.',
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                          textAlign: TextAlign.center,
                        ),
                        if (percent != null) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _Pill(
                                label: '$dia de $totalProgramDays días',
                                icon: Icons.local_fire_department_rounded,
                                iconColor: AppColors.streak,
                                background: AppColors.streakBg,
                                foreground: AppColors.streakText,
                              ),
                              _Pill(
                                label: '$percent% del programa',
                                background: AppColors.lavender,
                                foreground: AppColors.primaryDeep,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBFAFD),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderSoft),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text('¿Cómo te sientes ahora?', style: textTheme.labelLarge),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for (var i = 0; i < _feelings.length; i++)
                                    _FeelingButton(
                                      icon: _feelings[i].$1,
                                      label: _feelings[i].$2,
                                      selected: _feeling == i + 1,
                                      onTap: () => setState(() => _feeling = i + 1),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Expanded(
                                    child: Text('Peor que antes',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkTertiary)),
                                  ),
                                  Text('Mucho mejor',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkTertiary)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text.rich(
                                TextSpan(
                                  text: 'Comentario ',
                                  style: textTheme.labelMedium,
                                  children: const [
                                    TextSpan(
                                      text: '(opcional)',
                                      style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.inkTertiary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _commentController,
                                minLines: 2,
                                maxLines: 4,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: '¿Algo que quieras contarnos sobre la actividad?',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      AppPrimaryButton(
                        label: 'Guardar y volver a mi plan',
                        loading: _isLoading,
                        onPressed: _feeling == null ? null : () => _submit(skipped: false),
                      ),
                      if (_feeling == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Elige cómo te sientes para guardar.',
                              style: TextStyle(fontSize: 12, color: AppColors.inkTertiary)),
                        ),
                      TextButton(
                        onPressed: _isLoading ? null : () => _submit(skipped: true),
                        child: const Text('Omitir por ahora'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeelingButton extends StatelessWidget {
  const _FeelingButton({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 2),
            ),
            child: Icon(icon, size: 30, color: selected ? Colors.white : AppColors.primaryDeep),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.iconColor,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? foreground),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: foreground)),
        ],
      ),
    );
  }
}
