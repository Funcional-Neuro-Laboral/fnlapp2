import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:fnlapp/Main/prevtestestres.dart';
import 'package:fnlapp/Politicas%20y%20Terminos/condiciones_uso.dart';
import 'package:fnlapp/Politicas%20y%20Terminos/politica_privacidad.dart';
import 'package:http/http.dart' as http;
import 'package:fnlapp/SharedPreferences/sharedpreference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fnlapp/config.dart';
import '../Main/widgets/index_summary.dart';
import '../Util/api_service.dart';

class _FnlColors {
  static const blue = Color(0xFF0B1457);
  static const violet = Color(0xFF6428E8);
  static const violetSecondary = Color(0xFF814CF4);
  static const gradientStart = Color(0xFF5425E8);
  static const lavender = Color(0xFFF4F1FF);
  static const lavenderDeep = Color(0xFFEAE4FC);
  static const canvas = Color(0xFFFCFBFF);
  static const body = Color(0xFF70779C);
  static const label = Color(0xFF5F668B);
  static const border = Color(0xFFD9DCEF);
  static const bubbleBorder = Color(0xFFDCD3FA);
  static const disabledText = Color(0xFF9AA0C0);
  static const white = Color(0xFFFFFFFF);
}

class _FnlSpace {
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
}

class _FnlText {
  static TextStyle h2(double size) => GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: _FnlColors.blue,
        height: 1.25,
      );

  static TextStyle body({Color color = _FnlColors.body}) => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle consent() => GoogleFonts.roboto(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: _FnlColors.blue,
        height: 1.5,
      );

  static TextStyle link() => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _FnlColors.violet,
        height: 1.5,
      );

  static TextStyle label({Color color = _FnlColors.label}) =>
      GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle option({required bool selected}) => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: selected ? _FnlColors.violet : _FnlColors.blue,
        height: 1.35,
      );

  static TextStyle button({Color color = _FnlColors.white}) =>
      GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

class IndexScreen extends StatefulWidget {
  final String username;
  final ApiService apiServiceWithToken;

  IndexScreen({required this.username, required this.apiServiceWithToken});

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  // Mascota Funcy (imágenes remotas)
  static const String _thinkingUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/thinking.png';
  static const String _happyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/happy.png';

  static const int _totalQuestions = 6;
  static const List<String> _categoryKeys = [
    'age_range',
    'gender',
    'area',
    'level',
    'responsability_level',
    'sede',
  ];
  static const List<String> _questionTexts = [
    '¿Cuál es tu rango de edad?',
    '¿Cuál es tu género?',
    '¿Cuál es tu Área?',
    '¿Cuál es tu posición en la organización?',
    '¿Cuál es tu nivel de responsabilidad en tu organización?',
    '¿A que sede perteneces?',
  ];

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
  bool _imagesPrecached = false;

  // Recognizers de los enlaces legales (se crean una vez y se liberan en dispose)
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

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
    _privacyTap = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PoliticaPrivacidadScreen()),
        );
      };
    _termsTap = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CondicionesUsoScreen()),
        );
      };

    _loadUserData();
    _loadUserProgress();
    fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precacheImage necesita el context ya enlazado: no puede ir en initState
    if (!_imagesPrecached) {
      _imagesPrecached = true;
      _precacheImages();
    }
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  Future<void> _precacheImages() async {
    await Future.wait([
      precacheImage(const NetworkImage(_thinkingUrl), context),
      precacheImage(const NetworkImage(_happyUrl), context),
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

    print('Username: $username');
    print('User ID: $userId');
    print('Email: $email');
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

      if (!mounted) return;

      if (response.statusCode == 200) {
        print('Campo permisopoliticas actualizado correctamente.');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('permisopoliticas', true);

        if (!mounted) return;
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
      if (!mounted) return;
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
          final hierarchicalLevels =
              data.map((item) => Map<String, dynamic>.from(item)).toList();

          if (!mounted) return;
          setState(() {
            questionCategories['level'] = hierarchicalLevels;
          });

          print(
              'Niveles jerárquicos cargados correctamente (${hierarchicalLevels.length}).');
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

      var uriArea = Uri.parse('general/area/by-user')
          .replace(queryParameters: queryParams);
      var areasResponse =
          await widget.apiServiceWithToken.get(uriArea.toString());

      var areasData = json.decode(areasResponse.body);
      var areas = areasData as List;

      if (areas.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          questionCategories['area'] =
              areas.map((item) => Map<String, dynamic>.from(item)).toList();
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
          var category =
              data.map((item) => Map<String, dynamic>.from(item)).toList();

          if (i == 0) {
            questionCategories['age_range'] = category;
          } else if (i == 1) {
            questionCategories['responsability_level'] = category;
          } else if (i == 2) {
            questionCategories['gender'] = category;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        loading = false;
      });

      print('Las preguntas se cargaron correctamente.');
    } catch (e) {
      if (!mounted) return;
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

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Future<void> saveResponses() async {
    print('Selected Answers: $selectedAnswers');

    if (selectedAnswers[5] == null) {
      if (selectedOption != null) {
        selectedAnswers[currentQuestionIndex] = selectedOption;
      }
    }

    String? token = await getToken();

    // Los valores pueden venir como String desde la UI
    final int? ageRangeId = _asInt(selectedAnswers[0]);
    final int? genderId = _asInt(selectedAnswers[1]);
    final int? hierarchicalLevelId = _asInt(selectedAnswers[3]);
    final int? responsabilityLevelId = _asInt(selectedAnswers[4]);
    final int? branchId = _asInt(selectedAnswers[5]);

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

        if (!mounted) return;
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar respuestas.')),
        );
      }
    } catch (e) {
      print('Error al enviar respuestas: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar respuestas.')),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: _FnlBackground(
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _FnlColors.violet,
                ),
              )
            : agreedToTerms
                ? _buildQuestionsScreen()
                : _buildWelcomeScreen(),
      ),
    );
  }

  // ── Pantalla de privacidad ───────────────────────────────────
  Widget _buildWelcomeScreen() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final isSmallHeight = constraints.maxHeight < 700;
          final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
          final maxContentWidth = isTablet ? 720.0 : double.infinity;
          final mascotSize = isTablet
              ? 170.0
              : isSmallHeight
                  ? 96.0
                  : 130.0;

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          hPad, _FnlSpace.md, hPad, _FnlSpace.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MascotHalo(url: _thinkingUrl, size: mascotSize),
                          const SizedBox(height: _FnlSpace.sm),
                          Text(
                            'Tu privacidad nos importa',
                            textAlign: TextAlign.center,
                            style: _FnlText.h2(isTablet ? 32 : 26),
                          ),
                          const SizedBox(height: _FnlSpace.md),
                          _ConsentCard(
                            checked: acceptedProcessing,
                            onTap: () {
                              setState(() {
                                acceptedProcessing = !acceptedProcessing;
                                _updateAgreedToAll();
                              });
                            },
                            spans: [
                              _consentText('Acepto la '),
                              _privacyLink(),
                              _consentText(' y las '),
                              TextSpan(
                                text: 'Condiciones de uso',
                                style: _FnlText.link(),
                                recognizer: _termsTap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ConsentCard(
                            checked: acceptedProcessing1,
                            onTap: () {
                              setState(() {
                                acceptedProcessing1 = !acceptedProcessing1;
                                _updateAgreedToAll();
                              });
                            },
                            spans: [
                              _consentText(
                                  'Acepto el procesamiento de mis datos personales de salud con el fin de facilitar las funciones de la aplicación. Ver más en la '),
                              _privacyLink(),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ConsentCard(
                            checked: acceptedTracking,
                            onTap: () {
                              setState(() {
                                acceptedTracking = !acceptedTracking;
                                _updateAgreedToAll();
                              });
                            },
                            spans: [
                              _consentText(
                                  'Autorizo a la empresa a recopilar y utilizar información sobre mi actividad en aplicaciones y sitios web relacionados, así como datos necesarios para evaluar mi nivel de estrés y bienestar laboral, conforme a lo establecido en la '),
                              _privacyLink(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    hPad, _FnlSpace.xs, hPad, _FnlSpace.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SecondaryButton(
                          label: 'Aceptar todo',
                          icon: Icons.done_all_rounded,
                          onTap: () {
                            setState(() {
                              acceptedProcessing = true;
                              acceptedProcessing1 = true;
                              acceptedTracking = true;
                              _updateAgreedToAll();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _PrimaryButton(
                          label: 'Continuar',
                          icon: Icons.arrow_forward_rounded,
                          enabled: agreedToAll,
                          onTap: () {
                            _handleAcceptAll();
                            setState(() {
                              agreedToTerms = true;
                              currentQuestionIndex = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TextSpan _consentText(String text) =>
      TextSpan(text: text, style: _FnlText.consent());

  TextSpan _privacyLink() => TextSpan(
        text: 'Política de privacidad',
        style: _FnlText.link(),
        recognizer: _privacyTap,
      );

  // ── Preguntas de perfil ──────────────────────────────────────
  Widget _buildQuestionsScreen() {
    final lookupIndex = currentQuestionIndex.clamp(0, _totalQuestions - 1);
    final categoryKey = _categoryKeys[lookupIndex];
    final questionText = _questionTexts[lookupIndex];
    final options = questionCategories[categoryKey] ?? [];

    final bool isNextEnabled = selectedOption != null ||
        selectedAnswers.containsKey(currentQuestionIndex);
    final bool isLast = currentQuestionIndex >= _totalQuestions - 1;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final isSmallHeight = constraints.maxHeight < 650;
          final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
          final maxContentWidth = isTablet ? 720.0 : double.infinity;
          final mascotSize = isTablet
              ? 120.0
              : isSmallHeight
                  ? 72.0
                  : 96.0;

          return Column(
            children: [
              _buildQuestionHeader(hPad, maxContentWidth),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          hPad, _FnlSpace.xs, hPad, _FnlSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MascotHalo(url: _happyUrl, size: mascotSize),
                          const SizedBox(height: _FnlSpace.xs),
                          _SpeechBubble(
                            child: Text(
                              questionText,
                              textAlign: TextAlign.center,
                              style: _FnlText.h2(isTablet ? 24 : 20),
                            ),
                          ),
                          const SizedBox(height: _FnlSpace.md),
                          if (options.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No se encontraron preguntas para esta categoría.',
                                textAlign: TextAlign.center,
                                style: _FnlText.body(),
                              ),
                            )
                          else
                            ...options.map(_buildOption),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    hPad, _FnlSpace.sm, hPad, _FnlSpace.md),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: _PrimaryButton(
                      label: isLast ? 'Continuar' : 'Siguiente',
                      icon: Icons.arrow_forward_rounded,
                      enabled: isNextEnabled,
                      onTap: _onNextPressed,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onNextPressed() {
    if (currentQuestionIndex < _totalQuestions - 1) {
      goToNextQuestion();
    } else {
      // Navegar a la pantalla de resumen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IndexSummaryScreen(
            onFinalize: saveResponses,
            onBack: () {
              Navigator.pop(context); // Retroceder a la pantalla de preguntas
            },
          ),
        ),
      );
    }
  }

  Widget _buildOption(Map<String, dynamic> question) {
    final id = question['id'].toString();
    final isSelected = selectedOption == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _OptionTile(
        label: _getOptionText(question),
        selected: isSelected,
        onTap: () {
          setState(() {
            selectedOption = id;
          });

          if (currentQuestionIndex == 2) {
            final areaId = _asInt(question['id']);
            if (areaId != null) fetchHierarchicalLevel(areaId);
          }
        },
      ),
    );
  }

  // Header: retroceso + contador + barra de progreso
  Widget _buildQuestionHeader(double hPad, double maxContentWidth) {
    final progress = (currentQuestionIndex + 1) / _totalQuestions;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, _FnlSpace.sm, hPad, _FnlSpace.xs),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: currentQuestionIndex > 0
                        ? Material(
                            color: _FnlColors.white,
                            shape: const CircleBorder(
                              side: BorderSide(
                                  color: _FnlColors.bubbleBorder, width: 2),
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: goToPreviousQuestion,
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: _FnlColors.violet,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Pregunta ${currentQuestionIndex + 1} de $_totalQuestions',
                        style: _FnlText.label(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: _FnlSpace.sm),
              _ProgressBar(progress: progress),
            ],
          ),
        ),
      ),
    );
  }

  void _updateAgreedToAll() {
    setState(() {
      agreedToAll =
          acceptedProcessing && acceptedTracking && acceptedProcessing1;
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Componentes reutilizables
// ─────────────────────────────────────────────────────────────

/// Fondo con círculos decorativos (mismo lenguaje que bienvenida y test).
class _FnlBackground extends StatelessWidget {
  final Widget child;
  const _FnlBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Positioned.fill(child: child),
      ],
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

/// Funcy con halo suave.
class _MascotHalo extends StatelessWidget {
  final String url;
  final double size;
  const _MascotHalo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _FnlColors.violetSecondary.withOpacity(0.22),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Image.network(
            url,
            height: size,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: size,
                width: size,
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _FnlColors.violetSecondary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => SizedBox(height: size, width: size),
          ),
        ],
      ),
    );
  }
}

/// Globo de diálogo con colita apuntando a Funcy.
class _SpeechBubble extends StatelessWidget {
  final Widget child;
  const _SpeechBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_FnlSpace.md),
            decoration: BoxDecoration(
              color: _FnlColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: _FnlColors.bubbleBorder,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
        ),
        Positioned(
          top: 2,
          child: Transform.rotate(
            angle: 0.785398, // 45°
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: _FnlColors.white,
                border: Border(
                  top: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                  left: BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra de progreso gruesa y redondeada.
class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _FnlColors.lavenderDeep,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _FnlColors.gradientStart,
                  _FnlColors.violetSecondary,
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opción de respuesta: tarjeta "chunky" estilo caricatura.
class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: _FnlSpace.sm, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _FnlColors.lavender : _FnlColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 2,
            color: selected ? _FnlColors.violet : _FnlColors.border,
          ),
          // Sombra sólida abajo: efecto botón de juego
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _FnlColors.violet.withOpacity(0.35)
                  : _FnlColors.border,
              offset: Offset(0, selected ? 2 : 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            _SelectionDot(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: _FnlText.option(selected: selected)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador circular de selección con animación.
class _SelectionDot extends StatelessWidget {
  final bool selected;
  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? _FnlColors.violet : _FnlColors.white,
        border: Border.all(
          width: selected ? 0 : 2,
          color: _FnlColors.border,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: _FnlColors.white)
          : null,
    );
  }
}

/// Tarjeta de consentimiento con casilla cuadrada y texto enriquecido.
class _ConsentCard extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  final List<TextSpan> spans;

  const _ConsentCard({
    required this.checked,
    required this.onTap,
    required this.spans,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.all(_FnlSpace.sm),
        decoration: BoxDecoration(
          color: checked ? _FnlColors.lavender : _FnlColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            width: 2,
            color: checked ? _FnlColors.violet : _FnlColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: checked
                  ? _FnlColors.violet.withOpacity(0.35)
                  : _FnlColors.border,
              offset: Offset(0, checked ? 2 : 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: checked ? _FnlColors.violet : _FnlColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  width: checked ? 0 : 2,
                  color: _FnlColors.border,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: _FnlColors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(TextSpan(children: spans)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón primario FNL: 56 px, radio 18, violeta sólido.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    final Color fg = enabled ? _FnlColors.white : _FnlColors.disabledText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: enabled ? _FnlColors.violet : _FnlColors.border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: _FnlText.button(color: fg)),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 20, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario: lavanda con borde, texto violeta.
class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _SecondaryButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _FnlColors.lavender,
        borderRadius: radius,
        border: Border.all(color: _FnlColors.bubbleBorder, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: _FnlColors.violet),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: _FnlText.button(color: _FnlColors.violet)
                      .copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}