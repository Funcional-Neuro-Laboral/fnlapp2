import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fnlapp/Main/finalstepscreen.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../Util/api_service.dart';
import '../Util/translations.dart';
import 'completed_dia_screen.dart';

class StepScreen extends StatefulWidget {
  final List<String> steps;
  final String tecnicaNombre;
  final String tecnicaTipo;
  final int dia;
  final int userId;
  final int tecnicaId;
  final String url_img;
  final int sessionId;

  const StepScreen({
    Key? key,
    required this.steps,
    required this.tecnicaNombre,
    required this.tecnicaTipo,
    required this.dia,
    required this.userId,
    required this.tecnicaId,
    required this.url_img,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  static const _autoAdvanceSeconds = 10;
  static const _textSizes = [17.0, 20.0, 24.0];
  static const _textSizeLabels = ['pequeño', 'mediano', 'grande'];

  int currentStep = 0;
  bool isPlaying = false;
  bool isLoading = false;
  double textSize = 20.0;
  bool isMuted = false;
  bool _isPaused = false;
  AudioPlayer? currentPlayer;
  StreamSubscription<PlayerState>? _playerSubscription;
  Timer? _delayTimer;
  bool _isInDelay = false;
  int _remainingSeconds = _autoAdvanceSeconds;
  final Map<int, AudioSource> _cachedAudioSources = {};
  bool _isPreloadingAudio = true;

  List<String> get _steps => widget.steps.isEmpty ? const ['Respira profundo y tómate un momento para ti.'] : widget.steps;

  bool get _isLastStep => currentStep >= _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _loadTextSize();
    _preloadAllAudio();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _playerSubscription?.cancel();
    currentPlayer?.dispose();
    super.dispose();
  }

  Future<void> _loadTextSize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('stepTextSize');
    if (saved != null && mounted) setState(() => textSize = saved);
  }

  Future<void> _setTextSize(double value) async {
    setState(() => textSize = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('stepTextSize', value);
  }

  String _getImageUrlByDay() {
    if (widget.dia >= 1 && widget.dia <= 21) {
      return 'https://funkyrecursos.s3.us-east-2.amazonaws.com/recursos_nuevos2/DIA${widget.dia}.png';
    }
    return widget.url_img;
  }

  /// URL del audio de un paso, con el texto codificado correctamente.
  Uri _ttsUri(String text) =>
      Uri.parse('${Config.apiUrl2}/general/speech/tts/').replace(queryParameters: {'text': text});

  // ========== AUDIO ==========

  Future<void> _preloadAllAudio() async {
    try {
      // Las descargas se hacen en paralelo para que el audio esté listo antes.
      await Future.wait([
        for (var i = 0; i < _steps.length; i++)
          _downloadAudioForStep(_steps[i], i).then((source) {
            if (source != null && mounted) {
              setState(() => _cachedAudioSources[i] = source);
            }
          }),
      ]);
    } catch (e) {
      debugPrint('Error precargando audios: $e');
    } finally {
      if (mounted) setState(() => _isPreloadingAudio = false);
    }
  }

  Future<AudioSource?> _downloadAudioForStep(String text, int stepIndex) async {
    try {
      final response = await http.get(_ttsUri(text));
      if (response.statusCode == 200) {
        final audioBytes = response.bodyBytes;
        if (kIsWeb) {
          return AudioSource.uri(Uri.parse('data:audio/mp3;base64,${base64Encode(audioBytes)}'));
        }
        final tempDir = await getTemporaryDirectory();
        final audioFile =
            File('${tempDir.path}/speech_step_${stepIndex}_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await audioFile.writeAsBytes(audioBytes);
        return AudioSource.file(audioFile.path);
      }
    } catch (e) {
      debugPrint('Error descargando audio para paso $stepIndex: $e');
    }
    return null;
  }

  void _setupPlayerStateListener() {
    _playerSubscription?.cancel();
    _playerSubscription = currentPlayer?.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed && !_isPaused && isPlaying) {
        _handleAudioComplete();
      }
      if (state.playing != isPlaying && !_isInDelay && state.processingState != ProcessingState.completed) {
        setState(() {
          isPlaying = state.playing;
          _isPaused = !state.playing;
        });
      }
    });
  }

  Future<void> _playAudioFromAPI(String text) async {
    if (isPlaying && !_isPaused) return;

    setState(() {
      isPlaying = true;
      _isPaused = false;
      _isInDelay = false;
    });
    _cancelDelayTimer();

    try {
      var audioSource = _cachedAudioSources[currentStep];
      audioSource ??= await _downloadAudioForStep(text, currentStep);
      if (audioSource == null) throw Exception('Audio no disponible');
      if (!mounted) return;

      await _playerSubscription?.cancel();
      await currentPlayer?.dispose();
      currentPlayer = AudioPlayer();
      await currentPlayer!.setVolume(isMuted ? 0.0 : 1.0);
      await currentPlayer!.setAudioSource(audioSource);
      _setupPlayerStateListener();
      await currentPlayer!.play();
    } catch (e) {
      debugPrint('Error en la reproducción de audio: $e');
      if (mounted) {
        setState(() {
          isPlaying = false;
          _isPaused = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos reproducir el audio. Puedes seguir leyendo el paso.')),
        );
      }
    }
  }

  void _handleAudioComplete() {
    if (_isInDelay) return;
    if (!_isLastStep) {
      _startDelayTimer();
    } else {
      setState(() {
        isPlaying = false;
        _isInDelay = false;
        _isPaused = false;
      });
    }
  }

  void _startDelayTimer() {
    setState(() {
      _isInDelay = true;
      _remainingSeconds = _autoAdvanceSeconds;
    });
    _runDelayTimer();
  }

  void _runDelayTimer() {
    _delayTimer?.cancel();
    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        if (!_isPaused) _autoAdvanceToNextStep();
      }
    });
  }

  void _autoAdvanceToNextStep() {
    setState(() {
      isPlaying = false;
      _isInDelay = false;
    });
    if (!_isLastStep) _handleNextStep();
  }

  void _cancelDelayTimer() {
    _delayTimer?.cancel();
    _delayTimer = null;
    if (!mounted) return;
    setState(() {
      _isInDelay = false;
      _remainingSeconds = _autoAdvanceSeconds;
    });
  }

  Future<void> _pauseAudio() async {
    try {
      await currentPlayer?.pause();
      _cancelDelayTimer();
      if (mounted) {
        setState(() {
          isPlaying = false;
          _isPaused = true;
        });
      }
    } catch (e) {
      debugPrint('Error al pausar audio: $e');
    }
  }

  Future<void> _stopCurrentAudio() async {
    await _playerSubscription?.cancel();
    _playerSubscription = null;
    if (currentPlayer != null) {
      await currentPlayer?.stop();
      await currentPlayer?.dispose();
      currentPlayer = null;
    }
    _cancelDelayTimer();
    if (!mounted) return;
    setState(() {
      isPlaying = false;
      _isPaused = false;
      _isInDelay = false;
    });
  }

  Future<void> _resumeAudio() async {
    if (!_isPaused || currentPlayer == null) return;
    setState(() {
      isPlaying = true;
      _isPaused = false;
    });
    try {
      await currentPlayer?.play();
    } catch (e) {
      debugPrint('Error al reanudar audio: $e');
      if (mounted) {
        setState(() {
          isPlaying = false;
          _isPaused = true;
        });
      }
    }
  }

  void _pauseDelay() {
    _delayTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _resumeFromDelay() {
    setState(() => _isPaused = false);
    _runDelayTimer();
  }

  // ========== NAVEGACIÓN ENTRE PASOS ==========

  Future<void> _handleNextStep() async {
    await _stopCurrentAudio();
    if (!_isLastStep) {
      setState(() => currentStep++);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) await _playAudioFromAPI(_steps[currentStep]);
    } else {
      await _navigateToNextScreen();
    }
  }

  Future<void> _handlePreviousStep() async {
    if (currentStep == 0) return;
    await _stopCurrentAudio();
    setState(() => currentStep--);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) await _playAudioFromAPI(_steps[currentStep]);
  }

  Future<void> _navigateToNextScreen() async {
    await _stopCurrentAudio();
    setState(() => isLoading = true);

    var alreadyCompleted = false;
    try {
      final response = await ApiService().get('users/daily-activities?userId=${widget.userId}');
      final data = json.decode(response.body);
      final userProgramas = List<Map<String, dynamic>>.from(data['userProgramas'] ?? []);
      final currentProgram = userProgramas.firstWhere(
        (p) => int.tryParse(p['dia'].toString()) == widget.dia,
        orElse: () => {},
      );
      alreadyCompleted = currentProgram['completed'] == true || currentProgram['completed_date'] != null;
    } catch (e) {
      debugPrint('No se pudo verificar si el día está completado: $e');
    }

    if (!mounted) return;
    setState(() => isLoading = false);

    if (alreadyCompleted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CompletedDiaScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinalStepScreen(
            userId: widget.userId,
            tecnicaId: widget.tecnicaId,
            sessionId: widget.sessionId,
            dia: widget.dia,
          ),
        ),
      );
    }
  }

  // ========== UI ==========

  IconData _playIcon() {
    if (_isInDelay) return _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded;
    if (_isPaused && currentPlayer != null) return Icons.play_arrow_rounded;
    if (isPlaying && !_isPaused) return Icons.pause_rounded;
    return Icons.play_arrow_rounded;
  }

  String _playLabel() => _playIcon() == Icons.pause_rounded ? 'Pausar' : 'Reproducir';

  VoidCallback? _playAction() {
    if (_isInDelay) return _isPaused ? _resumeFromDelay : _pauseDelay;
    if (_isPaused) return _resumeAudio;
    if (isPlaying) return _pauseAudio;
    return () => _playAudioFromAPI(_steps[currentStep]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remainingMinutes = (_steps.length - currentStep - 1).clamp(1, 99);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    children: [
                      ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var i = 0; i < _steps.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i <= currentStep ? AppColors.primary : const Color(0xFFE6E2F0),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text('Paso ${currentStep + 1} de ${_steps.length}',
                                  style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          Text('≈ $remainingMinutes min restantes',
                              style: const TextStyle(fontSize: 13, color: AppColors.inkTertiary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(height: 176, child: _StepImage(url: _getImageUrlByDay())),
                        ),
                        const SizedBox(height: 14),
                        Text(widget.tecnicaNombre, style: textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('${traducirTipoTecnica(widget.tecnicaTipo)} · 5–10 min',
                            style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
                        const SizedBox(height: 12),
                        _buildTextSizeControl(),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Text(
                              _steps[currentStep],
                              key: ValueKey(currentStep),
                              style: TextStyle(fontSize: textSize, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatusRow(),
                ),
                _buildControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver a mi plan',
            onPressed: () => Navigator.of(context).maybePop(),
            style: IconButton.styleFrom(backgroundColor: AppColors.muted, minimumSize: const Size(44, 44)),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
          ),
          Expanded(
            child: Text(
              'Día ${widget.dia.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: isMuted ? 'Activar sonido' : 'Silenciar audio',
            onPressed: () {
              setState(() => isMuted = !isMuted);
              currentPlayer?.setVolume(isMuted ? 0.0 : 1.0);
            },
            style: IconButton.styleFrom(backgroundColor: AppColors.muted, minimumSize: const Size(44, 44)),
            icon: Icon(isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 21, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizeControl() {
    return Row(
      children: [
        const Expanded(
          child: Text('Tamaño del texto',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _textSizes.length; i++)
                Semantics(
                  button: true,
                  selected: textSize == _textSizes[i],
                  label: 'Texto ${_textSizeLabels[i]}',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _setTextSize(_textSizes[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: textSize == _textSizes[i] ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: textSize == _textSizes[i]
                            ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.14), blurRadius: 4, offset: const Offset(0, 1))]
                            : null,
                      ),
                      child: Text(
                        'A',
                        style: TextStyle(
                          fontSize: 13.0 + i * 4,
                          fontWeight: FontWeight.w800,
                          color: textSize == _textSizes[i] ? AppColors.primaryDeep : AppColors.inkSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    final Widget content;
    if (_isInDelay) {
      content = Row(
        key: const ValueKey('delay'),
        children: [
          const Icon(Icons.schedule_rounded, size: 18, color: AppColors.primaryDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isPaused ? 'Avance automático en pausa' : 'Siguiente paso en $_remainingSeconds s',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDeep),
            ),
          ),
          SizedBox(
            width: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: 1 - (_remainingSeconds / _autoAdvanceSeconds),
                minHeight: 4,
                backgroundColor: const Color(0xFFE6E2F0),
              ),
            ),
          ),
        ],
      );
    } else if (isPlaying) {
      content = const Row(
        key: ValueKey('playing'),
        children: [
          Icon(Icons.graphic_eq_rounded, size: 18, color: AppColors.primaryDeep),
          SizedBox(width: 8),
          Text('Reproduciendo…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDeep)),
        ],
      );
    } else if (!_cachedAudioSources.containsKey(currentStep) && _isPreloadingAudio) {
      content = const Row(
        key: ValueKey('loading'),
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 10),
          Text('Preparando el audio…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
        ],
      );
    } else if (!_cachedAudioSources.containsKey(currentStep)) {
      content = const Row(
        key: ValueKey('unavailable'),
        children: [
          Icon(Icons.volume_off_outlined, size: 18, color: AppColors.inkSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text('Audio no disponible ahora · puedes leer el paso',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
          ),
        ],
      );
    } else {
      content = const Row(
        key: ValueKey('ready'),
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
          SizedBox(width: 8),
          Expanded(
            child: Text('Audio listo · pulsa Reproducir para escuchar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.successText)),
          ),
        ],
      );
    }
    return Semantics(
      liveRegion: true,
      child: SizedBox(
        height: 36,
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: content),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            label: 'Anterior',
            icon: Icons.skip_previous_rounded,
            onPressed: currentStep > 0 && !isLoading ? _handlePreviousStep : null,
          ),
          _ControlButton(
            label: _playLabel(),
            icon: _playIcon(),
            primary: true,
            onPressed: isLoading ? null : _playAction(),
          ),
          _isLastStep
              ? _ControlButton(
                  label: 'Finalizar',
                  icon: Icons.check_rounded,
                  success: true,
                  loading: isLoading,
                  onPressed: isLoading ? null : _handleNextStep,
                )
              : _ControlButton(
                  label: 'Siguiente',
                  icon: Icons.skip_next_rounded,
                  onPressed: isLoading ? null : _handleNextStep,
                ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.success = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool success;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final size = primary ? 72.0 : 56.0;
    final background = primary
        ? AppColors.primary
        : success
            ? AppColors.success
            : AppColors.muted;
    final foreground = primary || success ? Colors.white : AppColors.ink;
    final labelColor = primary
        ? AppColors.primaryDeep
        : success
            ? AppColors.successText
            : AppColors.inkSecondary;

    return SizedBox(
      width: primary ? 96 : 72,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: Opacity(
              opacity: onPressed == null && !loading ? 0.4 : 1,
              child: Material(
                color: background,
                shape: const CircleBorder(),
                elevation: primary ? 6 : 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: loading
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            ),
                          )
                        : Icon(icon, size: primary ? 34 : 28, color: foreground),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: primary || success ? FontWeight.w700 : FontWeight.w600, color: labelColor)),
        ],
      ),
    );
  }
}

class _StepImage extends StatelessWidget {
  const _StepImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.lavender,
      alignment: Alignment.center,
      child: const FuncyImage(FuncyPose.medita, size: 130),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: frame == null ? placeholder : child);
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
