import 'package:flutter/material.dart';
import 'package:fnlapp/Login/login.dart';
import 'package:fnlapp/Main/profile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fnlapp/Funcy/screens/splash_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Util/token_service.dart';
import './models/profile_data.dart';
import '../config.dart';
import '../Main/widgets/custom_navigation_bar.dart';
import 'plan.dart';
import './widgets/chat_widget.dart';
import 'mitest.dart';
import './ExitTest/exit_test_screen.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:fnlapp/Main/testestres_form.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NivelEstres nivelEstres = NivelEstres.desconocido;
  List<dynamic> programas = [];
  bool isLoading = true;
  int _selectedIndex = 0;
  bool isChatOpen = false;
  bool showExitTest = false;
  bool showWidgets = false;
  int? userId;
  String? username;
  int? funcyInteract;
  ProfileData? profileData;
  bool hasFilledEmotion = false;
  String? token;
  bool isExitTestEnabled = false;

  @override
  void initState() {
    super.initState();
    // Cargamos todos los datos necesarios al iniciar la pantalla
    _loadInitialData();
  }

  // --- NUEVA FUNCIÓN PARA CENTRALIZAR LA CARGA DE DATOS ---
  Future<void> _loadInitialData() async {
    // Primero, obtenemos los datos del usuario de SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    username = prefs.getString('username');
    token = prefs.getString('token');

    // Si no tenemos los datos básicos, no podemos continuar.
    if (userId == null || token == null) {
      print('Error crítico: userId o token no encontrados al iniciar HomeScreen.');
      // Opcional: podrías redirigir al login aquí si esto ocurre.
      // _handleLogout();
      return;
    }

    // Ahora que tenemos los datos, ejecutamos las llamadas a la API en paralelo
    await Future.wait([
      _checkExitTest(),
      obtenerNivelEstresYProgramas(),
      loadProfile(),
      checkIfEmotionFilledForToday(),
    ]);

    // Actualizamos el estado para reflejar que la carga ha terminado
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkExitTest() async {
    // Ya no necesitamos leer de SharedPreferences aquí, usamos las variables de la clase
    if (userId == null || token == null) {
      print('Error en _checkExitTest: Faltan datos de usuario.');
      setState(() => isExitTestEnabled = false);
      return;
    }
    // ... (el resto de tu lógica de _checkExitTest sigue igual)
    try {
      final response1 = await http.get(
        Uri.parse('${Config.apiUrl}/getUserTestEstresSalida/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response1.statusCode == 404) {
        final response = await http.get(
          Uri.parse('${Config.apiUrl}/userprograma/$userId/actividad/21'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final String? completedDateStr = data['completed_date'];
          if (completedDateStr != null) {
            final DateTime completedDate = DateTime.parse(completedDateStr);
            final DateTime today = DateTime.now();
            final bool showTest = today.isAfter(completedDate) || _isSameDay(today, completedDate);
            setState(() {
              showExitTest = showTest;
              isExitTestEnabled = showTest;
            });
            print(showTest ? 'Test de salida habilitado.' : 'Test de salida deshabilitado.');
          } else {
            print('El día 21 aún no ha sido completado.');
            setState(() => isExitTestEnabled = false);
          }
        } else {
          setState(() => isExitTestEnabled = false);
        }
      } else {
        setState(() => isExitTestEnabled = false);
      }
    } catch (e) {
      print('Error al verificar el programa: $e');
      setState(() => isExitTestEnabled = false);
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> loadProfile() async {
    profileData = await fetchProfile();
    if (mounted) {
      setState(() {});
    }
  }

  // --- FUNCIÓN fetchProfile CORREGIDA ---
  Future<ProfileData?> fetchProfile() async {
    // Ya no necesitamos leer de SharedPreferences, usamos las variables de la clase.
    // La verificación principal ya se hizo en _loadInitialData.
    if (userId == null || token == null) {
      print('Error en fetchProfile: Faltan datos de usuario.');
      return null;
    }

    try {
      String url = '${Config.apiUrl2}/users/getprofile/$userId';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        var profile = ProfileData.fromJson(json.decode(response.body));
        // Esta llamada anidada puede ser un punto de mejora en el futuro.
        var res = await http.get(Uri.parse('${Config.apiUrl}/empresa/${profile.idEmpresa}'));
        profile.nombreEmpresa = json.decode(res.body)['nombre'];
        return profile;
      } else {
        print('Error fetching profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      isChatOpen = index == 1;
      if (index == 4 && showExitTest) {
        showWidgets = true;
      }
    });
  }

  // --- FUNCIÓN PARA ACTUALIZAR LA IMAGEN DE PERFIL ---
  void _updateProfileImage(String newImageUrl) {
    if (profileData != null) {
      setState(() {
        profileData!.profileImage = newImageUrl;
      });
      print('Imagen de perfil actualizada en HomeScreen: $newImageUrl');
    }
  }

  Widget _getSelectedWidget() {
    final String? nameSource = profileData?.nombres;
    final String userName = nameSource?.split(' ').first ?? 'Usuario';

    final List<dynamic> modifiedProgramas = programas.map((programa) {
      final newPrograma = Map<String, dynamic>.from(programa);
      if (newPrograma['descripcion'] != null && newPrograma['descripcion'] is String) {
        newPrograma['descripcion'] = newPrograma['descripcion'].replaceAll('USER', userName);
      }
      return newPrograma;
    }).toList();

    switch (_selectedIndex) {
      case 0:
        return PlanScreen(
          nivelEstres: nivelEstres,
          isLoading: isLoading,
          programas: modifiedProgramas,
        );
      case 1:
        return ChatWidget(
          userId: userId ?? 1,
          username: username ?? 'Usuario',
          onChatToggle: (isOpen) => setState(() => isChatOpen = isOpen),
        );
      case 2:
        return MiTestScreen(nivelEstres: nivelEstres);
      case 3:
        return ProfileScreen(
          profileData: profileData,
          onLogout: _handleLogout,
          onProfileImageUpdated: _updateProfileImage,
        );
      case 4:
        if (showExitTest) {
          return TestEstresQuestionScreen();
        }
        return PlanScreen(
          nivelEstres: nivelEstres,
          isLoading: isLoading,
          programas: programas,
        );
      default:
        return PlanScreen(
          nivelEstres: nivelEstres,
          isLoading: isLoading,
          programas: programas,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5027D0),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
          : Stack(
        children: [
          Positioned.fill(child: _getSelectedWidget()),
          if (!showWidgets)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomNavigationBar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
                showExitTest: showExitTest,
                isExitTestEnabled: isExitTestEnabled,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Usar logout con invalidación de tokens en servidor
    await TokenService.instance.logout(logoutAll: false);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  // --- FUNCIÓN obtenerNivelEstresYProgramas CORREGIDA ---
  Future<void> obtenerNivelEstresYProgramas() async {
    // La verificación principal ya se hizo en _loadInitialData.
    if (userId == null || token == null) {
      print('Error en obtenerNivelEstresYProgramas: Faltan datos de usuario.');
      return;
    }

    try {
      final responseNivel = await http.get(
        Uri.parse('${Config.apiUrl}/userestresessions/$userId/nivel'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (responseNivel.statusCode == 200) {
        final responseData = jsonDecode(responseNivel.body);
        int estresNivelId = responseData['estres_nivel_id'];
        if (mounted) setState(() => nivelEstres = _mapNivelEstres(estresNivelId));
      }

      final responseProgramas = await http.post(
        Uri.parse('${Config.apiUrl}/userprograma/getprogramcompleto/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'user_id': userId}),
      );

      if (responseProgramas.statusCode == 200) {
        final responseData = jsonDecode(responseProgramas.body);
        if (mounted) setState(() => programas = responseData['userProgramas']);
      }
    } catch (e) {
      print('Error obteniendo nivel de estrés o programas: $e');
    }
  }

  NivelEstres _mapNivelEstres(int nivelId) {
    switch (nivelId) {
      case 1: return NivelEstres.leve;
      case 2: return NivelEstres.moderado;
      case 3: return NivelEstres.severo;
      default: return NivelEstres.desconocido;
    }
  }

  Future<void> checkIfEmotionFilledForToday() async {
    if (userId == null || token == null) return;
    try {
      String fechaHoy = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/emociones_diarias/$fechaHoy'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (mounted) setState(() => hasFilledEmotion = data['data'].isNotEmpty);
      }
    } catch (e) {
      print('Error al verificar las emociones de hoy: $e');
    }
  }

  // ... (El resto de tus funciones como _showEmotionModal y _registerEmotion permanecen igual)
  void _showEmotionModal() {
    showDialog(
      context: context,
      builder: (context) {
        return EmotionModal(
          onEmotionRegistered: (emotion, note) {
            setState(() {
              hasFilledEmotion = true;
            });
            _registerEmotion(emotion, note);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _registerEmotion(int emotion, String note) async {
    if (userId == null || token == null) return;
    try {
      String fechaHoy = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/emociones_diarias'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'emocion': emotion,
          'notaOpcional': note,
        }),
      );
      if (response.statusCode == 201) {
        print('Emotion registered successfully');
      } else {
        print('Failed to register emotion');
      }
    } catch (e) {
      print('Error registering emotion: $e');
    }
  }
}

// ... (La clase EmotionModal permanece igual)
class EmotionModal extends StatefulWidget {
  final Function(int emotion, String note) onEmotionRegistered;
  EmotionModal({required this.onEmotionRegistered});
  @override
  _EmotionModalState createState() => _EmotionModalState();
}
class _EmotionModalState extends State<EmotionModal> {
  TextEditingController noteController = TextEditingController();
  int selectedEmotion = 0;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Emotion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => selectedEmotion = 1),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedEmotion == 1 ? Colors.grey.shade300 : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sentiment_very_satisfied, color: Colors.green, size: 40),
                ),
              ),
              SizedBox(width: 20),
              GestureDetector(
                onTap: () => setState(() => selectedEmotion = 0),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedEmotion == 0 ? Colors.grey.shade300 : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sentiment_neutral, color: Colors.grey, size: 40),
                ),
              ),
              SizedBox(width: 20),
              GestureDetector(
                onTap: () => setState(() => selectedEmotion = -1),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedEmotion == -1 ? Colors.grey.shade300 : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sentiment_dissatisfied, color: Colors.red, size: 40),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextField(
            controller: noteController,
            decoration: InputDecoration(hintText: 'Optional note'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onEmotionRegistered(selectedEmotion, noteController.text),
          child: Text('Save'),
        ),
      ],
    );
  }
}
