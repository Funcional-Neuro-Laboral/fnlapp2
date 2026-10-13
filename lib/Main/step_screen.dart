import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:fnlapp/Main/finalstepscreen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Util/translations.dart';
import '../config.dart';
import 'completed_dia_screen.dart';
import 'dart:async';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
  static const label = Color(0xFF5F668B);
  static const border = Color(0xFFD9DCEF);
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

  static TextStyle body({
    double size = 16,
    Color color = _FnlColors.body,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.roboto(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.5,
      );

  static TextStyle label({
    double size = 14,
    Color color = _FnlColors.label,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: letterSpacing,
      );
}

class StepScreen extends StatefulWidget {
  final List<String> steps;
  final List<String> ttsUrls;
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
    this.ttsUrls = const [],
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
  int currentStep = 0;
  bool isPlaying = false;
  bool isLoading = false;
  final TextEditingController commentController = TextEditingController();
  double rating = 0;
  double textSize = 18.0;
  bool isMuted = false;
  bool _isPaused = false;
  AudioPlayer? currentPlayer;
  StreamSubscription<PlayerState>? _playerStateSub;
  Timer? _delayTimer;
  bool _isInDelay = false;
  int _remainingSeconds = 10;
  // URIs de audio ya validadas, una por paso (null si falta o es inválida)
  List<Uri?> _ttsUris = [];
  bool _isPreloadingAudio = true;
  // Se incrementa cada vez que se inicia/detiene audio
  int _playRequestId = 0;

  // Helper method para obtener el tipo de dispositivo
  DeviceType _getDeviceType(double width) {
    if (width < 600) return DeviceType.mobile;
    if (width < 1024) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // Helper method para obtener dimensiones responsivas
  ResponsiveDimensions _getResponsiveDimensions(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceType = _getDeviceType(size.width);

    switch (deviceType) {
      case DeviceType.mobile:
        return ResponsiveDimensions(
          padding: 20.0,
          imageHeight: (size.height * 0.30).clamp(180.0, 300.0).toDouble(),
          fontSize: 16.0,
          titleFontSize: 20.0,
          iconSize: 24.0,
          buttonWidth: size.width * 0.25,
          buttonHeight: 60.0,
          maxContentWidth: size.width,
        );
      case DeviceType.tablet:
        return ResponsiveDimensions(
          padding: 28.0,
          imageHeight: (size.height * 0.35).clamp(240.0, 400.0).toDouble(),
          fontSize: 18.0,
          titleFontSize: 22.0,
          iconSize: 28.0,
          buttonWidth: size.width * 0.2,
          buttonHeight: 64.0,
          maxContentWidth: (size.width * 0.8).clamp(0.0, 640.0).toDouble(),
        );
      case DeviceType.desktop:
        return ResponsiveDimensions(
          padding: 32.0,
          imageHeight: size.height * 0.45,
          fontSize: 20.0,
          titleFontSize: 26.0,
          iconSize: 32.0,
          buttonWidth: 140.0,
          buttonHeight: 64.0,
          maxContentWidth: 1200.0,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _preloadAllAudio();
  }

  String _getImageUrlByDay() {
    if (widget.dia >= 1 && widget.dia <= 21) {
      return 'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/recursos_nuevos2/DIA${widget.dia}.jpg';
    }
    return widget.url_img;
  }

  @override
  void dispose() {
    // Invalidar cualquier carga de audio en curso
    _playRequestId++;

    _delayTimer?.cancel();
    _delayTimer = null;

    _playerStateSub?.cancel();
    _playerStateSub = null;
    final player = currentPlayer;
    currentPlayer = null;
    player?.dispose();

    commentController.dispose();
    super.dispose();
  }

  Uri? _parseTtsUri(int index) {
    if (index < 0 || index >= widget.ttsUrls.length) return null;
    final raw = widget.ttsUrls[index].trim();
    if (raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return uri;
  }

  Uri? _getTtsUri(int index) {
    if (index < 0 || index >= _ttsUris.length) return null;
    return _ttsUris[index];
  }

  /// Ya no descarga ni genera audios, solo valida y prepara las URLs de TTS
  void _preloadAllAudio() {
    final uris = <Uri?>[];
    for (int i = 0; i < widget.steps.length; i++) {
      final uri = _parseTtsUri(i);
      if (uri == null) {
        debugPrint("Paso $i sin URL de TTS válida");
      }
      uris.add(uri);
    }
    _ttsUris = uris;
    _isPreloadingAudio = false;
  }

  /// Cancela la suscripción al estado y libera el player actual.
  Future<void> _disposePlayer() async {
    final sub = _playerStateSub;
    _playerStateSub = null;
    await sub?.cancel();

    final player = currentPlayer;
    currentPlayer = null;
    if (player != null) {
      try {
        await player.dispose();
      } catch (e) {
        debugPrint("Error al liberar el AudioPlayer: $e");
      }
    }
  }

  void _setupPlayerStateListener(AudioPlayer player) {
    _playerStateSub?.cancel();
    _playerStateSub = player.playerStateStream.listen((state) {
      // Ignorar eventos de un player que ya no es el actual
      if (!mounted || player != currentPlayer) return;

      // Manejar cambios de estado más granularmente
      if (state.processingState == ProcessingState.completed &&
          !_isPaused &&
          !_isInDelay &&
          isPlaying) {
        _handleAudioComplete();
      }

      if (state.playing != isPlaying && !_isInDelay) {
        setState(() {
          isPlaying = state.playing;
          _isPaused = !state.playing;
        });
      }
    });
  }

  /// Reproduce el audio del paso actual desde ttsUrls[currentStep].
  Future<void> _playStepAudio() async {
    if (isPlaying && !_isPaused) return;

    final requestId = ++_playRequestId;
    final stepIndex = currentStep;

    _cancelDelayTimer();

    final uri = _getTtsUri(stepIndex);
    if (uri == null) {
      debugPrint("No hay audio TTS disponible para el paso $stepIndex");
      await _disposePlayer();
      if (mounted && requestId == _playRequestId) {
        setState(() {
          isPlaying = false;
          _isPaused = false;
          _isInDelay = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isPlaying = true;
        _isPaused = false;
        _isInDelay = false;
      });
    }

    print('=== TTS DEBUG ===');
    print('Paso actual: $currentStep');
    print('Cantidad de URLs: ${widget.ttsUrls.length}');
    print('URL que intenta reproducir: $uri');

    try {
      // Liberar el player anterior antes de crear uno nuevo
      await _disposePlayer();
      if (!mounted || requestId != _playRequestId) return;

      final player = AudioPlayer();
      currentPlayer = player;

      await player.setVolume(isMuted ? 0.0 : 1.0);
      await player.setAudioSource(AudioSource.uri(uri));

      // Si mientras cargaba el usuario cambió de paso, salió o detuvo el audio
      if (!mounted || requestId != _playRequestId || currentPlayer != player) {
        if (currentPlayer == player) {
          await _disposePlayer();
        } else {
          await player.dispose();
        }
        return;
      }

      // Iniciar reproducción (sin await: el Future termina al acabar el audio)
      player.play().catchError((Object e) {
        debugPrint("Error durante la reproducción: $e");
      });

      // Configurar el listener después de iniciar la reproducción
      _setupPlayerStateListener(player);

      // Para móvil: verificar que el estado se actualizó correctamente
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted &&
          requestId == _playRequestId &&
          currentPlayer?.playing == true) {
        setState(() {
          isPlaying = true;
          _isPaused = false;
        });
      }
    } catch (e) {
      debugPrint("Error en la reproducción de audio: $e");
      if (mounted && requestId == _playRequestId) {
        await _disposePlayer();
        setState(() {
          isPlaying = false;
          _isPaused = false;
        });
      }
    }
  }

  void _handleAudioComplete() {
    if (currentStep < widget.steps.length - 1) {
      // Iniciar delay de 10 segundos
      _startDelayTimer();
    } else {
      // Es el último step, terminar
      setState(() {
        isPlaying = false;
        _isInDelay = false;
        _isPaused = false;
      });
    }
  }

  void _startDelayTimer() {
    _delayTimer?.cancel();
    setState(() {
      _isInDelay = true;
      _remainingSeconds = 10;
    });

    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          if (mounted && !_isPaused) {
            _autoAdvanceToNextStep();
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _autoAdvanceToNextStep() {
    // Solo avanzar si no es el último paso
    if (currentStep < widget.steps.length - 1) {
      setState(() {
        isPlaying = false;
        _isInDelay = false;
      });
      _handleNextStep();
    } else {
      // Si es el último paso, solo limpiar el estado
      setState(() {
        isPlaying = false;
        _isInDelay = false;
        _isPaused = false;
      });
    }
  }

  void _cancelDelayTimer() {
    _delayTimer?.cancel();
    _delayTimer = null;
    if (!mounted) return;
    setState(() {
      _isInDelay = false;
      _remainingSeconds = 10;
    });
  }

  Future<void> _stopAudio() async {
    try {
      // Pausar el audio actual
      await currentPlayer?.pause();

      // Cancelar el delay si está activo
      _cancelDelayTimer();

      if (mounted) {
        setState(() {
          isPlaying = false;
          _isPaused = true;
        });
      }

      // Pequeño delay y rebuild adicional para móvil
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error al pausar audio: $e");
    }
  }

  Future<void> _stopCurrentAudio() async {
    // Invalida cualquier carga de audio pendiente
    _playRequestId++;

    await _disposePlayer();
    _cancelDelayTimer();

    if (!mounted) return;
    setState(() {
      isPlaying = false;
      _isPaused = false;
      _isInDelay = false;
    });
  }

  Future<void> _resumeAudio() async {
    if (_isPaused && currentPlayer != null) {
      try {
        // Actualizar estado inmediatamente
        if (mounted) {
          setState(() {
            isPlaying = true;
            _isPaused = false;
          });
        }

        await Future.delayed(const Duration(milliseconds: 50));

        // Reanudar reproducción (sin await, termina al acabar el audio)
        currentPlayer?.play().catchError((Object e) {
          debugPrint("Error al reanudar audio: $e");
        });

        // Forzar un rebuild adicional para móvil
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint("Error al reanudar audio: $e");
        if (mounted) {
          setState(() {
            isPlaying = false;
            _isPaused = true;
          });
        }
      }
    }
  }

  Future<void> _handleNextStep() async {
    await _stopCurrentAudio();
    if (!mounted) return;

    if (currentStep < widget.steps.length - 1) {
      // Detener cualquier audio o delay actual

      setState(() {
        currentStep++;
      });

      // Pequeña pausa para que se actualice la UI
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // Reproducir el nuevo audio
      await _playStepAudio();
    } else {
      await _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    await _stopCurrentAudio();
    if (isPlaying) {
      await _stopAudio();
    }

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      if (mounted) {
        final String apiUrl =
            "${Config.apiUrl2}/users/daily-activities?userId=${widget.userId}";

        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final userProgramas =
              List<Map<String, dynamic>>.from(data['userProgramas']);

          // Buscar el programa del día actual
          final currentProgram = userProgramas.firstWhere(
            (programa) => programa['dia'] == widget.dia,
            orElse: () => {},
          );

          final bool isCompleted = currentProgram['completed'] ?? false;

          if (isCompleted) {
            // Si ya está completado, mostrar CompletedDiaScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CompletedDiaScreen(),
              ),
            );
          } else {
            // Si no está completado, mostrar FinalStepScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FinalStepScreen(
                  userId: widget.userId,
                  tecnicaId: widget.tecnicaId,
                  sessionId: widget.sessionId,
                ),
              ),
            );
          }
        } else {
          throw Exception('Error al verificar estado de completado');
        }
      }
    } catch (e) {
      debugPrint("Error al navegar: $e");
      // En caso de error, ir a FinalStepScreen por defecto
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalStepScreen(
              userId: widget.userId,
              tecnicaId: widget.tecnicaId,
              sessionId: widget.sessionId,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _handlePreviousStep() async {
    if (currentStep > 0) {
      // Detener audio y delay actual completamente (también libera el player)
      await _stopCurrentAudio();
      if (!mounted) return;

      setState(() {
        currentStep--;
        isPlaying = false;
        _isPaused = false;
        _isInDelay = false;
      });

      // Pequeña pausa para que se actualice la UI
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // Reproducir automáticamente el audio del paso anterior
      await _playStepAudio();
    }
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
      // Ajustar volumen del AudioPlayer actual
      currentPlayer?.setVolume(isMuted ? 0.0 : 1.0);
    });
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final deviceType = _getDeviceType(MediaQuery.of(context).size.width);

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
              child: deviceType == DeviceType.desktop
                  ? _buildDesktopLayout(dimensions)
                  : _buildMobileTabletLayout(dimensions, deviceType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ResponsiveDimensions dimensions) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dimensions.maxContentWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Panel izquierdo: encabezado + imagen
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(dimensions.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(dimensions),
                    const SizedBox(height: _FnlSpace.md),
                    Expanded(
                      child: _buildImageSection(dimensions, fill: true),
                    ),
                  ],
                ),
              ),
            ),

            // Panel derecho: información, texto y controles
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.all(dimensions.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTechniqueInfo(dimensions),
                    const SizedBox(height: _FnlSpace.sm),
                    _buildProgress(),
                    const SizedBox(height: _FnlSpace.sm),
                    _buildTextSizeControl(dimensions),
                    const SizedBox(height: _FnlSpace.sm),
                    Expanded(
                      child: _buildStepText(dimensions, scrollable: true),
                    ),
                    const SizedBox(height: _FnlSpace.sm),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildControlsContent(dimensions),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabletLayout(
      ResponsiveDimensions dimensions, DeviceType deviceType) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dimensions.maxContentWidth),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  dimensions.padding, _FnlSpace.xs + 4, dimensions.padding, 0),
              child: _buildHeader(dimensions),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  dimensions.padding,
                  _FnlSpace.sm,
                  dimensions.padding,
                  _FnlSpace.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTechniqueInfo(dimensions),
                    const SizedBox(height: _FnlSpace.sm),
                    _buildProgress(),
                    const SizedBox(height: _FnlSpace.sm),
                    _buildImageSection(dimensions),
                    const SizedBox(height: _FnlSpace.sm),
                    _buildTextSizeControl(dimensions),
                    const SizedBox(height: _FnlSpace.sm),
                    _buildStepText(dimensions),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                dimensions.padding,
                _FnlSpace.sm,
                dimensions.padding,
                _FnlSpace.sm,
              ),
              decoration: const BoxDecoration(
                color: _FnlColors.canvas,
                border: Border(
                  top: BorderSide(color: _FnlColors.lavenderDeep, width: 2),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildControlsContent(dimensions),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Encabezado: volver, título del día y silenciar.
  Widget _buildHeader(ResponsiveDimensions dimensions) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          tooltip: 'Volver',
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FUNCY · PRÁCTICA',
                style: _FnlText.label(
                  size: 12,
                  color: _FnlColors.violet,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Semantics(
                header: true,
                child: Text(
                  'Día ${widget.dia.toString().padLeft(2, '0')}',
                  style: _FnlText.h2(22),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _RoundIconButton(
          icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          tooltip: isMuted ? 'Activar sonido' : 'Silenciar',
          onTap: _toggleMute,
        ),
      ],
    );
  }

  /// Duración, tipo de técnica y nombre.
  Widget _buildTechniqueInfo(ResponsiveDimensions dimensions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _InfoPill(icon: Icons.access_time_rounded, text: '10 min'),
            const SizedBox(width: 8),
            Flexible(
              child: _InfoPill(text: traducirTipoTecnica(widget.tecnicaTipo)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            widget.tecnicaNombre,
            style: _FnlText.h1(dimensions.titleFontSize + 6),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final total = widget.steps.isEmpty ? 1 : widget.steps.length;
    final factor = ((currentStep + 1) / total).clamp(0.0, 1.0).toDouble();
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: 'Paso ${currentStep + 1} de $total',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASO ${currentStep + 1} DE $total',
                style: _FnlText.label(
                  size: 12,
                  color: _FnlColors.violet,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${(factor * 100).round()}%',
                style: _FnlText.label(size: 12, color: _FnlColors.body),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              width: double.infinity,
              color: _FnlColors.lavenderDeep,
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: factor),
                duration:
                    reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0).toDouble(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _FnlColors.violet,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ResponsiveDimensions dimensions,
      {bool fill = false}) {
    return Container(
      width: double.infinity,
      height: fill ? null : dimensions.imageHeight,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.network(
          _getImageUrlByDay(),
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: _FnlColors.lavender,
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _FnlColors.violet,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: _FnlColors.lavender,
              child: Icon(
                Icons.image_not_supported_rounded,
                size: dimensions.iconSize * 2,
                color: _FnlColors.body,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextSizeControl(ResponsiveDimensions dimensions) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TAMAÑO DE TEXTO',
            style: _FnlText.label(
              size: 12,
              color: _FnlColors.body,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SizeButton(
                icon: Icons.text_decrease_rounded,
                tooltip: 'Reducir texto',
                onTap: () {
                  setState(() {
                    if (textSize > 18.0) {
                      textSize = textSize == 22.0 ? 20.0 : 18.0;
                    }
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildTextSizeSlider()),
              const SizedBox(width: 12),
              _SizeButton(
                icon: Icons.text_increase_rounded,
                tooltip: 'Aumentar texto',
                onTap: () {
                  setState(() {
                    if (textSize < 22.0) {
                      textSize = textSize == 18.0 ? 20.0 : 22.0;
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizeSlider() {
    const double thumb = 22;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final travel = (width - thumb).clamp(1.0, double.infinity).toDouble();
        final factor = ((textSize - 18.0) / 4.0).clamp(0.0, 1.0).toDouble();

        void update(double dx) {
          final percentage = ((dx - thumb / 2) / travel).clamp(0.0, 1.0);
          final newSize = 18.0 + (percentage * 4.0);
          setState(() {
            if (newSize <= 19.0) {
              textSize = 18.0;
            } else if (newSize <= 21.0) {
              textSize = 20.0;
            } else {
              textSize = 22.0;
            }
          });
        }

        return Semantics(
          label: 'Tamaño de texto',
          value: '${textSize.toInt()}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => update(d.localPosition.dx),
            onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
            child: SizedBox(
              height: 36,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _FnlColors.lavenderDeep,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: travel * factor + thumb / 2,
                    decoration: BoxDecoration(
                      color: _FnlColors.violet,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Positioned(
                    left: travel * factor,
                    child: Container(
                      width: thumb,
                      height: thumb,
                      decoration: BoxDecoration(
                        color: _FnlColors.violet,
                        shape: BoxShape.circle,
                        border: Border.all(color: _FnlColors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: _FnlColors.bubbleBorder,
                            blurRadius: 6,
                            offset: Offset(0, 2),
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
    );
  }

  Widget _buildStepText(ResponsiveDimensions dimensions,
      {bool scrollable = false}) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final text = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      child: Align(
        key: ValueKey<int>(currentStep),
        alignment: Alignment.centerLeft,
        child: Text(
          widget.steps[currentStep],
          textAlign: TextAlign.left,
          style: _FnlText.body(
            size: textSize,
            color: _FnlColors.blue,
          ).copyWith(height: 1.6),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_FnlSpace.md),
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
      child: scrollable ? SingleChildScrollView(child: text) : text,
    );
  }

  Widget _buildControlsContent(ResponsiveDimensions dimensions) {
    final isLastStep = currentStep == widget.steps.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isInDelay
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: _InfoPill(
                      icon: _isPaused
                          ? Icons.pause_circle_outline_rounded
                          : Icons.timer_outlined,
                      text: _isPaused
                          ? 'En pausa'
                          : 'Siguiente paso en $_remainingSeconds s',
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildControlButton(
                icon: Icons.skip_previous_rounded,
                label: 'Paso anterior',
                onPressed: currentStep > 0 ? _handlePreviousStep : null,
                dimensions: dimensions,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildControlButton(
                icon: _getPlayButtonIcon(),
                label: _getPlayButtonIcon() == Icons.pause
                    ? 'Pausar'
                    : 'Reproducir',
                onPressed: _getPlayButtonAction(),
                isPrimary: true,
                dimensions: dimensions,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildControlButton(
                icon: isLastStep
                    ? Icons.check_rounded
                    : Icons.skip_next_rounded,
                label: isLastStep ? 'Finalizar' : 'Siguiente paso',
                onPressed: isLoading ? null : _handleNextStep,
                isLoading: isLoading,
                dimensions: dimensions,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getPlayButtonIcon() {
    // Si está en delay, mostrar pause/play según si está pausado
    if (_isInDelay) {
      return _isPaused ? Icons.play_arrow : Icons.pause;
    }

    // Si hay audio pausado, mostrar play
    if (_isPaused && currentPlayer != null) {
      return Icons.play_arrow;
    }

    // Si está reproduciendo, mostrar pause
    if (isPlaying && !_isPaused) {
      return Icons.pause;
    }

    // Por defecto mostrar play
    return Icons.play_arrow;
  }

  VoidCallback? _getPlayButtonAction() {
    if (_isInDelay) {
      // Durante el delay, el botón pausa/reanuda el delay
      return () {
        if (_isPaused) {
          _resumeFromDelay();
        } else {
          _pauseDelay();
        }
      };
    } else if (_isPaused) {
      // Audio pausado, reanudar
      return _resumeAudio;
    } else if (isPlaying) {
      // Audio reproduciéndose, pausar
      return _stopAudio;
    } else {
      // No hay audio, iniciar reproducción del paso actual
      return () => _playStepAudio();
    }
  }

  void _pauseDelay() {
    _delayTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeFromDelay() {
    setState(() {
      _isPaused = false;
    });

    // Reanudar el timer con el tiempo restante
    _delayTimer?.cancel();
    _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          if (mounted && !_isPaused) {
            _autoAdvanceToNextStep();
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isLoading = false,
    required ResponsiveDimensions dimensions,
  }) {
    final radius = BorderRadius.circular(18);
    final enabled = onPressed != null;
    final fg = isPrimary ? _FnlColors.white : _FnlColors.violet;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: (enabled || isLoading) ? 1 : 0.45,
        child: Container(
          height: isPrimary ? 60 : 56,
          decoration: BoxDecoration(
            color: isPrimary ? _FnlColors.violet : _FnlColors.lavender,
            borderRadius: radius,
            border: isPrimary
                ? null
                : Border.all(color: _FnlColors.bubbleBorder, width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Icon(icon, size: 30, color: fg),
              ),
            ),
          ),
        ),
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: _FnlColors.lavender,
          shape: const CircleBorder(
            side: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 20, color: _FnlColors.violet),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SizeButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: _FnlColors.white,
          shape: const CircleBorder(
            side: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: _FnlColors.violet),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData? icon;
  final String text;

  const _InfoPill({this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _FnlColors.violet),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _FnlText.label(size: 13, color: _FnlColors.violet),
            ),
          ),
        ],
      ),
    );
  }
}

// Enums y clases auxiliares para la responsividad
enum DeviceType { mobile, tablet, desktop }

class ResponsiveDimensions {
  final double padding;
  final double imageHeight;
  final double fontSize;
  final double titleFontSize;
  final double iconSize;
  final double buttonWidth;
  final double buttonHeight;
  final double maxContentWidth;

  ResponsiveDimensions({
    required this.padding,
    required this.imageHeight,
    required this.fontSize,
    required this.titleFontSize,
    required this.iconSize,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.maxContentWidth,
  });
}