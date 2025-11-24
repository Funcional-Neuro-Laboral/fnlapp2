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
import '../Main/widgets/index_summary.dart';
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
  String? selectedOption;

  String _getOptionText(Map<String, dynamic> question) {
    return question['age_range']?.toString() ??
        question['area']?.toString() ??
        question['level']?.toString() ??
        question['gender']?.toString() ??
        question['responsability_level']?.toString() ??
        question['sede']?.toString() ??
        'Valor no disponible';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserProgress();
    fetchData();
    _precacheImages();
  }

  Future<void> _precacheImages() async {
    await Future.wait([
      precacheImage(
        NetworkImage('https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_seguridad.png'),
        context,
      ),
      precacheImage(
        NetworkImage('https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_espejo.png'),
        context,
      ),
    ]);
  }

  Future<void> _loadUserProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      agreedToTerms = prefs.getBool('permisopoliticas') ?? false;
      bool userresponsebool = prefs.getBool('userresponsebool') ?? false;
      bool testestresbool = prefs.getBool('testestresbool') ?? false;

      if (!agreedToTerms) {
        currentQuestionIndex = -1;
      } else if (!userresponsebool) {
        currentQuestionIndex = 0;
      } else if (!testestresbool) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TestEstresScreen()),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _loadUserData() async {
    String? username = await getUsername();
    userId = await getUserId();
    String? email = await getEmail();
    String? token = await getToken();

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

      String? token = await getToken();

      if (token == null) {
        print('No se encontró el token de autenticación.');
        return;
      }

      final url = '${Config.apiUrl2}/users/accept-permisos';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'iduser': userId}),
      );

      if (response.statusCode == 200) {
        print('Campo permisopoliticas actualizado correctamente.');
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
      if (!mounted) return;
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

          if (!mounted) return;
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
          if (!mounted) return;
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
        if (!mounted) return;
        setState(() {
          questionCategories['area'] = areas
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        });

        print('Áreas cargadas correctamente.');
      }

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

  void selectOption(String option) {
    setState(() {
      selectedOption = option;
    });
  }

  void goToNextQuestion() {
    if (selectedOption != null) {
      selectedAnswers[currentQuestionIndex] = selectedOption;
      setState(() {
        selectedOption = null;
        currentQuestionIndex++;
      });
    }
  }

  void goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        selectedOption = selectedAnswers[currentQuestionIndex] ?? null;
      });
    }
  }

  Future<void> saveResponses() async {
    print('Selected Answers: $selectedAnswers');

    if (selectedAnswers[5] == null) {
      if (selectedOption != null) {
        selectedAnswers[currentQuestionIndex] = selectedOption;
      }
    }

    String? token = await getToken();

    // Convertir todos los valores a int (pueden ser String desde la UI)
    int? ageRangeId = selectedAnswers[0] is String
        ? int.tryParse(selectedAnswers[0])
        : selectedAnswers[0];
    int? genderId = selectedAnswers[1] is String
        ? int.tryParse(selectedAnswers[1])
        : selectedAnswers[1];
    int? hierarchicalLevelId = selectedAnswers[3] is String
        ? int.tryParse(selectedAnswers[3])
        : selectedAnswers[3];
    int? responsabilityLevelId = selectedAnswers[4] is String
        ? int.tryParse(selectedAnswers[4])
        : selectedAnswers[4];
    int? branchId = selectedAnswers[5] is String
        ? int.tryParse(selectedAnswers[5])
        : selectedAnswers[5];

    final Map<String, dynamic> dataToSend = {
      "userId": userId,
      "age_range_id": ageRangeId,
      "hierarchical_level_id": hierarchicalLevelId,
      "responsability_level_id": responsabilityLevelId,
      "gender_id": genderId,
      "branch_id": branchId,
    };

    print('Data to send: $dataToSend');

    try {
      var response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/save-responses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('userresponsebool', true);

        // Guardar branch_id en SharedPreferences para uso posterior
        if (branchId != null) {
          await prefs.setInt('branch_id', branchId);
          print('branch_id guardado en SharedPreferences: $branchId');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Respuestas guardadas exitosamente.')),
        );

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
        final screenWidth = constraints.maxWidth;

        // Detectar tipo de dispositivo
        final isTablet = screenWidth >= 600;
        final isLargeTablet = screenWidth >= 800;
        final isSmallHeight = screenHeight < 700;

        // Adaptación responsiva de tamaños
        final titleFontSize = isLargeTablet ? 32.0 : isTablet ? 28.0 : isSmallHeight ? 20.0 : 24.0;
        final textFontSize = isLargeTablet ? 20.0 : isTablet ? 18.0 : isSmallHeight ? 16.0 : 18.0;
        final buttonWidth = isLargeTablet ? 250.0 : isTablet ? 220.0 : isSmallHeight ? 280.0 : 310.0;
        final imageSize = isLargeTablet ? 220.0 : isTablet ? 200.0 : isSmallHeight ? 120.0 : 150.0;
        final contentPadding = isTablet ? 40.0 : 20.0;
        final maxContentWidth = isLargeTablet ? 900.0 : isTablet ? 700.0 : double.infinity;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxContentWidth,
              maxHeight: screenHeight,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(contentPadding, contentPadding, contentPadding, 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Text(
                      'Tu privacidad nos importa',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF281368),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallHeight ? 15.0 : isTablet ? 30.0 : 20.0),

                    // Checkboxes
                    _buildCheckboxRow(
                      isChecked: acceptedProcessing,
                      textSpans: [
                        TextSpan(
                          text: 'Acepto la ',
                          style: TextStyle(fontSize: textFontSize, color: Colors.black),
                        ),
                        TextSpan(
                          text: 'Política de privacidad',
                          style: TextStyle(
                            fontSize: textFontSize,
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
                            style: TextStyle(fontSize: textFontSize, color: Colors.black)
                        ),
                        TextSpan(
                          text: 'Condiciones de uso',
                          style: TextStyle(
                            fontSize: textFontSize,
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
                      fontSize: textFontSize,
                    ),
                    SizedBox(height: isTablet ? 20.0 : 12.0),

                    _buildCheckboxRow(
                      isChecked: acceptedProcessing1,
                      textSpans: [
                        TextSpan(
                          text: 'Acepto el procesamiento de mis datos personales de salud con el fin de facilitar las funciones de la aplicación. Ver más en la ',
                          style: TextStyle(fontSize: textFontSize, color: Colors.black),
                        ),
                        TextSpan(
                          text: 'Política de privacidad',
                          style: TextStyle(
                            fontSize: textFontSize,
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
                      fontSize: textFontSize,
                    ),
                    SizedBox(height: isTablet ? 20.0 : 12.0),

                    _buildCheckboxRow(
                      isChecked: acceptedTracking,
                      textSpans: [
                        TextSpan(
                          text: 'Autorizo a la empresa a recopilar y utilizar información sobre mi actividad en aplicaciones y sitios web relacionados, así como datos necesarios para evaluar mi nivel de estrés y bienestar laboral, conforme a lo establecido en la ',
                          style: TextStyle(fontSize: textFontSize, color: Colors.black),
                        ),
                        TextSpan(
                          text: 'Política de privacidad',
                          style: TextStyle(
                            fontSize: textFontSize,
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
                      fontSize: textFontSize,
                    ),

                    SizedBox(height: isSmallHeight ? 15.0 : isTablet ? 30.0 : 20.0),

                    // Imagen
                    Image.network(
                      'https://funkyrecursos.s3.us-east-2.amazonaws.com/assets/funcy_seguridad.png',
                      width: imageSize,
                      height: imageSize + 30,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: isSmallHeight ? 15.0 : isTablet ? 30.0 : 20.0),

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
                        width: isTablet ? 200.0 : 165.0,
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 40 : 32,
                            vertical: isTablet ? 12 : 8),
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Aceptar todo',
                              style: TextStyle(
                                color: Color(0xFF6D4BD8),
                                fontSize: isTablet ? 20 : 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isTablet ? 20.0 : 10.0),

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
                        width: buttonWidth,
                        padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 40 : 32,
                            vertical: isTablet ? 16 : 12),
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
                              fontSize: isTablet ? 24 : 22,
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
          ),
        );
      },
    );
  }

  Widget _buildCheckboxRow({
    required bool isChecked,
    required List<TextSpan> textSpans,
    required VoidCallback onChanged,
    required double fontSize,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final checkboxSize = isTablet ? 30.0 : 24.0;
        final spacing = isTablet ? 16.0 : 12.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onChanged,
              child: Container(
                width: checkboxSize,
                height: checkboxSize,
                decoration: BoxDecoration(
                  color: isChecked ? Color(0xFF5027D0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    width: isTablet ? 2.0 : 1.78,
                    color: isChecked ? Color(0xFF5027D0) : Colors.black,
                  ),
                ),
                child: isChecked
                    ? Icon(
                        Icons.check,
                        size: isTablet ? 22 : 18,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            SizedBox(width: spacing),
            Flexible(
              child: RichText(
                text: TextSpan(children: textSpans),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionsScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = constraints.maxWidth;

        // Detectar tipo de dispositivo
        final isTablet = screenWidth >= 600;
        final isLargeTablet = screenWidth >= 800;
        final isSmallDevice = screenHeight < 650 || screenWidth < 350;

        // Adaptación responsiva
        final contentWidth = isLargeTablet ? 900.0 : isTablet ? 700.0 : screenWidth;
        final horizontalPadding = isTablet ? 40.0 : 20.0;
        final topPadding = isTablet ? 60.0 : 40.0;
        final titleFontSize = isLargeTablet ? 32.0 : isTablet ? 28.0 : 24.0;
        final questionCounterFontSize = isLargeTablet ? 20.0 : isTablet ? 18.0 : 18.0;
        final buttonFontSize = isLargeTablet ? 26.0 : isTablet ? 24.0 : 22.0;
        final optionFontSize = isLargeTablet ? 26.0 : isTablet ? 24.0 : isSmallDevice ? 20.0 : 22.0;
        final verticalPadding = isSmallDevice ? 12.0 : isTablet ? 24.0 : 20.0;

        String currentCategoryKey;
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

        var currentCategoryQuestions = questionCategories[currentCategoryKey];

        if (currentCategoryQuestions == null || currentCategoryQuestions.isEmpty) {
          return Center(
            child: Text("No se encontraron preguntas para esta categoría."),
          );
        }

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
            preguntaTexto = '¿Cuál es tu nivel de responsabilidad en tu organización?';
            break;
          case 5:
            preguntaTexto = '¿A que sede perteneces?';
            break;
        }

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: Column(
              children: [
                // Header fijo (barra de progreso + pregunta)
                Padding(
                  padding: EdgeInsets.only(
                    top: topPadding,
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de progreso con icono de retroceder
                      Row(
                        children: [
                          // Icono de retroceder (solo visible si no es la primera pregunta)
                          if (currentQuestionIndex > 0)
                            GestureDetector(
                              onTap: goToPreviousQuestion,
                              child: Container(
                                padding: EdgeInsets.all(isTablet ? 8.0 : 6.0),
                                margin: EdgeInsets.only(right: isTablet ? 16.0 : 12.0),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.black,
                                  size: isTablet ? 24.0 : 20.0,
                                ),
                              ),
                            )
                          else
                            SizedBox(width: isTablet ? 48.0 : 38.0),

                          // Barra de progreso expandida
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 6.0 : 4.0),
                                    height: isTablet ? 8.0 : 6.0,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(isTablet ? 4.0 : 3.0),
                                      color: index <= currentQuestionIndex
                                          ? const Color(0xFF6D4BD8)
                                          : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isTablet ? 40.0 : 30.0),

                      // Contador de preguntas
                      Text(
                        'Pregunta ${currentQuestionIndex + 1} de 6',
                        style: TextStyle(
                          color: Color(0xFF212121),
                          fontSize: questionCounterFontSize,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: isTablet ? 12.0 : 8.0),

                      // Pregunta
                      Text(
                        preguntaTexto,
                        style: TextStyle(
                          color: Color(0xFF5027D0),
                          fontSize: titleFontSize,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 24.0 : 16.0),

                // Opciones scrolleables (expandido para ocupar el espacio disponible)
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: _buildQuestionField(
                      currentCategoryQuestions,
                      optionFontSize,
                      verticalPadding,
                      isTablet,
                    ),
                  ),
                ),

                // Botón Siguiente/Finalizar fijo en la parte inferior
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isTablet ? 20 : 12,
                    horizontalPadding,
                    isTablet ? 40 : 30,
                  ),
                  child: Builder(
                    builder: (context) {
                      final bool isNextEnabled = selectedOption != null ||
                          selectedAnswers.containsKey(currentQuestionIndex);
                      final String nextLabel =
                          currentQuestionIndex < 5 ? 'Siguiente' : 'Continuar';

                      return GestureDetector(
                        onTap: isNextEnabled
                            ? () {
                                if (currentQuestionIndex < 5) {
                                  goToNextQuestion();
                                } else {
                                  // Navegar a la pantalla de resumen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IndexSummaryScreen(
                                        onFinalize: saveResponses,
                                        onBack: () {
                                          Navigator.pop(context); // Retroceder a la pantalla de preguntas
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: verticalPadding,
                          ),
                          decoration: ShapeDecoration(
                            color: isNextEnabled
                                ? const Color(0xFF6D4BD8)
                                : const Color(0xFFD7D7D7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 40.0 : 40.0),
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
                                fontSize: buttonFontSize,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionField(
    List<Map<String, dynamic>> questions,
    double fontSize,
    double verticalPadding,
    bool isTablet,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 16.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          var question = questions[index];
          return Padding(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 12.0 : 8.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * (isTablet ? 0.9 : 0.85),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: selectedOption == question['id'].toString()
                      ? const Color(0x515027D0)
                      : Colors.transparent,
                  side: BorderSide(
                    color: Color(0xFF6D4BD8),
                    width: isTablet ? 3.0 : 2.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                    horizontal: isTablet ? 48.0 : 32.0,
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
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6D4BD8),
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
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