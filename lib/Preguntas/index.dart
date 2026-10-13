import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  const IndexScreen({
    super.key,
    required this.username,
    required this.apiServiceWithToken,
  });

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

enum _QuestionKey {
  ageRange,
  gender,
  area,
  hierarchicalLevel,
  responsabilityLevel,
  branch,
}

typedef _QuestionAnswer = ({int value, String label});

class _IndexScreenState extends State<IndexScreen> {
  // Mascota Funcy (imágenes remotas)
  static const String _thinkingUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/thinking.png';
  static const String _happyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/happy.png';

  static const Map<_QuestionKey, String> questionByKey = {
    _QuestionKey.ageRange: '¿Cuál es tu rango de edad?',
    _QuestionKey.gender: '¿Cuál es tu género?',
    _QuestionKey.area: '¿Cuál es tu área?',
    _QuestionKey.hierarchicalLevel: '¿Cuál es tu posición en la organización?',
    _QuestionKey.responsabilityLevel:
        '¿Cuál es tu nivel de responsabilidad en tu organización?',
    _QuestionKey.branch: '¿A que sede perteneces?',
  };

  Map<_QuestionKey, List<_QuestionAnswer>> answersByKey = {};
  Map<_QuestionKey, int> selectedAnswerByKey = {};
  List<_QuestionKey> usedKeys = [];
  int currentKeyIndex = 0;

  bool loading = true;
  bool agreedToTerms = false;
  bool acceptedProcessing = false;
  bool acceptedProcessing1 = false;
  bool acceptedTracking = false;
  bool agreedToAll = false;
  int? userId;
  int? selectedOption;
  bool _imagesPrecached = false;

  // Carga de niveles jerárquicos (dependen del área elegida)
  bool _loadingLevels = false;
  int? _levelsAreaId;

  static const int _generalCompanyId = 8;
  static const int _generalHierarchicalLevelId = 109;
  static const int _generalBranchId = 9;
  bool _isGeneralUser = false;

  // Recognizers de los enlaces legales (se crean una vez y se liberan en dispose)
  late final TapGestureRecognizer _privacyTap;
  late final TapGestureRecognizer _termsTap;

  /// Logs solo en modo debug (nunca imprimir tokens ni datos sensibles).
  void _log(Object? message) {
    if (kDebugMode) debugPrint('$message');
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
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final terms = prefs.getBool('permisopoliticas') ?? false;
    final userResponseDone = prefs.getBool('userresponsebool') ?? false;
    final testEstresDone = prefs.getBool('testestresbool') ?? false;

    if (terms && userResponseDone) {
      if (!testEstresDone) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TestEstresScreen()),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    setState(() {
      agreedToTerms = terms;
      currentKeyIndex = 0;
    });
  }

  Future<void> _loadUserData() async {
    final username = await getUsername();
    userId = await getUserId();
    final email = await getEmail();

    _log('Username: $username');
    _log('User ID: $userId');
    _log('Email: $email');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updatePermisoPoliticas() async {
    try {
      userId ??= await getUserId();
      if (userId == null) {
        _log('No se encontró el ID del usuario.');
        return;
      }

      final token = await getToken();
      if (token == null) {
        _log('No se encontró el token de autenticación.');
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
        _log('Campo permisopoliticas actualizado correctamente.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('permisopoliticas', true);
        _showSnack('Permisos aceptados y actualizados.');
      } else {
        _log('Error al actualizar permisopoliticas: ${response.statusCode}');
        _showSnack('Error al actualizar permisos.');
      }
    } catch (e) {
      _log('Error: $e');
      _showSnack('Error al conectar con el servidor.');
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
    await fetchQuestions();
    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  /// Reintenta la carga de preguntas desde la pantalla de error.
  Future<void> _retryLoad() async {
    setState(() => loading = true);
    await fetchData();
  }

  /// Pide una lista de opciones al backend y la convierte a [_QuestionAnswer].
  Future<List<_QuestionAnswer>> fetchQuestionEndpoint(
    final String endpoint,
    final String valueName,
    final String labelName,
  ) async {
    final response = await widget.apiServiceWithToken.get(endpoint);
    if (response.statusCode != 200) {
      throw Exception(
          'Endpoint $endpoint returned HTTP status ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data is! List || data.isEmpty) {
      throw Exception('Endpoint $endpoint returned empty data');
    }

    return data.map<_QuestionAnswer>((item) {
      final value = int.tryParse('${item[valueName]}');
      if (value == null) {
        throw FormatException(
            'Endpoint $endpoint returned an invalid "$valueName": ${item[valueName]}');
      }
      return (
        value: value,
        label: '${item[labelName] ?? 'Valor no disponible'}',
      );
    }).toList();
  }

  Future<void> fetchHierarchicalLevel(int areaId) async {
    _levelsAreaId = areaId;
    if (mounted) {
      setState(() {
        _loadingLevels = true;
        answersByKey[_QuestionKey.hierarchicalLevel] = [];
      });
    }

    try {
      final levels = await fetchQuestionEndpoint(
        'general/hierarchical-levels/by-area?areaId=$areaId',
        'id',
        'level',
      );

      // Si el usuario ya eligió otra área, esta respuesta quedó obsoleta
      if (!mounted || _levelsAreaId != areaId) return;
      setState(() {
        answersByKey[_QuestionKey.hierarchicalLevel] = levels;
        _loadingLevels = false;
      });
    } catch (e, stackTrace) {
      _log('Excepción al cargar niveles jerárquicos: $e');
      _log(stackTrace);
      if (!mounted || _levelsAreaId != areaId) return;
      setState(() => _loadingLevels = false);
    }
  }

  Future<int> _fetchCompanyId() async {
    final response = await widget.apiServiceWithToken.get('users/form-config');
    if (response.statusCode != 200) {
      throw Exception(
          'users/form-config returned HTTP status ${response.statusCode}');
    }

    final body = json.decode(response.body);
    final companyId = int.tryParse('${body['data']?['company_id']}');
    if (companyId == null) {
      throw const FormatException('users/form-config returned no company_id');
    }
    return companyId;
  }

  Future<void> fetchQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // No depender de que _loadUserData haya terminado
      userId ??= await getUserId();

      final answers = <_QuestionKey, List<_QuestionAnswer>>{};
      final keys = <_QuestionKey>[];

      answers[_QuestionKey.ageRange] =
          await fetchQuestionEndpoint('general/age-ranges', 'id', 'age_range');
      answers[_QuestionKey.gender] =
          await fetchQuestionEndpoint('general/gender/all', 'id', 'gender');
      keys.add(_QuestionKey.ageRange);
      keys.add(_QuestionKey.gender);

      // company_id viene del backend (validado por el token del usuario)
      final companyId = await _fetchCompanyId();
      await prefs.setInt('company_id', companyId); // compatibilidad con el resto de la app
      final isNaturalUser = companyId == _generalCompanyId;
      _isGeneralUser = isNaturalUser;

      if (!isNaturalUser) {
        if (userId == null) {
          throw Exception('No se pudo obtener el ID del usuario');
        }
        answers[_QuestionKey.area] = await fetchQuestionEndpoint(
            'general/area/by-user?iduser=$userId', 'id', 'area');
        // Los niveles jerárquicos se cargan al elegir el área
        answers[_QuestionKey.hierarchicalLevel] = [];
        keys.add(_QuestionKey.area);
        keys.add(_QuestionKey.hierarchicalLevel);
      }

      answers[_QuestionKey.responsabilityLevel] = await fetchQuestionEndpoint(
          'general/responsibility-levels/all', 'id', 'responsability_level');
      keys.add(_QuestionKey.responsabilityLevel);

      if (!isNaturalUser) {
        answers[_QuestionKey.branch] = await fetchQuestionEndpoint(
            'general/branches/by-user?iduser=$userId', 'id', 'sede');
        keys.add(_QuestionKey.branch);
      }

      if (!mounted) return;
      setState(() {
        answersByKey = answers;
        usedKeys = keys;
        loading = false;
      });
      _log('Las preguntas se cargaron correctamente.');
    } catch (e) {
      _log('Error al cargar preguntas: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  void selectOption(int option) {
    setState(() {
      selectedOption = option;
    });
  }

  void goToNextQuestion() {
    final selected = selectedOption;
    if (selected == null) return;
    if (currentKeyIndex + 1 >= usedKeys.length) return;

    selectedAnswerByKey[usedKeys[currentKeyIndex]] = selected;
    final next = currentKeyIndex + 1;
    setState(() {
      currentKeyIndex = next;
      // Si el usuario ya había respondido la siguiente, se restaura
      selectedOption = selectedAnswerByKey[usedKeys[next]];
    });
  }

  void goToPreviousQuestion() {
    if (currentKeyIndex > 0) {
      setState(() {
        currentKeyIndex--;
        selectedOption = selectedAnswerByKey[usedKeys[currentKeyIndex]];
      });
    }
  }

  Future<void> saveResponses() async {
    userId ??= await getUserId();
    final token = await getToken();

    final id = userId;
    final ageRangeId = selectedAnswerByKey[_QuestionKey.ageRange];
    final genderId = selectedAnswerByKey[_QuestionKey.gender];
    final responsabilityLevelId =
        selectedAnswerByKey[_QuestionKey.responsabilityLevel];

    if (id == null ||
        ageRangeId == null ||
        genderId == null ||
        responsabilityLevelId == null) {
      _showSnack('Faltan respuestas por completar.');
      return;
    }

    final Map<String, int?> dataToSend = {
      'userId': id,
      'age_range_id': ageRangeId,
      'gender_id': genderId,
      'responsability_level_id': responsabilityLevelId,
      'hierarchical_level_id': _isGeneralUser
          ? _generalHierarchicalLevelId
          : selectedAnswerByKey[_QuestionKey.hierarchicalLevel],
      'branch_id': _isGeneralUser
          ? _generalBranchId
          : selectedAnswerByKey[_QuestionKey.branch],
    };
    _log('Data to send: $dataToSend');

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl2}/users/save-responses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('userresponsebool', true);

        // Guardar branch_id en SharedPreferences para uso posterior
        final branchId = _isGeneralUser
            ? _generalBranchId
            : selectedAnswerByKey[_QuestionKey.branch];
        if (branchId != null) {
          await prefs.setInt('branch_id', branchId);
          _log('branch_id guardado en SharedPreferences: $branchId');
        }

        if (!mounted) return;
        _showSnack('Respuestas guardadas exitosamente.');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TestEstresScreen(),
          ),
        );
      } else {
        _showSnack('Error al guardar respuestas.');
      }
    } catch (e) {
      _log('Error al enviar respuestas: $e');
      _showSnack('Error al enviar respuestas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading) {
      content = const Center(
        child: CircularProgressIndicator(color: _FnlColors.violet),
      );
    } else if (!agreedToTerms) {
      content = _buildWelcomeScreen();
    } else if (usedKeys.isEmpty) {
      content = _buildLoadError();
    } else {
      content = _buildQuestionsScreen();
    }

    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: _FnlBackground(child: content),
    );
  }

  // ── Error de carga con reintento ─────────────────────────────
  Widget _buildLoadError() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_FnlSpace.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _MascotHalo(url: _thinkingUrl, size: 120),
                const SizedBox(height: _FnlSpace.sm),
                Text(
                  'No pudimos cargar tus preguntas',
                  textAlign: TextAlign.center,
                  style: _FnlText.h2(22),
                ),
                const SizedBox(height: _FnlSpace.xs),
                Text(
                  'Revisa tu conexión e inténtalo de nuevo.',
                  textAlign: TextAlign.center,
                  style: _FnlText.body(),
                ),
                const SizedBox(height: _FnlSpace.md),
                _PrimaryButton(
                  label: 'Reintentar',
                  icon: Icons.refresh_rounded,
                  onTap: _retryLoad,
                ),
              ],
            ),
          ),
        ),
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
                              currentKeyIndex = 0;
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
    final keyIndex = currentKeyIndex < 0
        ? 0
        : currentKeyIndex >= usedKeys.length
            ? usedKeys.length - 1
            : currentKeyIndex;
    final currentKey = usedKeys[keyIndex];
    final questionText = questionByKey[currentKey] ?? '';
    final options = answersByKey[currentKey] ?? const <_QuestionAnswer>[];
    final bool isLoadingOptions =
        currentKey == _QuestionKey.hierarchicalLevel && _loadingLevels;

    final bool isNextEnabled = selectedOption != null;
    final bool isLast = keyIndex >= usedKeys.length - 1;

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
                          if (isLoadingOptions)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _FnlColors.violet,
                                ),
                              ),
                            )
                          else if (options.isEmpty)
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
    final selected = selectedOption;
    if (selected == null) return;

    if (currentKeyIndex + 1 < usedKeys.length) {
      goToNextQuestion();
      return;
    }

    // Última pregunta: guardar la respuesta y pasar al resumen
    selectedAnswerByKey[usedKeys[currentKeyIndex]] = selected;
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

  Widget _buildOption(_QuestionAnswer answer) {
    final isSelected = selectedOption == answer.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _OptionTile(
        label: answer.label,
        selected: isSelected,
        onTap: () => _onOptionSelected(answer),
      ),
    );
  }

  void _onOptionSelected(_QuestionAnswer answer) {
    setState(() {
      selectedOption = answer.value;
    });

    if (usedKeys[currentKeyIndex] == _QuestionKey.area) {
      _onAreaSelected(answer.value);
    }
  }

  void _onAreaSelected(int areaId) {
    // Si cambió el área, la posición elegida antes ya no es válida
    final previousArea = selectedAnswerByKey[_QuestionKey.area];
    if (previousArea != null && previousArea != areaId) {
      selectedAnswerByKey.remove(_QuestionKey.hierarchicalLevel);
    }

    // Evita pedir de nuevo los mismos niveles si ya están cargados
    final alreadyLoaded = _levelsAreaId == areaId &&
        (answersByKey[_QuestionKey.hierarchicalLevel]?.isNotEmpty ?? false);
    if (!alreadyLoaded) {
      fetchHierarchicalLevel(areaId);
    }
  }

  // Header: retroceso + contador + barra de progreso
  Widget _buildQuestionHeader(double hPad, double maxContentWidth) {
    final total = usedKeys.length;
    final progress = (currentKeyIndex + 1) / total;

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
                    child: currentKeyIndex > 0
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
                        'Pregunta ${currentKeyIndex + 1} de $total',
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
            excludeFromSemantics: true,
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: _FnlSpace.sm, vertical: 14),
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

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
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

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Container(
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
      ),
    );
  }
}