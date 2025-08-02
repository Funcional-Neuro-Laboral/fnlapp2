import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fnlapp/Main/prevtestestres.dart';
import 'package:fnlapp/Politicas%20y%20Terminos/condiciones_uso.dart';
import 'package:fnlapp/Politicas%20y%20Terminos/politica_privacidad.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fnlapp/config.dart';
import '../Util/api_service.dart';
import '../Util/carga.dart';
import '../Util/style.dart';

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

      final url = '${Config.apiUrl}/users/$userId';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Aquí añadimos el token en el header
        },
        body: jsonEncode({'permisopoliticas': true}),
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
      var hierarchicalEndpoint = 'v1/maintance/hierarchical-level/$areaId';
      var hierarchicalResponse = await widget.apiServiceWithToken.get(hierarchicalEndpoint);

      var hierarchicalData = json.decode(hierarchicalResponse.body);
      var hierarchicalLevels = hierarchicalData['results'];

      if (hierarchicalLevels != null) {
        setState(() {
          questionCategories['level'] = (hierarchicalLevels as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });
      }

      print('Niveles jerárquicos cargados correctamente para el área ID: $areaId.');
    } catch (e) {
      print('Error al cargar niveles jerárquicos: $e');
    }
  }


  Future<void> fetchQuestions() async {
    try {
      // Cargar áreas
      userId = await getUserId();


      var sedesResponse = await widget.apiServiceWithToken.get('v1/maintance/sedes/$userId');
      var sedesData = json.decode(sedesResponse.body);
      var sedes = sedesData['results'];



      if (sedes != null && sedes.isNotEmpty) {
        // Guardar áreas en la categoría correspondiente
        setState(() {
          questionCategories['sede'] = (sedes as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });

        // No cargamos niveles jerárquicos aquí automáticamente, eso será manejado dinámicamente
        print('Sedes cargadas correctamente.');
      }

      var areasResponse = await widget.apiServiceWithToken.get('v1/maintance/areas/$userId');
      var areasData = json.decode(areasResponse.body);
      var areas = areasData['results'];


      if (areas != null && areas.isNotEmpty) {
        // Guardar áreas en la categoría correspondiente
        setState(() {
          questionCategories['area'] = (areas as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });

        // No cargamos niveles jerárquicos aquí automáticamente, eso será manejado dinámicamente
        print('Áreas cargadas correctamente.');
      }
    
      // Cargar otras categorías
      var endpoints = [
        'v1/maintance/range-age',
        'v1/maintance/responsability-level',
        'v1/maintance/gender',
      ];

      var responses = await Future.wait(
        endpoints.map((endpoint) => widget.apiServiceWithToken.get(endpoint)),
      );
      
      for (var i = 0; i < responses.length; i++) {
        var data = json.decode(responses[i].body);
        var category = data['results'];

        if (category != null) {
          if (i == 0) {
            questionCategories['age_range'] = (category as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          } else if (i == 1) {
            questionCategories['responsability_level'] = (category as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          } else if (i == 2) {
            questionCategories['gender'] = (category as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
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
    


    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final String createdAt = dateFormat.format(DateTime.now());

    final Map<String, dynamic> dataToSend = {
      "user_id": userId,
      "age_range_id": selectedAnswers[0],
      "hierarchical_level_id": selectedAnswers[3],
      "responsability_level_id": selectedAnswers[4],
      "gender_id": selectedAnswers[1],
      "sedes_id": selectedAnswers[5],
      "created_at": createdAt,
    };

    print('Data to send: $dataToSend');

    try {
      // Llamada a la API para guardar las respuestas
      var response = await http.post(
        Uri.parse('${Config.apiUrl}/guardarUserResponses'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Respuestas guardadas exitosamente.')),
        );

        // Actualizar el campo userresponsebool utilizando la API existente
        await _updateUserResponseBool();

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

  Future<void> _updateUserResponseBool() async {
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

      final url = '${Config.apiUrl}/users/$userId';
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Token de autenticación
        },
        body: jsonEncode({'userresponsebool': true}), // Actualizar el campo
      );

      if (response.statusCode == 200) {
        print('Campo userresponsebool actualizado correctamente.');
        // Guardar en SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('userresponsebool', true);
      } else {
        print('Error al actualizar userresponsebool: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al actualizar userresponsebool: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          loading
              ? Center(child: CircularProgressIndicator())
              : agreedToTerms
                  ? _buildQuestionsScreen()
                  : _buildWelcomeScreen(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40.0, left: 20.0, right: 20.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Centramos el texto horizontalmente
            children: [
              Text(
                'Tu privacidad nos importa',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center, // Aseguramos el centrado del texto
              ),
              SizedBox(height: 20.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: acceptedProcessing,
                    activeColor: Color(0xFF5027D0),
                    onChanged: (value) {
                      setState(() {
                        acceptedProcessing = value ?? false;
                        _updateAgreedToAll();
                      });
                    },
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: 'Acepto la ',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Política de privacidad',
                            style: TextStyle(color: Colors.red),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PoliticaPrivacidadScreen()),
                                );
                              },
                          ),
                          TextSpan(text: ' y las '),
                          TextSpan(
                            text: 'Condiciones de uso',
                            style: TextStyle(color: Colors.red),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CondicionesUsoScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: acceptedProcessing1,
                    activeColor: Color(0xFF5027D0),
                    onChanged: (value) {
                      setState(() {
                        acceptedProcessing1 = value ?? false;
                        _updateAgreedToAll();
                      });
                    },
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text:
                            'Acepto el procesamiento de mis datos personales de salud con el fin de facilitar las funciones de la aplicación. Ver más en la ',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Política de privacidad',
                            style: TextStyle(color: Colors.red),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PoliticaPrivacidadScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: acceptedTracking,
                    activeColor: Color(0xFF5027D0),
                    onChanged: (value) {
                      setState(() {
                        acceptedTracking = value ?? false;
                        _updateAgreedToAll();
                      });
                    },
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text:
                            'Autorizo a la empresa a recopilar y utilizar información sobre mi actividad en aplicaciones y sitios web relacionados, así como datos necesarios para evaluar mi nivel de estrés y bienestar laboral, conforme a lo establecido en la ',
                        style: TextStyle(fontSize: 16.0, color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Política de privacidad',
                            style: TextStyle(color: Colors.red),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PoliticaPrivacidadScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Spacer(),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    acceptedProcessing = true;
                    acceptedProcessing1 = true;
                    acceptedTracking = true;
                    _updateAgreedToAll();
                  });
                },
                child: Text(
                  'Aceptar todo',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5027D0),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: agreedToAll
                    ? () {
                        _handleAcceptAll();
                        setState(() {
                          agreedToTerms = true;
                          currentQuestionIndex = 0;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5027D0),
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: agreedToAll
                        ? Colors.white
                        : Colors
                            .grey, // Cambia el color del texto según el estado
                  ),
                ),
              ),
            ],
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



    return Column(
      children: [
        // Contenido en la parte superior, con reducción de espacio
        Padding(
          padding:
              const EdgeInsets.only(top: 40.0), // Espacio superior ajustado
          child: Column(
            children: [
              Text(
                'Pregunta ${currentQuestionIndex + 1} de 6',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              if (currentQuestionIndex ==
                  0) // Mensaje especial solo en la primera pregunta
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Te damos la bienvenida a FNL',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 8.0), // Espacio entre los textos
              Text(
                preguntaTexto, // Texto dinámico de la pregunta
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10), // Espacio antes de las opciones
            ],
          ),
        ),

        // Opciones centradas en la pantalla
        Expanded(
          flex: 2,
          child: Center(
            child: _buildQuestionField(
                currentCategoryQuestions), // Campo de respuesta dinámico
          ),
        ),

        // Botones en la parte inferior
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentQuestionIndex > 0) // Botón de retroceso
                TextButton(
                  onPressed: goToPreviousQuestion,
                  child: Text(
                    'Volver',
                    style: TextStyle(
                        color: Color(0xFF5027D0), fontWeight: FontWeight.w600),
                  ),
                ),
              Spacer(),
              
              // Botón de siguiente o finalización según el índice de pregunta
              TextButton(
                
                onPressed: currentQuestionIndex < 5
                    ? goToNextQuestion
                    : saveResponses, // Guardar respuestas si es la última pregunta
                child: Text(
                  currentQuestionIndex < 5 ? 'Siguiente' : 'Finalizar',
                  style: TextStyle(
                      color: Color(0xFF5027D0), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  

  Widget _buildQuestionField(List<Map<String, dynamic>> questions) {
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.builder(
        shrinkWrap: true,  // Permite que el ListView se ajuste a su contenido
        itemCount: questions.length,
        itemBuilder: (context, index) {
          var question = questions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: selectedOption == question.values.first.toString()
                      ? Colors.white
                      : Color(0xFF5027D0),
                  side: BorderSide(
                    color: selectedOption == question.values.first.toString()
                        ? Color(0xFF5027D0)
                        : Colors.transparent,
                    width: 2.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20.0),
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
                  question.containsKey('age_range')
                      ? question['age_range'].toString()
                      : question.containsKey('area')
                          ? question['area'].toString()
                          : question.containsKey('level')
                              ? question['level'].toString()
                              : question.containsKey('gender')
                                  ? question['gender'].toString()
                                  : question.containsKey('responsability_level')
                                      ? question['responsability_level'].toString()
                                      : question.containsKey('sede')
                                        ? question['sede'].toString()
                                          : 'Valor no disponible',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: selectedOption == question.values.first.toString()
                        ? Color(0xFF5027D0)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      )
    );
  }


  Widget _buildCheckBoxes() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: acceptedProcessing,
              onChanged: (value) {
                setState(() {
                  acceptedProcessing = value ?? false;
                  _updateAgreedToAll();
                });
              },
            ),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: 'Acepto la ',
                  children: [
                    TextSpan(
                      text: 'Política de privacidad',
                      style: TextStyle(color: Colors.red),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    PoliticaPrivacidadScreen()),
                          );
                        },
                    ),
                    TextSpan(text: ' y las '),
                    TextSpan(
                      text: 'Condiciones de uso',
                      style: TextStyle(color: Colors.red),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CondicionesUsoScreen()),
                          );
                        },
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: acceptedTracking,
              onChanged: (value) {
                setState(() {
                  acceptedTracking = value ?? false;
                  _updateAgreedToAll();
                });
              },
            ),
            Flexible(
              child: Text(
                'Acepto el seguimiento de mi actividad.',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateAgreedToAll() {
    setState(() {
      agreedToAll = acceptedProcessing && acceptedTracking && acceptedProcessing1;
    });
  }
}
