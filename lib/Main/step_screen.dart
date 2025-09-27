import 'package:flutter/material.dart';
import 'package:fnlapp/Main/finalstepscreen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config.dart';
import 'completed_dia_screen.dart';
import 'dart:async';

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
  int currentStep = 0;
  bool isPlaying = false;
  bool isLoading = false;
  final TextEditingController commentController = TextEditingController();
  double rating = 0;
  double textSize = 18.0;
  bool isMuted = false;
  bool _isPaused = false;
  AudioPlayer? currentPlayer;
  Timer? _delayTimer;
  bool _isInDelay = false;
  int _remainingSeconds = 10;
  Map<int, AudioSource> _cachedAudioSources = {};
  bool _isPreloadingAudio = true;

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
          padding: 16.0,
          imageHeight: size.height * 0.35,
          fontSize: 16.0,
          titleFontSize: 17.0,
          iconSize: 24.0,
          buttonWidth: size.width * 0.25,
          buttonHeight: 60.0,
          maxContentWidth: size.width,
        );
      case DeviceType.tablet:
        return ResponsiveDimensions(
          padding: 24.0,
          imageHeight: size.height * 0.4,
          fontSize: 18.0,
          titleFontSize: 20.0,
          iconSize: 28.0,
          buttonWidth: size.width * 0.2,
          buttonHeight: 70.0,
          maxContentWidth: size.width * 0.8,
        );
      case DeviceType.desktop:
        return ResponsiveDimensions(
          padding: 32.0,
          imageHeight: size.height * 0.45,
          fontSize: 20.0,
          titleFontSize: 24.0,
          iconSize: 32.0,
          buttonWidth: 140.0,
          buttonHeight: 80.0,
          maxContentWidth: 800.0,
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
      return 'https://funkyrecursos.s3.us-east-2.amazonaws.com/recursos_nuevos2/DIA${widget.dia}.png';
    }
    return widget.url_img;
  }

  @override
  void dispose() {
    commentController.dispose();
    currentPlayer?.dispose();
    _cancelDelayTimer();
    super.dispose();
  }

  Future<void> _preloadAllAudio() async {
    setState(() {
      _isPreloadingAudio = true;
    });

    try {
      for (int i = 0; i < widget.steps.length; i++) {
        final audioSource = await _downloadAudioForStep(widget.steps[i], i);
        if (audioSource != null) {
          _cachedAudioSources[i] = audioSource;
        }
      }
    } catch (e) {
      debugPrint("Error precargando audios: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isPreloadingAudio = false;
        });
      }
    }
  }

  Future<AudioSource?> _downloadAudioForStep(String text, int stepIndex) async {
    try {
      final url = Uri.parse('${Config.apiUrl2}/general/speech/tts/?text=$text');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final audioBytes = response.bodyBytes;

        if (kIsWeb) {
          final base64Audio = base64Encode(audioBytes);
          final dataUri = 'data:audio/mp3;base64,$base64Audio';
          return AudioSource.uri(Uri.parse(dataUri));
        } else {
          final tempDir = await getTemporaryDirectory();
          final audioFile = File('${tempDir.path}/speech_step_${stepIndex}_${DateTime.now().millisecondsSinceEpoch}.mp3');
          await audioFile.writeAsBytes(audioBytes);
          return AudioSource.file(audioFile.path);
        }
      }
    } catch (e) {
      debugPrint("Error descargando audio para paso $stepIndex: $e");
    }
    return null;
  }

  void _setupPlayerStateListener() {
    currentPlayer?.playerStateStream.listen((state) {
      if (mounted) {
        // Manejar cambios de estado más granularmente
        if (state.processingState == ProcessingState.completed &&
            !_isPaused &&
            isPlaying) {
          _handleAudioComplete();
        }

        // Para móvil: sincronizar el estado del widget con el estado real del player
        if (state.playing != isPlaying && !_isInDelay) {
          setState(() {
            isPlaying = state.playing;
            _isPaused = !state.playing;
          });
        }
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
      // Usar audio precargado si está disponible
      AudioSource? audioSource = _cachedAudioSources[currentStep];

      if (audioSource != null) {
        currentPlayer = AudioPlayer();
        await currentPlayer?.setVolume(isMuted ? 0.0 : 1.0);
        await currentPlayer?.setAudioSource(audioSource);
      } else {
        // Fallback: descargar en tiempo real si no está en cache
        final url = Uri.parse('${Config.apiUrl2}/general/speech/tts/?text=$text');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final audioBytes = response.bodyBytes;
          currentPlayer = AudioPlayer();
          await currentPlayer?.setVolume(isMuted ? 0.0 : 1.0);

          if (kIsWeb) {
            final base64Audio = base64Encode(audioBytes);
            final dataUri = 'data:audio/mp3;base64,$base64Audio';
            await currentPlayer?.setAudioSource(
                AudioSource.uri(Uri.parse(dataUri))
            );
          } else {
            final tempDir = await getTemporaryDirectory();
            final audioFile = File('${tempDir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.mp3');
            await audioFile.writeAsBytes(audioBytes);
            await currentPlayer?.setAudioSource(
                AudioSource.file(audioFile.path)
            );
          }
        }
      }

      // Configurar el listener ANTES de iniciar la reproducción
      _setupPlayerStateListener();

      // Iniciar reproducción
      await currentPlayer?.play();

      // Para móvil: verificar que el estado se actualizó correctamente
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && currentPlayer?.playing == true) {
        setState(() {
          isPlaying = true;
          _isPaused = false;
        });
      }

    } catch (e) {
      debugPrint("Error en la reproducción de audio: $e");
      if (mounted) {
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
    if (currentPlayer != null) {
      await currentPlayer?.stop();
      await currentPlayer?.dispose();
      currentPlayer = null;
    }
    _cancelDelayTimer();
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

        // Pequeño delay para asegurar que el setState se procese en móvil
        await Future.delayed(const Duration(milliseconds: 50));

        // Reanudar reproducción
        await currentPlayer?.play();

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
    if (currentStep < widget.steps.length - 1) {
      // Detener cualquier audio o delay actual

      setState(() {
        currentStep++;
      });

      // Pequeña pausa para que se actualice la UI
      await Future.delayed(const Duration(milliseconds: 300));

      // Reproducir el nuevo audio
      await _playAudioFromAPI(widget.steps[currentStep]);
    } else {
      await _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    await _stopCurrentAudio();
    if (isPlaying) {
      await _stopAudio();
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (mounted) {
        final String apiUrl = "${Config.apiUrl2}/users/daily-activities?userId=${widget.userId}";

        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final userProgramas = List<Map<String, dynamic>>.from(data['userProgramas']);

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
      // Detener audio y delay actual completamente
      await _stopCurrentAudio();

      setState(() {
        currentStep--;
        isPlaying = false;
        _isPaused = false;
        _isInDelay = false;
      });

      // Dispose del player actual para evitar reproducción automática
      currentPlayer?.dispose();
      currentPlayer = null;

      // Pequeña pausa para que se actualice la UI
      await Future.delayed(const Duration(milliseconds: 300));

      // Reproducir automáticamente el audio del paso anterior
      await _playAudioFromAPI(widget.steps[currentStep]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final deviceType = _getDeviceType(MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: deviceType == DeviceType.desktop
            ? _buildDesktopLayout(dimensions)
            : _buildMobileTabletLayout(dimensions, deviceType),
      ),
    );
  }

  Widget _buildDesktopLayout(ResponsiveDimensions dimensions) {
    return Row(
      children: [
        // Panel izquierdo con imagen
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(dimensions.padding),
            child: Column(
              children: [
                _buildHeader(dimensions),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildImageSection(dimensions),
                ),
              ],
            ),
          ),
        ),

        // Panel derecho con contenido y controles
        Expanded(
          flex: 3,
          child: Container(
            padding: EdgeInsets.all(dimensions.padding),
            child: Column(
              children: [
                _buildProgressIndicator(dimensions),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildTextContent(dimensions),
                ),
                _buildControls(dimensions),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(ResponsiveDimensions dimensions, DeviceType deviceType) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dimensions.maxContentWidth),
        child: Column(
          children: [
            _buildHeader(dimensions),
            _buildProgressIndicator(dimensions),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: dimensions.padding),
                child: Column(
                  children: [
                    _buildImageSection(dimensions),
                    SizedBox(height: dimensions.padding),
                    _buildTextSizeControl(dimensions),
                    SizedBox(height: dimensions.padding),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.black,
                    ),
                    SizedBox(height: dimensions.padding),
                    _buildStepText(dimensions),
                  ],
                ),
              ),
            ),
            _buildControls(dimensions),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveDimensions dimensions) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dimensions.padding,
          vertical: dimensions.padding * 0.75
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: dimensions.iconSize + 8,
            height: dimensions.iconSize + 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: dimensions.iconSize * 0.8,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Día ${widget.dia.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: const Color(0xFF4320AD),
                  fontSize: dimensions.fontSize + 2,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: dimensions.iconSize + 8),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ResponsiveDimensions dimensions) {
    return Container(
      margin: EdgeInsets.all(dimensions.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: dimensions.fontSize,
                          color: const Color(0xFF212121),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '10 min',
                          style: TextStyle(
                            color: const Color(0xFF212121),
                            fontSize: dimensions.fontSize * 0.85,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const ShapeDecoration(
                            color: Color(0xFFB7B7B7),
                            shape: OvalBorder(),
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.tecnicaTipo,
                            style: TextStyle(
                              color: const Color(0xFF212121),
                              fontSize: dimensions.fontSize * 0.85,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      widget.tecnicaNombre,
                      style: TextStyle(
                        color: const Color(0xFF5027D0),
                        fontSize: dimensions.titleFontSize,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x28000000),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      isMuted = !isMuted;
                      // Ajustar volumen del AudioPlayer actual
                      currentPlayer?.setVolume(isMuted ? 0.0 : 1.0);
                    });
                  },
                  icon: Icon(
                    isMuted ? Icons.volume_off : Icons.volume_up,
                    size: dimensions.iconSize,
                    color: Colors.black,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.all(dimensions.padding * 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ResponsiveDimensions dimensions) {
    return Container(
      width: double.infinity,
      height: dimensions.imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          _getImageUrlByDay(),
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.image_not_supported,
                size: dimensions.iconSize * 2,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextContent(ResponsiveDimensions dimensions) {
    return Column(
      children: [
        _buildTextSizeControl(dimensions),
        SizedBox(height: dimensions.padding),
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.black,
        ),
        SizedBox(height: dimensions.padding),
        Expanded(
          child: _buildStepText(dimensions),
        ),
      ],
    );
  }

  Widget _buildTextSizeControl(ResponsiveDimensions dimensions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tamaño de texto',
            style: TextStyle(
              color: const Color(0xFF212121),
              fontSize: dimensions.fontSize * 0.85,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  if (textSize > 18.0) {
                    textSize = textSize == 22.0 ? 20.0 : 18.0;
                  }
                });
              },
              child: Container(
                width: dimensions.iconSize + 8,
                height: dimensions.iconSize + 8,
                child: Icon(
                  Icons.remove,
                  size: dimensions.iconSize,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCECECE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: (textSize - 18.0) / 4.0,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4320AD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Positioned(
                          left: ((textSize - 18.0) / 4.0) * constraints.maxWidth - 6,
                          top: -2,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              double percentage = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                              setState(() {
                                double newSize = 18.0 + (percentage * 4.0);
                                if (newSize <= 19.0) {
                                  textSize = 18.0;
                                } else if (newSize <= 21.0) {
                                  textSize = 20.0;
                                } else {
                                  textSize = 22.0;
                                }
                              });
                            },
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4320AD),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (textSize < 22.0) {
                    textSize = textSize == 18.0 ? 20.0 : 22.0;
                  }
                });
              },
              child: Container(
                width: dimensions.iconSize + 8,
                height: dimensions.iconSize + 8,
                child: Icon(
                  Icons.add,
                  size: dimensions.iconSize,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepText(ResponsiveDimensions dimensions) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.steps[currentStep],
          style: TextStyle(
            fontSize: textSize,
            color: const Color(0xFF212121),
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildControls(ResponsiveDimensions dimensions) {
    return Container(
      padding: EdgeInsets.all(dimensions.padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: currentStep > 0 ? _handlePreviousStep : null,
            isSecondary: true,
            dimensions: dimensions,
          ),
          SizedBox(width: dimensions.padding),
          _buildControlButton(
            icon: _getPlayButtonIcon(),
            onPressed: _getPlayButtonAction(),
            isPrimary: true,
            dimensions: dimensions,
          ),
          SizedBox(width: dimensions.padding),
          _buildControlButton(
            icon: currentStep == widget.steps.length - 1
                ? Icons.check
                : Icons.skip_next,
            onPressed: isLoading ? null : _handleNextStep,
            isSecondary: true,
            isLoading: isLoading,
            dimensions: dimensions,
          ),
        ],
      ),
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
      // No hay audio, iniciar reproducción
      return () => _playAudioFromAPI(widget.steps[currentStep]);
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
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isSecondary = false,
    bool isLoading = false,
    required ResponsiveDimensions dimensions,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF8A6FE0) : const Color(0xFFCCCCCC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        minimumSize: Size(dimensions.buttonWidth, dimensions.buttonHeight),
      ),
      child: isLoading
          ? SizedBox(
        width: dimensions.iconSize * 0.75,
        height: dimensions.iconSize * 0.75,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Icon(
        icon,
        size: dimensions.iconSize * 1.5,
        color: isPrimary ? Colors.white : Colors.black,
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