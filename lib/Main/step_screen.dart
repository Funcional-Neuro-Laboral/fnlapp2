import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fnlapp/Main/finalstepscreen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
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

  StepScreen({
    required this.steps,
    required this.tecnicaNombre,
    required this.dia,
    required this.userId, // Nuevo: user_id
    required this.tecnicaId, // Nuevo: tecnica_id
    required this.url_img, // Nuevo: url_img
  });

  @override
  _StepScreenState createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  int currentStep = 0; // Índice del paso actual
  FlutterTts flutterTts = FlutterTts(); // Instancia de FlutterTts
  bool isPlaying = false; // Para controlar si se está reproduciendo el audio
  TextEditingController commentController =
      TextEditingController(); // Controlador del input de comentario
  double _rating = 0; // Valor inicial para el rating de estrellas

  // No es necesario declarar steps aquí, ya que widget.steps es directamente la lista
  // List<dynamic> steps = []; // Lista de pasos decodificados del JSON

  @override
  void initState() {
    super.initState();
    // No es necesario decodificar, ya que widget.steps ya es una lista
    // steps = json.decode(widget.steps); // Elimina esta línea
    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false; // Cambia el estado a no reproduciendo
      });
    });
  }

  // Función para leer el texto
  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("es-ES"); // Establecer el idioma español
    await flutterTts.setPitch(1.0); // Tono de voz normal
    await flutterTts.speak(text); // Leer el texto

    setState(() {
      isPlaying = true; // Cambia el estado a reproduciendo
    });
  }

  // Función para detener la lectura
  Future<void> _stop() async {
    await flutterTts.stop(); // Detiene la lectura
    setState(() {
      isPlaying = false; // Cambia el estado a detenido
    });
  }

  @override
  void dispose() {
    // Asegúrate de detener la lectura cuando el widget se elimine
    flutterTts.stop();
    commentController.dispose(); // Libera el controlador del input
    super.dispose();
  }

  // Función para enviar el comentario
  void _sendComment() {
    // Aquí puedes manejar el envío del comentario, por ahora simplemente hace pop
    Navigator.pop(context); // Volver al home
    print('Rating: $_rating'); // Verificar el valor del rating
  }

  Future<void> _playAudioFromAPI(String text) async {
    try {
      final url = Uri.parse('${Config.apiUrl}/voice/texttovoice/?text=$text&voiceId=Joanna');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        Uint8List audioBytes = response.bodyBytes;
        AudioPlayer player = AudioPlayer();

        if (kIsWeb) {
          // Reproducir en la web
          await player.play(BytesSource(audioBytes));
        } else {
          // Reproducir en móvil/escritorio
          final tempDir = await getTemporaryDirectory();
          final audioFile = File('${tempDir.path}/speech.mp3');
          await audioFile.writeAsBytes(audioBytes);
          await player.play(DeviceFileSource(audioFile.path));
        }
      } else {
        print("Error al obtener audio: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en la reproducción de audio: $e");
    }
  }

  @override
Widget build(BuildContext context) {
  int maxSteps = widget.steps.length; // Usar widget.steps directamente

  return Scaffold(
    backgroundColor: Colors.transparent, // Fondo transparente para el Scaffold
    appBar: AppBar(
      backgroundColor: Colors.black.withOpacity(0.5),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 255, 255, 255)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      centerTitle: true,
      title: Text(
        'Mi plan diario',
        style: GoogleFonts.poppins(fontSize: 16.0, color: Colors.white),
      ),
    ),
    body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(widget.url_img), // Usar la URL de la imagen
          fit: BoxFit.cover, // Asegura que la imagen cubra toda la pantalla
        ),
      ),
      child: Container(
        // Añadimos una capa oscura sobre la imagen para mejorar la visibilidad del texto
        color: Colors.black.withOpacity(0.5), // Ajusta la opacidad según sea necesario
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Texto en el centro de la pantalla
              Expanded(
                child: Center(
                  child: currentStep < maxSteps
                      ? Text(
                          widget.steps[currentStep], // Usar widget.steps
                          style: GoogleFonts.poppins(
                              fontSize: 22.0,
                              color: Colors.white,
                              height: 1.5),
                          textAlign: TextAlign.center,
                        )
                      : Container(), // Evita error si intentamos acceder a un paso inexistente
                ),
              ),
              // Texto del día y la técnica
              if (currentStep < maxSteps)
                Column(
                  children: [
                    Text(
                      'Día ${widget.dia.toString().padLeft(2, '0')}',
                      style: GoogleFonts.poppins(
                          fontSize: 14.0, color: Colors.white),
                    ),
                    Text(
                      widget.tecnicaNombre,
                      style: GoogleFonts.poppins(
                          fontSize: 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              SizedBox(height: 20),

              // Si es la última vista, mostrar el input y el botón "Enviar"
              if (currentStep == maxSteps)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
                    children: [
                      // Título y Rating
                      Text(
                        "Califica tu experiencia con las técnicas de relajación",
                        style: GoogleFonts.poppins(
                            fontSize: 16.0, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      RatingBar.builder(
                        initialRating: 0,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _rating = rating;
                          });
                        },
                      ),
                      SizedBox(height: 30),
                      // Input para el comentario
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Deja un comentario sobre la técnica",
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Botón "Enviar"
                      ElevatedButton(
                        onPressed: _sendComment, // Llama a la función para enviar el comentario
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 75, 21, 141),
                        ),
                        child: Text(
                          'Enviar',
                          style: GoogleFonts.poppins(
                              fontSize: 16.0, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // Botones de navegación y audio solo si es mensaje
              if (currentStep < maxSteps)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón anterior (solo si no es la primera vista)
                    if (currentStep > 0)
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 75, 21, 141), // Fondo circular
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.skip_previous, color: Colors.white),
                          iconSize: 28, // Tamaño del ícono ajustado
                          onPressed: () {
                            setState(() {
                              if (currentStep > 0) {
                                currentStep--;
                                if (isPlaying) {
                                  _stop();
                                }
                              }
                            });
                          },
                        ),
                      ),
                    SizedBox(width: 20), // Separador

                    // Botón siguiente (modificado)
                    if (currentStep < maxSteps)
                      Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 75, 21, 141), // Fondo circular
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.skip_next, color: Colors.white),
                          iconSize: 28, // Tamaño del ícono ajustado
                          onPressed: () async {
                            if (currentStep < maxSteps - 1) {
                              currentStep++;
                              if (isPlaying) {
                                await _stop();
                                await Future.delayed(Duration(milliseconds: 800));
                              }
                              await _playAudioFromAPI(widget.steps[currentStep]);
                            } else {
                              if (isPlaying) {
                                await _stop();
                              }

                              // Llamada a la API para verificar si el día fue completado
                              final response = await http.get(
                                Uri.parse('${Config.apiUrl}/userprograma/${widget.userId}/act/${widget.dia}')
                              );

                              if (response.statusCode == 200) {
                                // Si el día fue completado
                                final responseData = json.decode(response.body);
                                if (responseData['isCompleted'] == true) {
                                  // Si el día fue completado, navega a la pantalla CompletedDiaScreen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CompletedDiaScreen(),
                                    ),
                                  );
                                } else {
                                  // Si no ha sido completado, continúa con la lógica original
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FinalStepScreen(
                                        userId: widget.userId, // Pasa el user_id
                                        tecnicaId: widget.tecnicaId, // Pasa el tecnica_id
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                // Maneja el caso en que la API no responda correctamente
                                print("Error al verificar el estado del día");
                                // Continúa con la lógica original si la API falla
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
                            // Actualizamos la vista
                            setState(() {});
                          },
                        ),
                      ),
                    SizedBox(width: 20), // Separador

                    // Botón de audio (opcional para leer el texto en voz alta)
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 75, 21, 141), // Fondo circular
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(isPlaying ? Icons.stop : Icons.volume_up, color: Colors.white),
                        iconSize: 28, // Tamaño del ícono ajustado
                        onPressed: () async {
                          if (isPlaying) {
                            await _stop();
                          } else {
                            setState(() {
                              isPlaying = true; // Cambia el estado a "reproduciendo"
                            });
                            await _playAudioFromAPI(widget.steps[currentStep]);
                          }
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}