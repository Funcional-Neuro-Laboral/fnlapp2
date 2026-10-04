import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/funcy.dart';
import '../../widgets/app_buttons.dart';

/// Cierre de las preguntas iniciales, antes de guardar las respuestas.
class IndexSummaryScreen extends StatefulWidget {
  final Future<void> Function() onFinalize;
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
  bool _saving = false;

  Future<void> _finalize() async {
    setState(() => _saving = true);
    try {
      await widget.onFinalize();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: IconButton(
                      tooltip: 'Volver a las preguntas',
                      onPressed: _saving ? null : widget.onBack,
                      style: IconButton.styleFrom(backgroundColor: AppColors.muted, minimumSize: const Size(44, 44)),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Column(
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const FuncyImage(FuncyPose.feliz, size: 210, semanticLabel: 'Funcy feliz'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'El equilibrio entre tu trabajo y tu bienestar empieza por conocerte',
                          style: textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          const TextSpan(
                            children: [
                              TextSpan(text: 'Tu cargo y tus responsabilidades '),
                              TextSpan(text: 'no te definen', style: TextStyle(fontWeight: FontWeight.w800)),
                              TextSpan(text: ', pero nos ayudan a crear un plan más humano y real para ti.'),
                            ],
                          ),
                          style: textTheme.bodyLarge?.copyWith(color: AppColors.inkSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'A continuación harás un breve test de estrés.',
                          style: TextStyle(fontSize: 14, color: AppColors.inkTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: AppPrimaryButton(label: 'Guardar y continuar', loading: _saving, onPressed: _finalize),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
