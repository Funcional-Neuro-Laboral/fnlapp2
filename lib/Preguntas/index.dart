import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fnlapp/Main/prevtestestres.dart';
import 'package:fnlapp/Politicas%20y%20Terminos/condiciones_uso.dart';
import 'package:fnlapp/Politicas%20y%20Terminos/politica_privacidad.dart';
import 'package:http/http.dart' as http;
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fnlapp/config.dart';
import '../Util/api_service.dart';

class IndexScreen extends StatefulWidget {
  final String username;
  final ApiService apiServiceWithToken;

  IndexScreen({required this.username, required this.apiServiceWithToken});

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  Map<String, List<Map<String, dynamic>>> questionCategories = {
    'age_range': [],
    'level': [],
    'area': [],
    'sede': [],
    'responsability_level': [],
    'gender': []
  };
  Map<int, dynamic> selectedAnswers = {};

  int currentQuestionIndex = 0;
  bool loading = true;
  bool agreedToTerms = false;
  bool acceptedProcessing = false;
  bool acceptedProcessing1 = false;
  bool acceptedTracking = false;
  bool agreedToAll = false;
  int? selectedAreaId; 

  int? userId;

  // Variable para almacenar la opción seleccionada en la pregunta actual
  String? selectedOption;
  String _getOptionText(Map<String, dynamic> question) {
    return question['age_range']?.toString() ??
        question['area']?.toString() ??
        question['level']?.toString() ??
        question['gender']?.toString() ??
        question['responsability_level']?.toString() ?? // ahora sí funcionará
        question['sede']?.toString() ??
        'Valor no disponible';
  }
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserProgress();
    fetchData();
  }

  Future<void> _loadUserProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      agreedToTerms = prefs.getBool('permisopoliticas') ?? false;
      bool userresponsebool = prefs.getBool('userresponsebool') ?? false;
      bool testestresbool = prefs.getBool('testestresbool') ?? false;

      if (!agreedToTerms) {
        currentQuestionIndex = -1; // 🔴 Mostrar pantalla de políticas
      } else if (!userresponsebool) {
        currentQuestionIndex = 0; // 🔴 Empezar preguntas
      } else if (!testestresbool) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TestEstresScreen()),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home'); // 🔴 Si todo está completado
      }
    });
  }

  Future<void> _loadUserData() async {
    // Obtener datos de SharedPreferences
    String? username = await getUsername();
    userId = await getUserId();
    String? email = await getEmail();
    String? token = await getToken();

    // Mostrar los datos en la consola
    print('Username: $username');
    print('User ID: $userId');
    print('Email: $email');
    print('Token: $token');
  }

  Future<void> _updatePermisoPoliticas() async {
    try {
      if (userId == null) {
        print('No se encontró el ID del usuario.');
        return;
      }

      String? token = await getToken(); // Obtener el token de SharedPreferences

      if (token == null) {
        print('No se encontró el token de autenticación.');
        return;
      }

      final url = '${Config.apiUrl2}/users/accept-permisos';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode({'iduser': userId}),
      );

      if (response.statusCode == 200) {
        print('Campo permisopoliticas actualizado correctamente.');
        // Guardar en SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('permisopoliticas', true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permisos aceptados y actualizados.')),
        );
      } else {
        print('Error al actualizar permisopoliticas: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar permisos.')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el servidor.')),
      );
    }
  }

  void _handleAcceptAll() async {
    setState(() {
      acceptedProcessing = true;
      acceptedProcessing1 = true;
      acceptedTracking = true;
      agreedToAll = true;
    });

    await _updatePermisoPoliticas();
  }

  Future<void> fetchData() async {
    try {
      await fetchQuestions();
      setState(() {
        loading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
    }
  }

  Future<void> fetchHierarchicalLevel(int areaId) async {
    try {
      final queryParams = {
        'areaId': areaId.toString(),
      };

      final uri = Uri.parse('general/hierarchical-levels/by-area')
          .replace(queryParameters: queryParams);

      final response = await widget.apiServiceWithToken.get(uri.toString());

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          final hierarchicalLevels = data
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          setState(() {
            questionCategories['level'] = hierarchicalLevels;
          });

          print('Niveles jerárquicos cargados correctamente (${hierarchicalLevels.length}).');
        } else {
          print('No se encontraron niveles jerárquicos para el área $areaId.');
        }
      } else {
        print('Error al cargar niveles jerárquicos: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Excepción al cargar niveles jerárquicos: $e');
      print(stackTrace);
    }
  }


  Future<void> fetchQuestions() async {
    try {
      // Cargar áreas
      userId = await getUserId();

      final queryParamsSedes = {
        'iduser': userId.toString(),
      };

      final uriSede = Uri.parse('general/branches/by-user')
          .replace(queryParameters: queryParamsSedes);

      final response = await widget.apiServiceWithToken.get(uriSede.toString());

      if (response.statusCode == 200) {
        final List<dynamic> sedesData = json.decode(response.body);

        if (sedesData.isNotEmpty) {
          setState(() {
            questionCategories['sede'] = sedesData
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          });
          print('Sedes Body: ${response.body}');
          print('Sedes cargadas correctamente (${sedesData.length}).');
        } else {
          print('No se encontraron sedes para el usuario $userId.');
        }
      } else {
        print('Error al cargar sedes: ${response.statusCode}');
      }


      var queryParams = {
        'iduser': userId.toString(),
      };

      var uriArea = Uri.parse('general/area/by-user').replace(queryParameters: queryParams);
      var areasResponse = await widget.apiServiceWithToken.get(uriArea.toString());

      var areasData = json.decode(areasResponse.body);
      var areas = areasData as List;

      if (areas.isNotEmpty) {
        setState(() {
          questionCategories['area'] = areas
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });

        print('Áreas cargadas correctamente.');
      }

    
      // Cargar otras categorías
      var endpoints = [
        'general/age-ranges',
        'general/responsibility-levels/all',
        'general/gender/all',
      ];

      var responses = await Future.wait(
        endpoints.map((endpoint) => widget.apiServiceWithToken.get(endpoint)),
      );
      
      for (var i = 0; i < responses.length; i++) {
        var data = json.decode(responses[i].body);

        if (data != null && data is List) {
          var category = data.map((item) => Map<String, dynamic>.from(item)).toList();

          if (i == 0) {
            questionCategories['age_range'] = category;
          } else if (i == 1) {
            questionCategories['responsability_level'] = category;
          } else if (i == 2) {
            questionCategories['gender'] = category;
          }
        }
      }

      setState(() {
        loading = false;
      });

      print('Las preguntas se cargaron correctamente.');
    } catch (e) {
      setState(() {
        loading = false;
      });
      print('Error al cargar preguntas: $e');
    }
  }



  // Función para manejar la selección de una opción
  void selectOption(String option) {
    setState(() {
      selectedOption = option; // Almacenar la opción seleccionada
    });
  }

  void goToNextQuestion() {
    if (selectedOption != null) {
      // Guardar la opción seleccionada en el estado antes de pasar a la siguiente pregunta
      selectedAnswers[currentQuestionIndex] = selectedOption;
      setState(() {
        selectedOption =
            null; // Reiniciar la opción seleccionada para la siguiente pregunta
        currentQuestionIndex++;
      });
    }
  }

  void goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedOption = selectedAnswers[currentQuestionIndex] ??
            null; // Recuperar la opción seleccionada si existe
      });
    }
  }

  Future<void> saveResponses() async {
    // Verificar los valores de selectedAnswers
    print('Selected Answers: $selectedAnswers');

    if (selectedAnswers[5] == null) {
      if (selectedOption != null) {
        selectedAnswers[currentQuestionIndex] = selectedOption;
      }
    }
    
    String? token = await getToken(); 

    final Map<String, dynamic> dataToSend = {
      "userId": userId,
      "age_range_id": selectedAnswers[0],
      "hierarchical_level_id": selectedAnswers[3],
      "responsability_level_id": selectedAnswers[4],
      "gender_id": selectedAnswers[1],
      "branch_id": selectedAnswers[5],
    };

    print('Data to send: $dataToSend');

    try {
      // Llamada a la API para guardar las respuestas
      var response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/save-responses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Respuestas guardadas exitosamente.')),
        );

        // Navegar a la siguiente pantalla
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TestEstresScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar respuestas.')),
        );
      }
    } catch (e) {
      print('Error al enviar respuestas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar respuestas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : agreedToTerms
          ? _buildQuestionsScreen()
          : _buildWelcomeScreen(),
    );
  }

  Widget _buildWelcomeScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallHeight = screenHeight < 700;
        final isMobile = constraints.maxWidth < 600;
        final scaleFactor = isMobile ? 1.0 : 1.2;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 430 : 700, // O incluso 800 si prefieres más amplitud
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Encabezado y checkboxes
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // <- Centrar horizontalmente todo
                    children: [
                      const SizedBox(height: 10),
                       Center( // <- Centrar específicamente el texto
                        child: Text(
                          'Tu privacidad nos importa',
                          style: TextStyle(
                            fontSize: isSmallHeight ? 18.0 : 24.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF281368),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(height: isSmallHeight ? 10.0 : 20.0),

                      // checkboxes
                      _buildCheckboxRow(
                        isChecked: acceptedProcessing,
                        textSpans: [
                          TextSpan(
                            text: 'Acepto la ',
                            style: TextStyle(fontSize: 18.0 * scaleFactor, color: Colors.black),
                          ),
                          TextSpan(
                            text: 'Política de privacidad',
                            style: TextStyle(
                              fontSize: 18.0 * scaleFactor,
                              color: Color(0xFF5027D0),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PoliticaPrivacidadScreen()),
                                );
                              },
                          ),
                          TextSpan(
                              text: ' y las ',
                              style: TextStyle(
                                  fontSize: 18.0 * scaleFactor, color: Colors.black)
                          ),
                          TextSpan(
                            text: 'Condiciones de uso',
                            style: TextStyle(
                              fontSize: 18.0 * scaleFactor,
                              color: Color(0xFF5027D0),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CondicionesUsoScreen()),
                                );
                              },
                          ),
                        ],
                        onChanged: () {
                          setState(() {
                            acceptedProcessing = !acceptedProcessing;
                            _updateAgreedToAll();
                          });
                        },
                      ),
                      const SizedBox(height: 12.0),
                      _buildCheckboxRow(
                        isChecked: acceptedProcessing1,
                        textSpans: [
                            TextSpan(
                            text: 'Acepto el procesamiento de mis datos personales de salud con el fin de facilitar las funciones de la aplicación. Ver más en la ',
                            style: TextStyle(fontSize: 18.0 * scaleFactor, color: Colors.black),
                          ),
                          TextSpan(
                            text: 'Política de privacidad',
                            style: TextStyle(
                              fontSize: 18.0 * scaleFactor,
                              color: Color(0xFF5027D0),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PoliticaPrivacidadScreen()),
                                );
                              },
                          ),
                        ],
                        onChanged: () {
                          setState(() {
                            acceptedProcessing1 = !acceptedProcessing1;
                            _updateAgreedToAll();
                          });
                        },
                      ),
                      const SizedBox(height: 12.0),
                      _buildCheckboxRow(
                        isChecked: acceptedTracking,
                        textSpans: [
                            TextSpan(
                            text:
                            'Autorizo a la empresa a recopilar y utilizar información sobre mi actividad en aplicaciones y sitios web relacionados, así como datos necesarios para evaluar mi nivel de estrés y bienestar laboral, conforme a lo establecido en la ',
                            style: TextStyle(fontSize: 18.0 * scaleFactor, color: Colors.black),
                          ),
                          TextSpan(
                            text: 'Política de privacidad',
                            style: TextStyle(
                              fontSize: 18.0 * scaleFactor,
                              color: Color(0xFF5027D0),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PoliticaPrivacidadScreen()),
                                );
                              },
                          ),
                        ],
                        onChanged: () {
                          setState(() {
                            acceptedTracking = !acceptedTracking;
                            _updateAgreedToAll();
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallHeight ? 10.0 : 20.0),

                  // Imagen
                  Image.network(
                    'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_like.png',
                    width: 150,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: isSmallHeight ? 10.0 : 20.0),

                  // Botón Aceptar todo
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        acceptedProcessing = true;
                        acceptedProcessing1 = true;
                        acceptedTracking = true;
                        _updateAgreedToAll();
                      });
                    },
                    child: Container(
                      width: isMobile ? 165 : 200,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: FittedBox( // <- ESTO AJUSTA AUTOMÁTICAMENTE EL TEXTO
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Aceptar todo',
                            style: TextStyle(
                              color: Color(0xFF6D4BD8),
                              fontSize: 18,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),


                  const SizedBox(height: 10.0),

                  // Botón Continuar
                  GestureDetector(
                    onTap: agreedToAll
                        ? () {
                      _handleAcceptAll();
                      setState(() {
                        agreedToTerms = true;
                        currentQuestionIndex = 0;
                      });
                    }
                        : null,
                    child: Container(
                      width: isMobile ? 310 : 400,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: agreedToAll ? const Color(0xFF5027D0) : const Color(0xFFD7D7D7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            color: agreedToAll ? Colors.white : const Color(0xFF868686),
                            fontSize: 22,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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



  Widget _buildCheckboxRow({
    required bool isChecked,
    required List<TextSpan> textSpans,
    required VoidCallback onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onChanged,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isChecked ? Color(0xFF5027D0) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                width: 1.78,
                color: isChecked ? Color(0xFF5027D0) : Colors.black,
              ),
            ),
            child: isChecked
                ? const Icon(
              Icons.check,
              size: 18,
              color: Colors.white,
            )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: RichText(
            text: TextSpan(children: textSpans),
          ),
        ),
      ],
    );
  }






  Widget _buildQuestionsScreen() {
    String currentCategoryKey;

    // Selección de la categoría según el índice de la pregunta
    switch (currentQuestionIndex) {
      case 0:
        currentCategoryKey = 'age_range';
        break;
      case 1:
        currentCategoryKey = 'gender';
        break;
      case 2:
        currentCategoryKey = 'area';
        break;
      case 3:
        currentCategoryKey = 'level';
        break;
      case 4:
        currentCategoryKey = 'responsability_level';
        break;
      case 5:
        currentCategoryKey = 'sede';
        break;
      default:
        currentCategoryKey = 'age_range';
    }

    // Obtenemos las preguntas de la categoría actual
    var currentCategoryQuestions = questionCategories[currentCategoryKey];
    print('Current Category Questions ($currentCategoryKey): $currentCategoryQuestions');
    // Si no hay preguntas disponibles, mostramos un mensaje
    if (currentCategoryQuestions == null || currentCategoryQuestions.isEmpty) {
      return Center(
        child: Text("No se encontraron preguntas para esta categoría."),
      );
    }

    // Definir el texto de la pregunta según el índice
    String preguntaTexto = '';
    switch (currentQuestionIndex) {
      case 0:
        preguntaTexto = '¿Cuál es tu rango de edad?';
        break;
      case 1:
        preguntaTexto = '¿Cuál es tu género?';
        break;
      case 2:
        preguntaTexto = '¿Cuál es tu Área?';
        break;
      case 3:
        preguntaTexto = '¿Cuál es tu posición en la organización?';
        break;
      case 4:
        preguntaTexto = '¿Cuál es tu nivel de responsabilidad?';
        break;
      case 5:
        preguntaTexto = '¿A que sede perteneces?';
        break;
    }



    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = constraints.maxWidth;
        final isSmallDevice = screenHeight < 650 || screenWidth < 350;

        final optionFontSize = isSmallDevice ? 14.0 : 16.0;
        final verticalPadding = isSmallDevice ? 12.0 : 20.0;

        // 🔹 ancho máximo para web
        final contentWidth = constraints.maxWidth > 720 ? 720.0 : constraints.maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barra de progreso
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                height: 6.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3.0),
                                  color: index <= currentQuestionIndex
                                      ? const Color(0xFF6D4BD8)
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 35.0),

                        // Contenedor para mantener la bienvenida y la pregunta en posición fija
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banda fija para la bienvenida (20 px de alto)
                            SizedBox(
                              height: 20,
                              child: currentQuestionIndex == 0
                                  ? const Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  'Te damos la bienvenida a FNL',
                                  style: TextStyle(
                                    color: Color(0xFF212121),
                                    fontSize: 18,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                                  : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 8.0), // espacio fijo debajo de la bienvenida

                            // Banda fija para la pregunta
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                preguntaTexto,
                                style: const TextStyle(
                                  color: Color(0xFF5027D0),
                                  fontSize: 24,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Opciones
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: _buildQuestionField(
                      currentCategoryQuestions,
                      optionFontSize,
                      verticalPadding,
                    ),
                  ),

                  SizedBox(height: 90),

                  // Botones (Atrás / Siguiente o Finalizar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ---- ATRÁS ----
                        if (currentQuestionIndex > 0)
                          GestureDetector(
                            onTap: goToPreviousQuestion,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(80),
                                ),
                                shadows: const [
                                  BoxShadow(
                                    color: Color(0x4C000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 6),
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Atrás',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 88),

                        // ---- SIGUIENTE / FINALIZAR ----
                        Builder(
                          builder: (context) {
                            final bool isNextEnabled = selectedOption != null ||
                                selectedAnswers.containsKey(currentQuestionIndex);
                            final String nextLabel =
                            currentQuestionIndex < 5 ? 'Siguiente' : 'Finalizar';

                            return GestureDetector(
                              onTap: isNextEnabled
                                  ? () {
                                if (currentQuestionIndex < 5) {
                                  goToNextQuestion();
                                } else {
                                  saveResponses();
                                }
                              }
                                  : null,
                              child: Container(
                                width: 158,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                clipBehavior: Clip.antiAlias,
                                decoration: ShapeDecoration(
                                  color: isNextEnabled
                                      ? const Color(0xFF6D4BD8)
                                      : const Color(0xFFD7D7D7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  shadows: isNextEnabled
                                      ? const [
                                    BoxShadow(
                                      color: Color(0x26000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Color(0x4C000000),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                      spreadRadius: 0,
                                    ),
                                  ]
                                      : const [],
                                ),
                                child: Center(
                                  child: Text(
                                    nextLabel,
                                    style: TextStyle(
                                      color: isNextEnabled
                                          ? Colors.white
                                          : const Color(0xFF868686),
                                      fontSize: 22,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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

    Widget _buildQuestionField(List<Map<String, dynamic>> questions, double fontSize, double verticalPadding) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Evita scroll
          itemCount: questions.length,
          itemBuilder: (context, index) {
            var question = questions[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selectedOption == question['id'].toString()
                        ? const Color(0x515027D0)
                        : Colors.transparent,
                    side: const BorderSide(
                      color: Color(0xFF6D4BD8),
                      width: 2.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: verticalPadding,
                      horizontal: 32.0,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedOption = question['id'].toString();
                    });

                    if (currentQuestionIndex == 2) {
                      int areaId = question['id'];
                      fetchHierarchicalLevel(areaId);
                    }
                  },
                  child: Text(
                    _getOptionText(question),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6D4BD8),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

  void _updateAgreedToAll() {
    setState(() {
      agreedToAll = acceptedProcessing && acceptedTracking && acceptedProcessing1;
    });
  }
}
