import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
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
import 'package:fnlapp/Main/certificate_screen.dart';

class _FnlColors {
  static const blue = Color(0xFF0B1457); // Azul FNL (H1 / H2)
  static const violet = Color(0xFF6428E8); // Violeta principal
  static const violetSecondary = Color(0xFF814CF4); // Violeta secundario
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
  static const double xl = 40;
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

class TestEstresQuestionScreen extends StatefulWidget {
  const TestEstresQuestionScreen({Key? key}) : super(key: key);

  @override
  _TestEstresQuestionScreenState createState() =>
      _TestEstresQuestionScreenState();
}

class _TestEstresQuestionScreenState extends State<TestEstresQuestionScreen> {
  static const String _mascotUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/meditating.png';
  static const String _funcyUrl =
      'https://fnls3app-896680309156-us-east-2-an.s3.us-east-2.amazonaws.com/funcy/funcy.png';

  bool isSubmitting = false;
  int currentQuestionIndex = 0;
  List<int> selectedOptions = List<int>.filled(23, 0);
  int? userId;
  bool? isDay21Completed;
  bool showingNotice = false;
  TestNotice? currentNotice;
  int? previousNoticeIndex;
  bool _imagesPrecached = false;


  bool _testSaved = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      _precacheNoticeImages();
      _imagesPrecached = true;
    }
  }

  void _precacheNoticeImages() {
    for (var notice in testNotices) {
      if (notice.imagePath != null && notice.imagePath!.isNotEmpty) {
        precacheImage(NetworkImage(notice.imagePath!), context);
      }
    }
    precacheImage(const NetworkImage(_funcyUrl), context);
  }

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

  Future<bool> _isCompany8User() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      int? branchId = prefs.getInt('branch_id');
      int? companyId = prefs.getInt('company_id');

      print(
          'DEBUG: SharedPreferences - company_id = $companyId, branch_id = $branchId');

      List<int> company8BranchIds = [9];

      if (companyId == 8 ||
          (branchId != null && company8BranchIds.contains(branchId))) {
        print(
            'DEBUG: Usuario identificado como company 8 desde SharedPreferences');
        return true;
      }

      Map<String, dynamic>? userProfile = await _getUserProfile();
      if (userProfile != null) {
        String? companyName = userProfile['companyName'];
        print('DEBUG: companyName desde perfil = $companyName');

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

  void selectOption(int optionId) {
    setState(() {
      selectedOptions[currentQuestionIndex] = optionId;
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
    });
  }

  Future<void> submitTest() async {
    if (isSubmitting) {
      print("Test ya está siendo enviado");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Por favor espera, el test se está procesando...')),
      );
      return;
    }

    if (isDay21Completed == true) {
      await _processTestSubmission();
    } else {
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
      setState(() {
        isSubmitting = true;
      });

      if (userId == null) {
        print("Error: userId es null");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se ha cargado el ID del usuario')),
        );
        return;
      }

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

      int totalScore = selectedOptions.fold(0, (sum, value) => sum + value);

      Map<String, dynamic>? userProfile = await _getUserProfile();
      if (userProfile == null) {
        print('Error: No se pudo obtener el perfil del usuario');
        return;
      }

      int genderId =
          _getGenderIdFromProfile(userProfile['gender'] ?? 'Masculino');

      final Map<String, dynamic> estresResult =
          _calcularNivelEstres(totalScore, genderId);
      NivelEstres nivelEstres = estresResult['nivel'];
      int estresNivelId = estresResult['id'];

      String testType = (isDay21Completed == true) ? 'exit' : 'entry';

      // Solo se guarda una vez: si el usuario tocó "Ahora no" en el pop-up de
      // suscripción y vuelve a pulsar "Finalizar", no se duplica el test.
      if (!_testSaved) {
        List<Map<String, dynamic>> testData = [];
        for (int i = 0; i < selectedOptions.length; i++) {
          testData.add({
            'user_id': userId,
            'question_id': i + 1,
            'score': selectedOptions[i],
            'test_type': testType,
          });
        }

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

        _testSaved = true;
        print('Test guardado correctamente con tipo: $testType');
      }

      if (testType == 'exit') {
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
        await prefs.setBool('isDay21Completed', false);
        await prefs.setBool('hasCompletedExitTest', true);

        print("Test de salida completado, navegando a CertificateScreen.");

        String userName = userProfile['fullName'] ??
            userProfile['name'] ??
            '${userProfile['names'] ?? 'Usuario'} ${userProfile['lastnames'] ?? ''}';

        String completionDate = _formatDate(DateTime.now());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CertificateScreen(
              username: userName.trim(),
              completionDate: completionDate,
              programName: 'Programa de Manejo de Estrés Laboral - 21 Días',
            ),
          ),
        );

        return;
      } else {
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

        bool isCompany8 = await _isCompany8User();

        print('========== SUBSCRIPTION DEBUG ==========');
        print('isCompany8 = $isCompany8');

        final hasAccess = await SubscriptionService.hasAccessToPrograms();

        print('hasAccessToPrograms = $hasAccess');
        print('========================================');

        if (isCompany8) {
          if (!hasAccess) {
            final shouldNavigate = await _showSubscriptionDialog();
            if (!mounted) return;

            if (shouldNavigate != true) {
              return;
            }

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionScreen(showBackButton: false),
              ),
            );
            if (!mounted) return;

            if (result == true) {
              await _generateProgram(userProfile, totalScore);
              await _updateTestEstresBool();

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CargarProgramaScreen(nivelEstres: nivelEstres),
                ),
              );
            }
            return;
          } else {
            await _generateProgram(userProfile, totalScore);
            await _updateTestEstresBool();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CargarProgramaScreen(nivelEstres: nivelEstres),
              ),
            );
          }
        } else {
          print('========================================');
          print('POSIBLE BYPASS DE SUSCRIPCIÓN');
          print('_isCompany8User() devolvió FALSE');
          print('Se generará el programa SIN verificar suscripción');
          print('========================================');
          await _generateProgram(userProfile, totalScore);
          await _updateTestEstresBool();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CargarProgramaScreen(nivelEstres: nivelEstres),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al procesar el test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el test')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }


  Future<bool?> _showSubscriptionDialog() {
    const double mascotSize = 140; 
    const double mascotOverlap = 70; 

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      // Scrim azul FNL en vez del negro genérico
      barrierColor: _FnlColors.blue.withOpacity(0.55),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: _FnlSpace.md,
            vertical: _FnlSpace.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Opacity(
                  opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
                  child: Transform.scale(scale: scale, child: child),
                ),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: mascotOverlap),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          _FnlSpace.md,
                          mascotSize - mascotOverlap + _FnlSpace.xs,
                          _FnlSpace.md,
                          _FnlSpace.sm,
                        ),
                        decoration: BoxDecoration(
                          color: _FnlColors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: _FnlColors.bubbleBorder, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: _FnlColors.bubbleBorder,
                              offset: Offset(0, 6),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Píldora PRO
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _FnlColors.lavender,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                    color: _FnlColors.bubbleBorder, width: 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium_rounded,
                                      size: 18, color: _FnlColors.violet),
                                  const SizedBox(width: 6),
                                  Text('Funcy PRO',
                                      style: _FnlText.label(
                                          color: _FnlColors.violet)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tu programa personalizado te espera',
                              textAlign: TextAlign.center,
                              style: _FnlText.h2(22),
                            ),
                            const SizedBox(height: _FnlSpace.xs),
                            Text(
                              'Para obtener tu programa personalizado de 30 días, debes suscribirte a Funcy PRO.',
                              textAlign: TextAlign.center,
                              style: _FnlText.body(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '¿Deseas suscribirte ahora?',
                              textAlign: TextAlign.center,
                              style: _FnlText.label(color: _FnlColors.violet)
                                  .copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: _FnlSpace.md),
                            _GradientButton(
                              label: 'Suscribirme',
                              icon: Icons.arrow_forward_rounded,
                              onTap: () =>
                                  Navigator.of(dialogContext).pop(true),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                foregroundColor: _FnlColors.label,
                              ),
                              child:
                                  Text('Ahora no', style: _FnlText.label()),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: mascotSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: mascotSize * 0.7,
                            height: mascotSize * 0.7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _FnlColors.violetSecondary
                                      .withOpacity(0.35),
                                  blurRadius: 40,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          Image.network(
                            _funcyUrl,
                            height: mascotSize,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: mascotSize,
                                width: mascotSize,
                                child: Center(
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
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: mascotSize,
                              width: mascotSize,
                            ),
                          ),
                        ],
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
        nivelEstres =
            totalScore <= 132 ? NivelEstres.moderado : NivelEstres.severo;
        estresNivelId = totalScore <= 132 ? 2 : 3;
      }
    } else if (totalScore > 138) {
      if (genderId == 1) {
        nivelEstres = NivelEstres.severo;
        estresNivelId = 3;
      } else if (genderId == 2 || genderId == 3) {
        nivelEstres = NivelEstres.severo;
        estresNivelId = 3;
      }
    }

    return {'nivel': nivelEstres, 'id': estresNivelId};
  }

  Future<void> _generateProgram(
      Map<String, dynamic> userProfile, int totalScore) async {
    try {
      String? token = await getToken();
      if (token == null) {
        print('Error: No se encontró el token para generar programa.');
        return;
      }

      String resumenRespuestas = _createResponseSummary(totalScore);

      DateTime now = DateTime.now();
      String startDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

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

  String _createResponseSummary(int totalScore) {
    if (totalScore <= 92) {
      return 'Usuario presenta niveles bajos de estrés. Respuestas indican manejo adecuado de situaciones cotidianas.';
    } else if (totalScore <= 138) {
      return 'Usuario presenta niveles moderados de estrés. Se observan algunas dificultades en el manejo de situaciones laborales.';
    } else {
      return 'Usuario presenta niveles altos de estrés. Respuestas indican dificultades significativas en el manejo de presión y situaciones laborales.';
    }
  }

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

    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return Scaffold(
        backgroundColor: _FnlColors.canvas,
        body: Center(
          child: Text('No hay preguntas disponibles', style: _FnlText.body()),
        ),
      );
    }

    final question = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: _FnlColors.canvas,
      body: Stack(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final hPad = isTablet ? _FnlSpace.lg : _FnlSpace.md;
              final maxContentWidth = isTablet ? 720.0 : double.infinity;

              return Column(
                children: [
                  _buildHeader(context, hPad, maxContentWidth),
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
                              _buildQuestionCard(question, isTablet),
                              const SizedBox(height: _FnlSpace.md),
                              ..._buildOptions(question),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomBar(context, hPad, maxContentWidth),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, double hPad, double maxContentWidth) {
    final total = questions.length;
    final progress = (currentQuestionIndex + 1) / total;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        MediaQuery.of(context).padding.top + _FnlSpace.sm,
        hPad,
        _FnlSpace.xs,
      ),
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
                            elevation: 0,
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
                        'Pregunta ${currentQuestionIndex + 1} de $total',
                        style: _FnlText.label(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: _FnlSpace.sm),
              Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, bool isTablet) {
    final mascotSize = isTablet ? 140.0 : 108.0;

    return Column(
      children: [
        // Mascota con halo suave
        SizedBox(
          height: mascotSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: mascotSize * 0.8,
                height: mascotSize * 0.8,
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
                _mascotUrl,
                height: mascotSize,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: mascotSize,
                    width: mascotSize,
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
                errorBuilder: (_, __, ___) => SizedBox(
                  height: mascotSize,
                  width: mascotSize,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _FnlSpace.xs),
        // Globo de diálogo con colita apuntando a Funcy
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                    _FnlSpace.md, _FnlSpace.md, _FnlSpace.md, _FnlSpace.md),
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
                child: Column(
                  children: [
                    if (question['question'] != null)
                      Text(
                        question['question']!,
                        textAlign: TextAlign.center,
                        style: _FnlText.h2(isTablet ? 24 : 20),
                      ),
                    if (question['description'] != null) ...[
                      const SizedBox(height: _FnlSpace.xs),
                      Text(
                        question['description']!,
                        textAlign: TextAlign.center,
                        style: _FnlText.body(),
                      ),
                    ],
                  ],
                ),
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
                      left:
                          BorderSide(color: _FnlColors.bubbleBorder, width: 2),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildOptions(Map<String, dynamic> question) {
    final widgets = <Widget>[];

    for (int index = 0; index < 8; index++) {
      final optionText = question['option${index + 1}'];
      final optionDetail = question['detail${index + 1}'];
      if (optionText == null || optionDetail == null) continue;

      final isSelected = selectedOptions[currentQuestionIndex] == (index + 1);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => selectOption(index + 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: _FnlSpace.sm, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? _FnlColors.lavender : _FnlColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 2,
                  color: isSelected ? _FnlColors.violet : _FnlColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? _FnlColors.violet.withOpacity(0.35)
                        : _FnlColors.border,
                    offset: Offset(0, isSelected ? 2 : 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _SelectionDot(selected: isSelected),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
                          style: _FnlText.option(selected: isSelected),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(
                                top: _FnlSpace.xs, left: 36),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Detalle: ',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _FnlColors.violet,
                                    ),
                                  ),
                                  TextSpan(
                                    text: optionDetail,
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: _FnlColors.body,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildBottomBar(
      BuildContext context, double hPad, double maxContentWidth) {
    final bool isNextEnabled = selectedOptions[currentQuestionIndex] != 0;
    final bool isLast = currentQuestionIndex >= questions.length - 1;
    final String nextLabel = isLast ? 'Continuar' : 'Siguiente';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPad,
        _FnlSpace.sm,
        hPad,
        MediaQuery.of(context).padding.bottom + _FnlSpace.md,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: _GradientButton(
            label: nextLabel,
            icon: Icons.arrow_forward_rounded,
            loading: isSubmitting,
            enabled: isNextEnabled && !isSubmitting,
            onTap: () {
              if (!isLast) {
                goToNextQuestion();
              } else {
                submitTest();
              }
            },
          ),
        ),
      ),
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

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final bool loading;

  const _GradientButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.loading = false,
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
        color: (enabled || loading) ? _FnlColors.violet : _FnlColors.border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_FnlColors.white),
                    ),
                  )
                : Row(
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