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
import '../theme/app_colors.dart';
import '../theme/funcy.dart';
import '../widgets/app_buttons.dart';
import '../widgets/state_views.dart';

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
    userId = await getUserId();
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

  static const _questionTitles = [
    '¿Cuál es tu rango de edad?',
    '¿Cuál es tu género?',
    '¿En qué área trabajas?',
    '¿Cuál es tu posición en la organización?',
    '¿Cuál es tu nivel de responsabilidad?',
    '¿A qué sede perteneces?',
  ];

  static const _questionKeys = ['age_range', 'gender', 'area', 'level', 'responsability_level', 'sede'];

  late final TapGestureRecognizer _privacyTap1 = TapGestureRecognizer()..onTap = _openPrivacy;
  late final TapGestureRecognizer _privacyTap2 = TapGestureRecognizer()..onTap = _openPrivacy;
  late final TapGestureRecognizer _privacyTap3 = TapGestureRecognizer()..onTap = _openPrivacy;
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => CondicionesUsoScreen()));

  void _openPrivacy() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => PoliticaPrivacidadScreen()));

  @override
  void dispose() {
    _privacyTap1.dispose();
    _privacyTap2.dispose();
    _privacyTap3.dispose();
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: loading
                ? _buildLoading()
                : agreedToTerms
                    ? _buildQuestionsScreen()
                    : _buildWelcomeScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FuncyImage(FuncyPose.pensativo, size: 150, flipped: true),
          SizedBox(height: 16),
          Text('Preparando tus preguntas…', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
          SizedBox(height: 16),
          SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final textTheme = Theme.of(context).textTheme;
    const linkStyle = TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.w700, decoration: TextDecoration.underline);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const FuncyImage(FuncyPose.seguro, size: 160),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tu privacidad nos importa', style: textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Antes de empezar, revisa y acepta cómo cuidamos tu información.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildCheckboxRow(
                  isChecked: acceptedProcessing,
                  textSpans: [
                    const TextSpan(text: 'Acepto la '),
                    TextSpan(text: 'Política de privacidad', style: linkStyle, recognizer: _privacyTap1),
                    const TextSpan(text: ' y las '),
                    TextSpan(text: 'Condiciones de uso', style: linkStyle, recognizer: _termsTap),
                    const TextSpan(text: '.'),
                  ],
                  onChanged: () {
                    setState(() => acceptedProcessing = !acceptedProcessing);
                    _updateAgreedToAll();
                  },
                ),
                const SizedBox(height: 10),
                _buildCheckboxRow(
                  isChecked: acceptedProcessing1,
                  textSpans: [
                    const TextSpan(
                        text:
                            'Acepto el procesamiento de mis datos personales de salud para que la aplicación pueda funcionar. Ver más en la '),
                    TextSpan(text: 'Política de privacidad', style: linkStyle, recognizer: _privacyTap2),
                    const TextSpan(text: '.'),
                  ],
                  onChanged: () {
                    setState(() => acceptedProcessing1 = !acceptedProcessing1);
                    _updateAgreedToAll();
                  },
                ),
                const SizedBox(height: 10),
                _buildCheckboxRow(
                  isChecked: acceptedTracking,
                  textSpans: [
                    const TextSpan(
                        text:
                            'Autorizo a la empresa a recopilar y usar información sobre mi actividad en la aplicación y los datos necesarios para evaluar mi nivel de estrés y bienestar laboral, según la '),
                    TextSpan(text: 'Política de privacidad', style: linkStyle, recognizer: _privacyTap3),
                    const TextSpan(text: '.'),
                  ],
                  onChanged: () {
                    setState(() => acceptedTracking = !acceptedTracking);
                    _updateAgreedToAll();
                  },
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
          child: Column(
            children: [
              if (!agreedToAll)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        acceptedProcessing = true;
                        acceptedProcessing1 = true;
                        acceptedTracking = true;
                      });
                      _updateAgreedToAll();
                    },
                    child: const Text('Aceptar todo'),
                  ),
                ),
              if (!agreedToAll) const SizedBox(height: 10),
              AppPrimaryButton(
                label: 'Continuar',
                onPressed: agreedToAll
                    ? () {
                        _handleAcceptAll();
                        setState(() {
                          agreedToTerms = true;
                          currentQuestionIndex = 0;
                        });
                      }
                    : null,
              ),
              if (!agreedToAll)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Acepta las tres opciones para continuar.',
                      style: TextStyle(fontSize: 12, color: AppColors.inkTertiary)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow({
    required bool isChecked,
    required List<TextSpan> textSpans,
    required VoidCallback onChanged,
  }) {
    return Material(
      color: isChecked ? AppColors.selected : AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onChanged,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: isChecked, onChanged: (_) => onChanged()),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      children: textSpans,
                      style: const TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.ink),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsScreen() {
    final textTheme = Theme.of(context).textTheme;
    final index = currentQuestionIndex.clamp(0, _questionKeys.length - 1);
    final options = questionCategories[_questionKeys[index]] ?? [];
    final isNextEnabled = selectedOption != null || selectedAnswers.containsKey(currentQuestionIndex);
    final isLast = currentQuestionIndex >= _questionKeys.length - 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 20, 0),
          child: Row(
            children: [
              if (currentQuestionIndex > 0)
                IconButton(
                  tooltip: 'Pregunta anterior',
                  onPressed: goToPreviousQuestion,
                  style: IconButton.styleFrom(backgroundColor: AppColors.muted, minimumSize: const Size(44, 44)),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
                )
              else
                const SizedBox(width: 44),
              const SizedBox(width: 12),
              Expanded(
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < _questionKeys.length; i++) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 6,
                            decoration: BoxDecoration(
                              color: i <= currentQuestionIndex ? AppColors.primary : const Color(0xFFE6E2F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${index + 1} de ${_questionKeys.length}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSecondary)),
            ],
          ),
        ),
        Expanded(
          child: options.isEmpty
              ? Center(
                  child: ErrorStateView(
                    title: 'No pudimos cargar las opciones',
                    message: 'Revisa tu conexión a internet e inténtalo de nuevo.',
                    onRetry: () {
                      setState(() => loading = true);
                      fetchData();
                    },
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(index < 2 ? 'Sobre ti' : 'Sobre tu trabajo',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              const SizedBox(height: 6),
                              Semantics(
                                header: true,
                                child: Text(_questionTitles[index], style: textTheme.headlineSmall),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const FuncyImage(FuncyPose.pensativo, size: 96, flipped: true),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 18, color: AppColors.success),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tus respuestas son confidenciales y solo sirven para personalizar tu plan.',
                            style: TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.inkSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildQuestionField(options),
                  ],
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
          child: Column(
            children: [
              AppPrimaryButton(
                label: isLast ? 'Continuar' : 'Siguiente',
                onPressed: isNextEnabled
                    ? () {
                        if (!isLast) {
                          goToNextQuestion();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IndexSummaryScreen(
                                onFinalize: saveResponses,
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                isNextEnabled ? 'Puedes volver atrás para cambiar tu respuesta.' : 'Elige una opción para continuar.',
                style: const TextStyle(fontSize: 12, color: AppColors.inkTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionField(List<Map<String, dynamic>> questions) {
    return Semantics(
      container: true,
      child: Column(
        children: [
          for (final question in questions) ...[
            _OptionCard(
              label: _getOptionText(question),
              selected: selectedOption == question['id'].toString(),
              onTap: () {
                setState(() => selectedOption = question['id'].toString());
                if (currentQuestionIndex == 2) {
                  final areaId = question['id'];
                  if (areaId is int) fetchHierarchicalLevel(areaId);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  void _updateAgreedToAll() {
    setState(() {
      agreedToAll = acceptedProcessing && acceptedTracking && acceptedProcessing1;
    });
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 16, height: 22 / 16, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
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
