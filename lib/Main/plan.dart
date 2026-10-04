import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fnlapp/Main/step_screen.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../Util/date_format_es.dart';
import '../Util/translations.dart';
import '../widgets/app_buttons.dart';
import '../widgets/state_views.dart';

const int totalProgramDays = 21;

// Modelo de datos
class Programa {
  final String? startDate;
  final String? completedDate;
  final bool completed;
  final String nombreTecnica;
  final String tipoTecnica;
  final String? descripcion;
  final String? urlImg;
  final int dia;
  final int userId;
  final int id;
  final int sessionId;
  final dynamic guia;
  final bool unlocked;

  Programa({
    this.startDate,
    this.completedDate,
    this.completed = false,
    required this.nombreTecnica,
    required this.tipoTecnica,
    this.descripcion,
    this.urlImg,
    required this.dia,
    required this.userId,
    required this.id,
    required this.sessionId,
    this.guia,
    this.unlocked = false,
  });

  factory Programa.fromMap(Map<String, dynamic> map) {
    return Programa(
      startDate: map['start_date'],
      completedDate: map['completed_date'],
      completed: map['completed'] == true,
      nombreTecnica: map['nombre_tecnica'] ?? 'Sin nombre',
      tipoTecnica: map['tipo_tecnica'] ?? 'Sin tipo',
      descripcion: map['descripcion'],
      urlImg: map['url_img'],
      dia: int.tryParse(map['dia'].toString()) ?? 0,
      userId: int.tryParse(map['user_id'].toString()) ?? 0,
      id: int.tryParse(map['id'].toString()) ?? 0,
      sessionId: int.tryParse(map['session_id'].toString()) ?? 0,
      guia: map['guia'],
      unlocked: map['unlocked'] ?? false,
    );
  }

  bool get isCompleted => completed || completedDate != null;

  DateTime? get startDateTime => startDate == null ? null : DateTime.tryParse(startDate!)?.toLocal();

  DateTime? get completedDateTime =>
      completedDate == null ? null : DateTime.tryParse(completedDate!)?.toLocal();

  bool get isUnlocked {
    if (!unlocked) return false;
    final start = startDateTime;
    if (start == null) return false;
    final date = DateTime(start.year, start.month, start.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(date);
  }

  List<String> get parsedSteps {
    try {
      if (guia is String) {
        return List<String>.from(json.decode(guia));
      } else if (guia is List) {
        return List<String>.from(guia);
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing steps: $e');
      return [];
    }
  }

  String get dayLabel => 'Día ${dia.toString().padLeft(2, '0')}';

  /// Imagen ilustrativa de cada día del programa.
  String get imageUrl => (dia >= 1 && dia <= totalProgramDays)
      ? 'https://funkyrecursos.s3.us-east-2.amazonaws.com/recursos_nuevos2/DIA$dia.png'
      : (urlImg ?? '');
}

/// Días seguidos (hasta hoy o ayer) con al menos una actividad completada.
int computeStreak(Iterable<Programa> programas, {DateTime? now}) {
  final days = <DateTime>{};
  for (final p in programas) {
    final d = p.completedDateTime;
    if (d != null) days.add(DateTime(d.year, d.month, d.day));
  }
  if (days.isEmpty) return 0;
  final reference = now ?? DateTime.now();
  var cursor = DateTime(reference.year, reference.month, reference.day);
  if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

class PlanScreen extends StatefulWidget {
  final NivelEstres nivelEstres;
  final bool isLoading;
  final bool loadFailed;
  final List<dynamic> programas;
  final bool showExitTestModal;
  final String? userName;
  final String? avatarUrl;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onStartExitTest;

  const PlanScreen({
    Key? key,
    required this.nivelEstres,
    required this.isLoading,
    required this.programas,
    this.loadFailed = false,
    this.showExitTestModal = false,
    this.userName,
    this.avatarUrl,
    this.onRefresh,
    this.onOpenProfile,
    this.onStartExitTest,
  }) : super(key: key);

  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _hasShownModal = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowModal();
  }

  @override
  void didUpdateWidget(PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showExitTestModal && !oldWidget.showExitTestModal) {
      _checkAndShowModal();
    }
  }

  Future<void> _checkAndShowModal() async {
    if (!widget.showExitTestModal) return;
    final prefs = await SharedPreferences.getInstance();
    final hasShownExitTestModal = prefs.getBool('hasShownExitTestModal') ?? false;
    if (!hasShownExitTestModal && !_hasShownModal) {
      _hasShownModal = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showExitTestModal());
    }
  }

  Future<void> _showExitTestModal() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasShownExitTestModal', true);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FuncyImage(FuncyPose.celebra, size: 150, semanticLabel: 'Funcy celebrando'),
                const SizedBox(height: 12),
                Text('¡Completaste los 21 días!', style: textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Haz tu test de salida para ver cuánto avanzaste y obtener tu certificado.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Hacer test de salida',
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    widget.onStartExitTest?.call();
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Más tarde'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Programa> get _parsedProgramas {
    final list = widget.programas
        .where((p) => p['nombre_tecnica'] != null && p['nombre_tecnica'].toString().isNotEmpty)
        .map((p) => Programa.fromMap(Map<String, dynamic>.from(p)))
        .toList();
    list.sort((a, b) => a.dia.compareTo(b.dia));
    return list;
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    final saludo = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';
    final name = widget.userName;
    return (name == null || name.isEmpty) ? saludo : '$saludo, $name';
  }

  Future<void> _openProgram(Programa programa) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StepScreen(
          steps: programa.parsedSteps,
          tecnicaNombre: programa.nombreTecnica,
          tecnicaTipo: programa.tipoTecnica,
          dia: programa.dia,
          userId: programa.userId,
          tecnicaId: programa.id,
          url_img: programa.urlImg ?? '',
          sessionId: programa.id,
        ),
      ),
    );
    // Al volver, se actualiza el plan (por si se completó la actividad).
    await widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        ..._buildBody(context),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: widget.onRefresh == null
                ? content
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: widget.onRefresh!,
                    child: content,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = widget.userName ?? '';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Mi plan', style: textTheme.headlineMedium),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Ir a mi perfil',
            excludeSemantics: true,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onOpenProfile,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.lavenderStrong,
                foregroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
                child: Text(
                  initial,
                  style: const TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return const [SliverToBoxAdapter(child: _PlanSkeleton())];
    }

    if (widget.loadFailed) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: ErrorStateView(
              title: 'No pudimos cargar tu plan',
              message: 'Revisa tu conexión a internet e inténtalo de nuevo. Tu progreso está guardado y no se perderá.',
              onRetry: widget.onRefresh,
            ),
          ),
        ),
      ];
    }

    final programas = _parsedProgramas;
    if (programas.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: ErrorStateView(
              pose: FuncyPose.medita,
              title: 'Tu plan se está preparando',
              message: 'En unos minutos verás aquí tus actividades. Desliza hacia abajo para actualizar.',
              retryLabel: 'Actualizar',
              onRetry: widget.onRefresh,
            ),
          ),
        ),
      ];
    }

    final completedCount = programas.where((p) => p.isCompleted).length;
    final streak = computeStreak(programas);
    final today = programas.where((p) => p.isUnlocked && !p.isCompleted).cast<Programa?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    final nextLocked = programas.where((p) => !p.isUnlocked && !p.isCompleted).cast<Programa?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    final currentDay = today?.dia ?? (completedCount + 1).clamp(1, totalProgramDays);

    return [
      SliverToBoxAdapter(
        child: _ProgressCard(
          currentDay: currentDay,
          completed: completedCount,
          streak: streak,
        ),
      ),
      if (widget.showExitTestModal && widget.onStartExitTest != null)
        SliverToBoxAdapter(child: _ExitTestCard(onStart: widget.onStartExitTest!)),
      SliverToBoxAdapter(child: _SectionTitle(title: 'Para hoy')),
      SliverToBoxAdapter(
        child: today != null
            ? _TodayCard(programa: today, onStart: () => _openProgram(today))
            : _DoneForTodayCard(next: nextLocked, allDone: completedCount >= programas.length),
      ),
      SliverToBoxAdapter(child: _SectionTitle(title: 'Tu recorrido')),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < programas.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _DayRow(
                    programa: programas[i],
                    isToday: identical(programas[i], today),
                    onTap: programas[i].isUnlocked ? () => _openProgram(programas[i]) : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.currentDay, required this.completed, required this.streak});

  final int currentDay;
  final int completed;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = ((completed / totalProgramDays) * 100).round();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Día $currentDay de $totalProgramDays',
                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('$percent%', style: textTheme.labelMedium?.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Progreso del programa: $percent por ciento',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: completed / totalProgramDays,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (streak > 0)
                _Chip(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.streak,
                  label: streak == 1 ? 'Racha de 1 día' : 'Racha de $streak días',
                  background: AppColors.streakBg,
                  foreground: AppColors.streakText,
                ),
              _Chip(
                icon: Icons.check_rounded,
                iconColor: AppColors.successText,
                label: completed == 1 ? '1 completado' : '$completed completados',
                background: AppColors.successBg,
                foreground: AppColors.successText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      height: 30,
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.programa, required this.onStart});

  final Programa programa;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final steps = programa.parsedSteps.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ProgramImage(url: programa.imageUrl),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryDeep),
                        const SizedBox(width: 6),
                        Text('${programa.dayLabel} · Hoy',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDeep)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(programa.nombreTecnica, style: textTheme.titleMedium),
                if ((programa.descripcion ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    programa.descripcion!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary, fontWeight: FontWeight.w400),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: traducirTipoTecnica(programa.tipoTecnica),
                      background: AppColors.lavender,
                      foreground: AppColors.primaryDeep,
                    ),
                    const _Chip(
                      icon: Icons.schedule_rounded,
                      label: '5–10 min',
                      background: AppColors.muted,
                      foreground: AppColors.inkSecondary,
                    ),
                    if (steps > 0)
                      _Chip(
                        label: steps == 1 ? '1 paso' : '$steps pasos',
                        background: AppColors.muted,
                        foreground: AppColors.inkSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                AppPrimaryButton(label: 'Empezar actividad', icon: Icons.play_arrow_rounded, onPressed: onStart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneForTodayCard extends StatelessWidget {
  const _DoneForTodayCard({required this.next, required this.allDone});

  final Programa? next;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nextDate = next?.startDateTime;
    final message = allDone
        ? 'Terminaste todas las actividades de tu programa. ¡Excelente trabajo!'
        : next == null
            ? 'Vuelve mañana para tu siguiente actividad.'
            : 'Tu siguiente actividad, ${next!.dayLabel}: ${next!.nombreTecnica}, se desbloquea '
                '${nextDate == null ? 'al completar la anterior' : DateFormatEs.relative(nextDate)}.';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const FuncyImage(FuncyPose.celebra, size: 92),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(allDone ? '¡Programa completado!' : '¡Actividad de hoy lista!', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(message, style: textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExitTestCard extends StatelessWidget {
  const _ExitTestCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(color: AppColors.night, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Test de salida disponible',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Descubre cuánto avanzaste y obtén tu certificado.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 20 / 14)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDeep,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text('Hacer test de salida'),
                ),
              ],
            ),
          ),
          const FuncyImage(FuncyPose.emocionado, size: 96),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.programa, required this.isToday, this.onTap});

  final Programa programa;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final completed = programa.isCompleted;
    final unlocked = programa.isUnlocked;

    final Widget leading;
    final String subtitle;
    final Color subtitleColor;

    if (completed) {
      leading = const _RowIcon(background: AppColors.successBg, child: Icon(Icons.check_rounded, size: 20, color: AppColors.success));
      final date = programa.completedDateTime;
      subtitle = date == null ? 'Completado' : 'Completado ${DateFormatEs.relative(date)}';
      subtitleColor = AppColors.successText;
    } else if (unlocked) {
      leading = _RowIcon(
        background: isToday ? AppColors.primary : AppColors.lavender,
        child: Text(
          '${programa.dia}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: isToday ? Colors.white : AppColors.primaryDeep,
          ),
        ),
      );
      subtitle = isToday ? 'Disponible hoy' : 'Pendiente';
      subtitleColor = AppColors.primaryDeep;
    } else {
      leading = const _RowIcon(background: AppColors.muted, child: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.inkTertiary));
      final start = programa.startDateTime;
      subtitle = start == null ? 'Se desbloquea al completar el anterior' : 'Se desbloquea ${DateFormatEs.relative(start)}';
      subtitleColor = AppColors.inkTertiary;
    }

    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${programa.dayLabel} · ${programa.nombreTecnica}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: unlocked || completed ? AppColors.ink : AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600, color: subtitleColor)),
                  ],
                ),
              ),
              SizedBox(
                width: 36,
                child: onTap == null
                    ? null
                    : const Icon(Icons.chevron_right_rounded, color: AppColors.inkTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _ProgramImage extends StatelessWidget {
  const _ProgramImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.lavender,
      alignment: Alignment.center,
      child: const FuncyImage(FuncyPose.medita, size: 110),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: frame == null ? placeholder : child,
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [SkeletonBox(width: 96, height: 16), Spacer(), SkeletonBox(width: 36, height: 16)]),
                  SizedBox(height: 14),
                  SkeletonBox(height: 8),
                  SizedBox(height: 14),
                  Row(children: [SkeletonBox(width: 128, height: 30), SizedBox(width: 8), SkeletonBox(width: 112, height: 30)]),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SkeletonBox(width: 84, height: 16, color: Color(0xFFE6E2EF)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 140, radius: 0),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 180, height: 18),
                        SizedBox(height: 10),
                        SkeletonBox(width: 260, height: 12, color: AppColors.divider),
                        SizedBox(height: 16),
                        SkeletonBox(height: 52),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const SkeletonBox(width: 110, height: 16, color: Color(0xFFE6E2EF)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  SkeletonBox(width: 36, height: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 170, height: 13),
                        SizedBox(height: 8),
                        SkeletonBox(width: 104, height: 11, color: AppColors.divider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
