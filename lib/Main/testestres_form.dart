import 'package:flutter/material.dart';
import 'package:fnlapp/Main/models/test_notice.dart';
import 'package:fnlapp/Main/subscription_screen.dart';
import 'package:fnlapp/Main/widgets/test_completion_screen.dart';
import 'package:fnlapp/Main/widgets/test_notice_dialog.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:fnlapp/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Preguntas/index.dart';
import '../Preguntas/questions_data.dart';
import 'package:fnlapp/Main/home.dart';
import '../Util/api_service.dart';
import '../Util/test_notices_data.dart';
import '../services/subscription_service.dart';
import 'package:fnlapp/Main/certificate_screen.dart';
import 'package:fnlapp/Main/stress_result_screen.dart';
import '../Util/stress_factors.dart';
import '../theme/app_colors.dart';
import '../widgets/app_buttons.dart';

class TestEstresQuestionScreen extends StatefulWidget {
  const TestEstresQuestionScreen({Key? key}) : super(key: key);

  @override
  _TestEstresQuestionScreenState createState() =>
      _TestEstresQuestionScreenState();
}

class _TestEstresQuestionScreenState extends State<TestEstresQuestionScreen> {
  bool isSubmitting = false;
  int currentQuestionIndex = 0;
  List<int> selectedOptions = List<int>.filled(
      23, 0); // Asigna un valor predeterminado (por ejemplo, 0)
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

  // Función para verificar si el usuario es de company 8 usando múltiples métodos
  Future<bool> _isCompany8User() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // MÉTODO 1: Verificar desde SharedPreferences (guardado en IndexScreen)
      int? branchId = prefs.getInt('branch_id');
      int? companyId = prefs.getInt('company_id');

      print(
          'DEBUG: SharedPreferences - company_id = $companyId, branch_id = $branchId');

      // Lista de branch_ids que pertenecen a la empresa ID 8 (General)
      List<int> company8BranchIds = [9];

      if (companyId == 8 ||
          (branchId != null && company8BranchIds.contains(branchId))) {
        print(
            'DEBUG: Usuario identificado como company 8 desde SharedPreferences');
        return true;
      }

      // MÉTODO 2: Verificar desde userProfile usando companyName
      Map<String, dynamic>? userProfile = await _getUserProfile();
      if (userProfile != null) {
        String? companyName = userProfile['companyName'];
        print('DEBUG: companyName desde perfil = $companyName');

        // "General" es el nombre de la empresa ID 8
        if (companyName != null && companyName.toLowerCase() == 'general') {
          print(
              'DEBUG: Usuario identificado como company 8 por companyName="General"');
          return true;
        }
      }

      print('DEBUG: Usuario NO es de company 8');
      return false;
    } catch (e) {
      print('Error al verificar company 8: $e');
      return false;
    }
  }

  // Función para formatear fecha en español
  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
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

    // Solo mostrar TestCompletionScreen para test de entrada
    // Para test de salida, procesar directamente
    if (isDay21Completed == true) {
      // Test de salida: procesar directamente sin pantalla de completion
      await _processTestSubmission();
    } else {
      // Test de entrada: mostrar pantalla de finalización
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestCompletionScreen(
            onFinalize: _processTestSubmission,
          ),
        ),
      );
    }
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
      final updateEstresUrl =
          Uri.parse('${Config.apiUrl2}/users/$userId/estres-level');

      // Calcular el puntaje total
      int totalScore = selectedOptions.fold(0, (sum, value) => sum + value);

      // Obtener perfil del usuario desde apiUrl2
      Map<String, dynamic>? userProfile = await _getUserProfile();
      if (userProfile == null) {
        print('Error: No se pudo obtener el perfil del usuario');
        return;
      }

      // Obtener gender_id desde el perfil
      int genderId =
          _getGenderIdFromProfile(userProfile['gender'] ?? 'Masculino');

      // Calcular el nivel de estrés y su ID
      final Map<String, dynamic> estresResult =
          _calcularNivelEstres(totalScore, genderId);
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

      // Guardar el resultado en el dispositivo para mostrarlo en "Mi test".
      final factors = topStressFactors(selectedOptions);
      await LastStressResult(
        score: totalScore,
        nivel: nivelEstres,
        date: DateTime.now(),
        factors: factors,
        testType: testType,
      ).save();

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
          print(
              'Error al actualizar el estres_nivel_id: ${updateResponse.body}');
          return;
        }

        print('Nivel de estrés actualizado correctamente.');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        // Ocultar el botón del exit test y activar el botón del certificado
        await prefs.setBool('isDay21Completed', false);
        await prefs.setBool('hasCompletedExitTest', true);

        print("Test de salida completado, navegando a CertificateScreen.");

        // Obtener nombre del usuario para el certificado
        String userName = userProfile['fullName'] ??
            userProfile['name'] ??
            '${userProfile['names'] ?? 'Usuario'} ${userProfile['lastnames'] ?? ''}';

        // Formatear fecha actual
        String completionDate = _formatDate(DateTime.now());

        // Mostrar el resultado del test de salida y, desde ahí, el certificado.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (resultContext) => StressResultScreen(
              nivel: nivelEstres,
              score: totalScore,
              factors: factors,
              primaryLabel: 'Ver mi certificado',
              onPrimary: () => Navigator.of(resultContext).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => CertificateScreen(
                    username: userName.trim(),
                    completionDate: completionDate,
                    programName: 'Programa de Manejo de Estrés Laboral - 21 Días',
                  ),
                ),
              ),
            ),
          ),
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

        // Verificar si el usuario pertenece a la empresa 8 (General)
        bool isCompany8 = await _isCompany8User();

        print('DEBUG: isCompany8 = $isCompany8');

        // Verificar acceso a programas SOLO si es de company_id 8
        if (isCompany8) {
          final hasAccess = await SubscriptionService.hasAccessToPrograms();

          if (!hasAccess) {
            // Usuario no tiene acceso, mostrar diálogo de suscripción
            final shouldNavigate = await _showSubscriptionDialog();

            if (shouldNavigate == true) {
              // Usuario eligió suscribirse, navegar a pantalla de suscripción
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SubscriptionScreen(showBackButton: false),
                ),
              );

              if (result == true) {
                // Suscripción exitosa, generar programa
                await _generateProgram(userProfile, totalScore);
                await _updateTestEstresBool();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        _entryResult(nivelEstres, totalScore, factors),
                  ),
                );
              } else {
                // No se completó la suscripción, volver a index
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => IndexScreen(
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
                MaterialPageRoute(
                    builder: (context) => IndexScreen(
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
                builder: (context) =>
                    _entryResult(nivelEstres, totalScore, factors),
              ),
            );
          }
        } else {
          // Usuario NO es de company_id 8 (empresas con suscripción corporativa)
          // Generar programa directamente sin verificar suscripción individual
          await _generateProgram(userProfile, totalScore);
          await _updateTestEstresBool();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  _entryResult(nivelEstres, totalScore, factors),
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

  /// Resultado del test de entrada; desde ahí se entra al plan.
  Widget _entryResult(NivelEstres nivel, int score, List<StressFactor> factors) {
    return Builder(
      builder: (resultContext) => StressResultScreen(
        nivel: nivel,
        score: score,
        factors: factors,
        primaryLabel: 'Ver mi plan de 21 días',
        onPrimary: () => Navigator.of(resultContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        ),
      ),
    );
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
      } else if (genderId == 2 || genderId == 3) {
        // Considerando 3 como otro género
        nivelEstres =
            totalScore <= 132 ? NivelEstres.moderado : NivelEstres.severo;
        estresNivelId = totalScore <= 132 ? 2 : 3;
      }
    } else if (totalScore > 138) {
      if (genderId == 1) {
        nivelEstres = NivelEstres.severo;
        estresNivelId = 3;
      } else if (genderId == 2 || genderId == 3) {
        // Considerando 3 como otro género
        nivelEstres = NivelEstres.severo;
        estresNivelId = 3;
      }
    }

    return {'nivel': nivelEstres, 'id': estresNivelId};
  }

  // Generar programa usando la nueva API
  Future<void> _generateProgram(
      Map<String, dynamic> userProfile, int totalScore) async {
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
      String startDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Mapear el género para el userContext
      String genderCode = userProfile['gender'] == 'Masculino'
          ? 'M'
          : userProfile['gender'] == 'Femenino'
              ? 'F'
              : 'O';

      final generateProgramUrl =
          Uri.parse('${Config.apiUrl2}/programs/generate');

      final Map<String, dynamic> programData = {
        'userId': userId,
        'goal': 'Reducir estrés laboral',
        'constraints': ['sin material externo', 'sesiones < 15 minutos'],
        'count': 21,
        'startDate': startDate,
        'tagDistribution': [
          {'tag': 'relajacion', 'days': 7},
          {'tag': 'pensamiento-positivo', 'days': 7},
          {'tag': 'visualizacion', 'days': 7}
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

      if (programResponse.statusCode == 200 ||
          programResponse.statusCode == 201) {
        print('Programa generado correctamente.');
      } else {
        print(
            'Error al generar el programa: ${programResponse.statusCode} - ${programResponse.body}');
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
      return const Scaffold(
        body: Center(child: Text('No hay preguntas disponibles')),
      );
    }

    final question = questions[currentQuestionIndex];
    final total = questions.length;
    final isLast = currentQuestionIndex >= total - 1;
    final isNextEnabled = selectedOptions[currentQuestionIndex] != 0 && !isSubmitting;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 20, 0),
                  child: Row(
                    children: [
                      if (currentQuestionIndex > 0)
                        IconButton(
                          tooltip: 'Pregunta anterior',
                          onPressed: isSubmitting ? null : goToPreviousQuestion,
                          style: IconButton.styleFrom(backgroundColor: AppColors.muted, minimumSize: const Size(44, 44)),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
                        )
                      else
                        const SizedBox(width: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: Text('Pregunta ${currentQuestionIndex + 1} de $total',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSecondary)),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: (currentQuestionIndex + 1) / total,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE6E2F0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                    children: [
                      if (question['question'] != null)
                        Semantics(
                          header: true,
                          child: Text(question['question']!, style: textTheme.titleMedium?.copyWith(height: 26 / 18)),
                        ),
                      if (question['description'] != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          question['description']!,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                        ),
                      ],
                      const SizedBox(height: 20),
                      for (var index = 0; index < 8; index++)
                        if (question['option${index + 1}'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AnswerOption(
                              label: question['option${index + 1}']!,
                              detail: question['detail${index + 1}'],
                              selected: selectedOptions[currentQuestionIndex] == index + 1,
                              onTap: () => selectOption(index + 1),
                            ),
                          ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
                  child: AppPrimaryButton(
                    label: isLast ? 'Ver mi resultado' : 'Siguiente',
                    loading: isSubmitting,
                    onPressed: isNextEnabled
                        ? () {
                            if (!isLast) {
                              goToNextQuestion();
                            } else {
                              submitTest();
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({required this.label, required this.selected, required this.onTap, this.detail});

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      hint: selected ? detail : null,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.selected : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(fontSize: 16, height: 22 / 16, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: selected && detail != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(detail!,
                                      style: const TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.inkSecondary)),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: selected ? AppColors.primary : const Color(0xFFB9B3CC), width: 2),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
