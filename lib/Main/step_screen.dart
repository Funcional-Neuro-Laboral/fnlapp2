import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fnlapp/Main/finalstepscreen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config.dart';
import 'completed_dia_screen.dart';


class StepScreen extends StatefulWidget {
  final List<String> steps; // Recibir la lista de pasos como un JSON
  final String tecnicaNombre; // Nombre de la técnica
  final int dia; // Número del día
  final int userId; // Nuevo: user_id
  final int tecnicaId; // Nuevo: tecnica_id
  final String url_img;

  const StepScreen({
    Key? key,
    required this.steps,
    required this.tecnicaNombre,
    required this.dia,
    required this.userId,
    required this.tecnicaId,
    required this.url_img,
  }) : super(key: key);

  @override
  State<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  int currentStep = 0;
  FlutterTts? flutterTts;
  bool isPlaying = false;
  bool isLoading = false;
  final TextEditingController commentController = TextEditingController();
  double rating = 0;
  double textSize = 18.0;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    flutterTts?.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    flutterTts?.stop();
    commentController.dispose();
    super.dispose();
  }

  Future<void> _playAudioFromAPI(String text) async {
    if (isPlaying) return;

    setState(() {
      isPlaying = true;
    });

    try {
      final url = Uri.parse('${Config.apiUrl}/voice/texttovoice/?text=$text&voiceId=Joanna');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final audioBytes = response.bodyBytes;
        final player = AudioPlayer();

        if (kIsWeb) {
          await player.play(BytesSource(audioBytes));
        } else {
          final tempDir = await getTemporaryDirectory();
          final audioFile = File('${tempDir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.mp3');
          await audioFile.writeAsBytes(audioBytes);
          await player.play(DeviceFileSource(audioFile.path));
        }

        // Escuchar cuando termine la reproducción
        player.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.completed && mounted) {
            setState(() {
              isPlaying = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Error en la reproducción de audio: $e");
      if (mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    await flutterTts?.stop();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _handleNextStep() async {
    if (currentStep < widget.steps.length - 1) {
      setState(() {
        currentStep++;
      });
      if (isPlaying) {
        await _stopAudio();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await _playAudioFromAPI(widget.steps[currentStep]);
    } else {
      await _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (isPlaying) {
      await _stopAudio();
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/userprograma/${widget.userId}/act/${widget.dia}'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['isCompleted'] == true) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CompletedDiaScreen(),
              ),
            );
          }
        } else {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FinalStepScreen(
                  userId: widget.userId,
                  tecnicaId: widget.tecnicaId,
                ),
              ),
            );
          }
        }
      } else {
        throw Exception('Error en la respuesta del servidor');
      }
    } catch (e) {
      debugPrint("Error al verificar el estado del día: $e");
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalStepScreen(
              userId: widget.userId,
              tecnicaId: widget.tecnicaId,
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

  void _handlePreviousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      if (isPlaying) {
        _stopAudio();
      }
    }
  }

  Future<void> _sendComment() async {
    // Implementar envío de comentario
    debugPrint('Rating: $rating');
    debugPrint('Comentario: ${commentController.text}');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: _buildStepContent(),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
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
                  fontSize: 18,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 32), // Para balancear el icono de back
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Aumenté el margen vertical
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lado izquierdo con la información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila con tiempo y tipo de relajación
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: const Color(0xFF212121),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '10 min',
                          style: TextStyle(
                            color: const Color(0xFF212121),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFB7B7B7),
                            shape: OvalBorder(),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Relajación',
                          style: TextStyle(
                            color: const Color(0xFF212121),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Nombre del programa
                    Text(
                      widget.tecnicaNombre,
                      style: TextStyle(
                        color: const Color(0xFF5027D0),
                        fontSize: 17,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de voz a la derecha con sombra
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x28000000),
                      blurRadius: 5,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () async {
                    if (isPlaying) {
                      await _stopAudio();
                    } else {
                      await _playAudioFromAPI(widget.steps[currentStep]);
                    }
                  },
                  icon: Icon(
                    isPlaying ? Icons.volume_off : Icons.volume_up,
                    size: 24,
                    color: Colors.black,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Imagen con bordes redondeados
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
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
                  widget.url_img,
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
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título de tamaño de texto
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tamaño de texto',
              style: TextStyle(
                color: const Color(0xFF212121),
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Control deslizante de tamaño de texto
          Row(
            children: [
              // Botón de disminuir tamaño
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (textSize > 18.0) { // Cambié de 16.0 a 18.0
                      textSize = textSize == 22.0 ? 20.0 : 18.0; // Cambié los valores
                    }
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.remove,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(width: 12),

              // Slider de tamaño
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 8,
                      child: Stack(
                        children: [
                          // Track del slider
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(0xFFCECECE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Parte activa del slider
                          FractionallySizedBox(
                            widthFactor: (textSize - 18.0) / 4.0, // Cambié de 16.0 a 18.0
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4320AD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // Botón deslizante
                          Positioned(
                            left: ((textSize - 18.0) / 4.0) * (MediaQuery.of(context).size.width - 120) - 6, // Cambié de 16.0 a 18.0
                            top: -2,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                RenderBox renderBox = context.findRenderObject() as RenderBox;
                                double localX = details.localPosition.dx;
                                double sliderWidth = MediaQuery.of(context).size.width - 120;
                                double percentage = (localX / sliderWidth).clamp(0.0, 1.0);

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
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12),

              // Botón de aumentar tamaño
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (textSize < 22.0) {
                      textSize = textSize == 18.0 ? 20.0 : 22.0;
                    }
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.add,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Línea divisoria
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.black,
          ),
          const SizedBox(height: 20),

          // Contenido del paso
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.centerLeft, // Alineación a la izquierda
                child: Text(
                  widget.steps[currentStep],
                  style: TextStyle(
                    fontSize: textSize,
                    color: const Color(0xFF212121),
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.left, // Texto alineado a la izquierda
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botón anterior
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: currentStep > 0 ? _handlePreviousStep : null, // null deshabilita el botón
            isSecondary: true,
          ),
          const SizedBox(width: 16),

          // Botón de reproducir/pausar
          _buildControlButton(
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: () async {
              if (isPlaying) {
                await _stopAudio();
              } else {
                await _playAudioFromAPI(widget.steps[currentStep]);
              }
            },
            isPrimary: true,
          ),

          const SizedBox(width: 16),

          // Botón siguiente
          _buildControlButton(
            icon: currentStep == widget.steps.length - 1
                ? Icons.check
                : Icons.skip_next,
            onPressed: isLoading ? null : _handleNextStep,
            isSecondary: true,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isSecondary = false,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF8A6FE0) : const Color(0xFFCCCCCC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        minimumSize: Size(114, 72),
      ),
      child: isLoading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Icon(
        icon,
        size: 40,
        color: isPrimary ? Colors.white : Colors.black,
      ),
    );
  }
}