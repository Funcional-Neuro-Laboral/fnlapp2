import 'package:flutter/material.dart';
import 'package:fnlapp/Main/models/test_notice.dart';
import 'package:fnlapp/Main/subscription_screen.dart';
import 'package:fnlapp/Main/widgets/test_completion_screen.dart';
import 'package:fnlapp/Main/widgets/test_notice_dialog.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:fnlapp/Main/cargarprograma.dart';
import 'package:fnlapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Preguntas/index.dart';
import '../Preguntas/questions_data.dart';
import 'package:fnlapp/Main/home.dart';
import '../Util/api_service.dart';
import '../Util/test_notices_data.dart';
import '../services/subscription_service.dart';

class TestEstresQuestionScreen extends StatefulWidget {
  const TestEstresQuestionScreen({Key? key}) : super(key: key);

  @override
  _TestEstresQuestionScreenState createState() =>
      _TestEstresQuestionScreenState();
}

class _TestEstresQuestionScreenState extends State<TestEstresQuestionScreen> {
  bool isSubmitting = false;
  int currentQuestionIndex = 0;
  List<int> selectedOptions = List<int>.filled(23, 0); // Asigna un valor predeterminado (por ejemplo, 0)
  int? userId;
  bool? isDay21Completed;
  bool showingNotice = false;
  TestNotice? currentNotice;
  int? previousNoticeIndex;
  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Cargamos el ID del usuario y estado del día 21
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precargar las imágenes de los avisos solo una vez.
    if (!_imagesPrecached) {
      _precacheNoticeImages();
      _imagesPrecached = true;
    }
  }

  // Función para precargar las imágenes de los avisos en el caché.
  void _precacheNoticeImages() {
    for (var notice in testNotices) {
      if (notice.imagePath != null && notice.imagePath!.isNotEmpty) {
        precacheImage(NetworkImage(notice.imagePath!), context);
      }
    }
  }

  // Función para cargar el userId y estado del día 21 desde SharedPreferences
  Future<void> _loadUserData() async {
    int? id = await getUserId();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? day21Status = prefs.getBool('isDay21Completed');

    setState(() {
      userId = id;
      isDay21Completed = day21Status == true;

      if (userId == null) {
        print('Error: userId is null');
        return;
      } else {
        print('Success: userId cargado correctamente - $userId');
        print('Day 21 completed status: $isDay21Completed');
      }
    });
  }

  // Función para obtener el perfil del usuario
  Future<Map<String, dynamic>?> _getUserProfile() async {
    try {
      String? token = await getToken();
      if (token == null) {
        print('Error: No se encontró el token.');
        return null;
      }

      String url = '${Config.apiUrl2}/users/getprofile/$userId';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error al obtener perfil: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener perfil del usuario: $e');
      return null;
    }
  }

  // Función para mapear el género a ID
  int _getGenderIdFromProfile(String gender) {
    switch (gender.toLowerCase()) {
      case 'masculino':
        return 1;
      case 'femenino':
        return 2;
      case 'otro':
        return 3;
      default:
        return 1;
    }
  }

  // Función para seleccionar una opción
  void selectOption(int optionId) {
    setState(() {
      selectedOptions[currentQuestionIndex] =
          optionId; // Guarda la respuesta para la pregunta actual
    });
  }

  void goToNextQuestion() {
    if (selectedOptions[currentQuestionIndex] != 0) {
      TestNotice? notice;
      try {
        notice = testNotices.firstWhere(
              (n) => n.afterQuestion == currentQuestionIndex + 1,
        );
      } catch (e) {
        notice = null;
      }

      if (notice != null) {
        setState(() {
          showingNotice = true;
          currentNotice = notice;
          previousNoticeIndex = currentQuestionIndex;
        });
      } else if (currentQuestionIndex < questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una opción antes de continuar'),
        ),
      );
    }
  }

  void continueAfterNotice() {
    setState(() {
      showingNotice = false;
      currentNotice = null;
      previousNoticeIndex = null;
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      }
    });
  }

  void goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        // Verificar si hay un aviso en la pregunta anterior
        TestNotice? notice;
        try {
          notice = testNotices.firstWhere(
                (n) => n.afterQuestion == currentQuestionIndex + 1,
          );
        } catch (e) {
          notice = null;
        }

        if (notice != null) {
          showingNotice = true;
          currentNotice = notice;
          previousNoticeIndex = currentQuestionIndex;
        }
      });
    }
  }

  void goBackFromNotice() {
    setState(() {
      showingNotice = false;
      currentNotice = null;
      previousNoticeIndex = null;
      // No cambiar currentQuestionIndex, solo ocultar el aviso
    });
  }

  Future<void> submitTest() async {
    // Verificar si ya está en proceso de envío
    if (isSubmitting) {
      print("Test ya está siendo enviado");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor espera, el test se está procesando...')),
      );
      return;
    }

    // Mostrar pantalla de finalización
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestCompletionScreen(
          onFinalize: _processTestSubmission,
        ),
      ),
    );
  }

  Future<void> _processTestSubmission() async {
    try {
      // Activar el bloqueo
      setState(() {
        isSubmitting = true;
      });

      // Validar userId antes de proceder
      if (userId == null) {
        print("Error: userId es null");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se ha cargado el ID del usuario')),
        );
        return;
      }

      // Validar si selectedOptions está correctamente poblado
      if (selectedOptions.isEmpty || selectedOptions.length < 23) {
        print("Error: selectedOptions no tiene suficientes datos.");
        return;
      }

      String? token = await getToken();
      if (token == null) {
        print('Error: No se encontró el token.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Token no disponible')),
        );
        return;
      }

      final saveTestUrl = Uri.parse('${Config.apiUrl2}/stress-test/save');
      final updateEstresUrl = Uri.parse('${Config.apiUrl2}/users/$userId/estres-level');

      // Calcular el puntaje total
      int totalScore = selectedOptions.fold(0, (sum, value) => sum + value);

      // Obtener perfil del usuario desde apiUrl2
      Map<String, dynamic>? userProfile = await _getUserProfile();
      if (userProfile == null) {
        print('Error: No se pudo obtener el perfil del usuario');
        return;
      }

      // Obtener gender_id desde el perfil
      int genderId = _getGenderIdFromProfile(userProfile['gender'] ?? 'Masculino');

      // Calcular el nivel de estrés y su ID
      final Map<String, dynamic> estresResult = _calcularNivelEstres(totalScore, genderId);
      NivelEstres nivelEstres = estresResult['nivel'];
      int estresNivelId = estresResult['id'];

      // Determinar el tipo de test basado en si el día 21 fue completado
      String testType = (isDay21Completed == true) ? 'exit' : 'entry';

      // Preparar datos para la nueva API
      List<Map<String, dynamic>> testData = [];
      for (int i = 0; i < selectedOptions.length; i++) {
        testData.add({
          'user_id': userId,
          'question_id': i + 1, // Las preguntas van del 1 al 23
          'score': selectedOptions[i],
          'test_type': testType,
        });
      }

      // Guardar el test usando la nueva API
      final saveResponse = await http.post(
        saveTestUrl,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: json.encode(testData),
      );

      if (saveResponse.statusCode != 201) {
        print('Error al guardar el test: ${saveResponse.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el test')),
        );
        return;
      }

      print('Test guardado correctamente con tipo: $testType');

      if (testType == 'exit') {
        // Si es un test de salida (día 21 completado), actualizar el nivel de estrés
        final updateData = {
          'estres_level': estresNivelId,
          'type': 'final',
        };
        final updateResponse = await http.put(
          updateEstresUrl,
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer $token',
          },
          body: json.encode(updateData),
        );

        if (updateResponse.statusCode != 200) {
          print('Error al actualizar el estres_nivel_id: ${updateResponse.body}');
          return;
        }

        print('Nivel de estrés actualizado correctamente.');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDay21Completed', false);

        print("Test de salida completado, redirigiendo al HomeScreen.");

        // Redirigir al HomeScreen para test de salida
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
        );

        return;
      } else {
        // Test de entrada
        final updateData = {
          'estres_level': estresNivelId,
          'type': 'initial',
        };
        final updateResponse = await http.put(
          updateEstresUrl,
          headers: {
            "Content-Type": "application/json",
            'Authorization': 'Bearer $token',
          },
          body: json.encode(updateData),
        );

        if (updateResponse.statusCode != 200) {
          print('Error al crear el registro: ${updateResponse.body}');
          return;
        }

        print('Registro de nivel de estrés creado correctamente.');

        // Obtener company_id del perfil del usuario
        int? companyId = userProfile['company_id'] ?? userProfile['id_empresa'];

        // Verificar acceso a programas SOLO si company_id == 8
        if (companyId == 8) {
          final hasAccess = await SubscriptionService.hasAccessToPrograms();

          if (!hasAccess) {
            // Usuario no tiene acceso, mostrar diálogo de suscripción
            final shouldNavigate = await _showSubscriptionDialog();

            if (shouldNavigate == true) {
              // Usuario eligió suscribirse, navegar a pantalla de suscripción
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionScreen(showBackButton: false),
                ),
              );

              if (result == true) {
                // Suscripción exitosa, generar programa
                await _generateProgram(userProfile, totalScore);
                await _updateTestEstresBool();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CargarProgramaScreen(nivelEstres: nivelEstres),
                  ),
                );
              } else {
                // No se completó la suscripción, volver a index
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => IndexScreen(
                    username: '',
                    apiServiceWithToken: ApiService(),
                  )),
                      (Route<dynamic> route) => false,
                );
              }
            } else {
              // Usuario canceló, volver a index
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => IndexScreen(
                  username: '',
                  apiServiceWithToken: ApiService(),
                )),
                    (Route<dynamic> route) => false,
              );
            }
          } else {
            // Usuario tiene acceso (ya suscrito)
            await _generateProgram(userProfile, totalScore);
            await _updateTestEstresBool();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CargarProgramaScreen(nivelEstres: nivelEstres),
              ),
            );
          }
        } else {
          // Usuario NO es de company_id 8, generar programa directamente sin verificar suscripción
          await _generateProgram(userProfile, totalScore);
          await _updateTestEstresBool();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CargarProgramaScreen(nivelEstres: nivelEstres),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al procesar el test: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el test')),
      );
    } finally {
      // Desactivar el bloqueo al finalizar, sea éxito o error
      setState(() {
        isSubmitting = false;
      });
    }
  }

  Future<bool?> _showSubscriptionDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFF5027D0)),
              SizedBox(width: 8),
              Text('Funcy PRO'),
            ],
          ),
          content: Text(
            'Para obtener tu programa personalizado de 30 dias, debes suscribirte a Funcy PRO.\n\n¿Deseas suscribirte ahora?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5027D0),
                foregroundColor: Colors.white,
              ),
              child: Text('Suscribirme'),
            ),
          ],
        );
      },
    );
  }

  // Función para calcular el nivel de estrés
  Map<String, dynamic> _calcularNivelEstres(int totalScore, int genderId) {
    NivelEstres nivelEstres = NivelEstres.desconocido;
    int estresNivelId = 0;

    if (totalScore <= 92) {
      nivelEstres = NivelEstres.leve;
      estresNivelId = 1;
    } else if (totalScore > 92 && totalScore <= 138) {
      if (genderId == 1) {
        nivelEstres = NivelEstres.moderado;
        estresNivelId = 2;
      } else if (genderId == 2 || genderId == 3) { // Considerando 3 como otro género
        nivelEstres =
            totalScore <= 132 ? NivelEstres.moderado : NivelEstres.severo;
        estresNivelId = totalScore <= 132 ? 2 : 3;
      }
    } else if (totalScore > 138) {
      if (genderId == 1) {
        nivelEstres = NivelEstres.severo;
        estresNivelId = 3;
      } else if (genderId == 2 || genderId == 3) { // Considerando 3 como otro género
        nivelEstres = NivelEstres.severo;
        estresNivelId = 3;
      }
    }

    return {'nivel': nivelEstres, 'id': estresNivelId};
  }

  // Generar programa usando la nueva API
  Future<void> _generateProgram(Map<String, dynamic> userProfile, int totalScore) async {
    try {
      String? token = await getToken();
      if (token == null) {
        print('Error: No se encontró el token para generar programa.');
        return;
      }

      // Crear resumen de respuestas basado en el puntaje total
      String resumenRespuestas = _createResponseSummary(totalScore);

      // Obtener la fecha actual para startDate
      DateTime now = DateTime.now();
      String startDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Mapear el género para el userContext
      String genderCode = userProfile['gender'] == 'Masculino' ? 'M' :
                         userProfile['gender'] == 'Femenino' ? 'F' : 'O';

      final generateProgramUrl = Uri.parse('${Config.apiUrl2}/programs/generate');

      final Map<String, dynamic> programData = {
        'userId': userId,
        'goal': 'Reducir estrés laboral',
        'constraints': [
          'sin material externo',
          'sesiones < 15 minutos'
        ],
        'count': 21,
        'startDate': startDate,
        'tagDistribution': [
          {
            'tag': 'relajacion',
            'days': 7
          },
          {
            'tag': 'pensamiento-positivo',
            'days': 7
          },
          {
            'tag': 'visualizacion',
            'days': 7
          }
        ],
        'userContext': {
          'username': userProfile['username'] ?? '',
          'age_range': userProfile['ageRange'] ?? '',
          'hierarchical_level': userProfile['hierarchicalLevel'] ?? '',
          'responsability_level': userProfile['responsabilityLevel'] ?? '',
          'gender': genderCode,
          'estres_nivel': userProfile['estresLevel'] ?? '',
          'resumenRespuestas': resumenRespuestas
        }
      };

      print('Generando programa con los siguientes datos: $programData');
      final programResponse = await http.post(
        generateProgramUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(programData),
      );

      if (programResponse.statusCode == 200 || programResponse.statusCode == 201) {
        print('Programa generado correctamente.');
      } else {
        print('Error al generar el programa: ${programResponse.statusCode} - ${programResponse.body}');
      }
    } catch (e) {
      print('Error al generar el programa: $e');
    }
  }

  // Crear resumen de respuestas basado en el puntaje total
  String _createResponseSummary(int totalScore) {
    if (totalScore <= 92) {
      return 'Usuario presenta niveles bajos de estrés. Respuestas indican manejo adecuado de situaciones cotidianas.';
    } else if (totalScore <= 138) {
      return 'Usuario presenta niveles moderados de estrés. Se observan algunas dificultades en el manejo de situaciones laborales.';
    } else {
      return 'Usuario presenta niveles altos de estrés. Respuestas indican dificultades significativas en el manejo de presión y situaciones laborales.';
    }
  }

  // Actualizar testestresbool a true en el backend usando apiUrl2
  Future<void> _updateTestEstresBool() async {
    try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('testestresbool', true);
    } catch (e) {
      print('Error al actualizar testestresbool: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showingNotice && currentNotice != null) {
      return Scaffold(
        body: TestNoticeDialog(
          notice: currentNotice!,
          onContinue: continueAfterNotice,
          onBack: goBackFromNotice,
        ),
      );
    }

    // Verificación inicial para asegurarse de que 'questions' no esté vacío y que el índice esté en rango
    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return Scaffold(
        body: Center(
          child: Text("No hay preguntas disponibles"), // Mensaje de error si no hay preguntas
        ),
      );
    }

    // Asignar la pregunta actual solo si la lista de preguntas tiene contenido y el índice es válido
    final question = questions[currentQuestionIndex];

    // Obtener el ancho de la pantalla
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final isTablet = screenWidth > 600;

          // Tamaños responsivos
          final headerPadding = isTablet ? 24.0 : 16.0;
          final iconSize = isTablet ? 28.0 : 24.0;
          final titleFontSize = isTablet ? 20.0 : 16.0;
          final questionFontSize = isTablet ? 22.0 : 16.0;
          final descriptionFontSize = isTablet ? 19.0 : 16.0;
          final optionFontSize = isTablet ? 24.0 : 22.0;
          final buttonFontSize = isTablet ? 24.0 : 22.0;
          final horizontalPadding = isTablet ? 32.0 : 24.0;
          final maxContentWidth = isTablet ? 800.0 : double.infinity;

          return Container(
            color: Color(0xFFF6F6F6),
            child: Column(
              children: [
                // Header con icono de retroceso y título (fijo)
                Container(
                  margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: headerPadding,
                    ),
                    child: Row(
                      children: [
                        if (currentQuestionIndex > 0)
                          GestureDetector(
                            onTap: goToPreviousQuestion,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Color(0xFF4320AD),
                                size: iconSize,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 40 + (isTablet ? 8 : 0)),

                        Expanded(
                          child: Center(
                            child: Text(
                              'Pregunta ${currentQuestionIndex + 1} de ${questions.length}',
                              style: TextStyle(
                                color: const Color(0xFF4320AD),
                                fontSize: titleFontSize,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 40 + (isTablet ? 8 : 0)),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 30 : 20),

                // Pregunta (fija)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      children: [
                        if (question['question'] != null)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Text(
                              question['question']!,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: const Color(0xFF4320AD),
                                fontSize: questionFontSize,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        if (question['description'] != null) ...[
                          SizedBox(height: isTablet ? 16 : 12),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: Text(
                              question['description']!,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: descriptionFontSize,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 30 : 20),

                // Opciones scrolleables
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          children: List.generate(8, (index) {
                            final optionKey = 'option${index + 1}';
                            final detailKey = 'detail${index + 1}';
                            final optionText = question[optionKey];
                            final optionDetail = question[detailKey];

                            if (optionText == null || optionDetail == null) {
                              return SizedBox.shrink();
                            }

                            bool isSelected = selectedOptions[currentQuestionIndex] == (index + 1);

                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: isTablet ? 10.0 : 8.0),
                              child: GestureDetector(
                                onTap: () => selectOption(index + 1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isTablet ? 16 : 12,
                                    horizontal: isTablet ? 40 : 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Color(0x8E5027D0) : Colors.white,
                                    border: Border.all(
                                      width: 2,
                                      color: Color(0xFF6D4BD8),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        optionText,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Color(0xFF6D4BD8),
                                          fontSize: optionFontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (isSelected)
                                        Padding(
                                          padding: EdgeInsets.only(top: isTablet ? 12.0 : 8.0),
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "Detalle: ",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isTablet ? 16 : 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: optionDetail,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: isTablet ? 16 : 14,
                                                    fontWeight: FontWeight.w400,
                                                  ),
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
                          }),
                        ),
                      ),
                    ),
                  ),
                ),

                // Botón Siguiente/Finalizar (fijo)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    MediaQuery.of(context).padding.bottom + (isTablet ? 30 : 20),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Builder(
                        builder: (context) {
                          final bool isNextEnabled = selectedOptions[currentQuestionIndex] != 0;
                          final String nextLabel = currentQuestionIndex < questions.length - 1 ? 'Siguiente' : 'Continuar';

                          return GestureDetector(
                            onTap: isNextEnabled && !isSubmitting
                                ? () {
                              if (currentQuestionIndex < questions.length - 1) {
                                goToNextQuestion();
                              } else {
                                submitTest();
                              }
                            }
                                : null,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                              decoration: ShapeDecoration(
                                color: (isNextEnabled && !isSubmitting) ? const Color(0xFF6D4BD8) : const Color(0xFFD7D7D7),
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
                                ]
                                    : const [],
                              ),
                              child: Center(
                                child: isSubmitting
                                    ? SizedBox(
                                  width: isTablet ? 24 : 20,
                                  height: isTablet ? 24 : 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(
                                  nextLabel,
                                  style: TextStyle(
                                    color: (isNextEnabled && !isSubmitting)
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}