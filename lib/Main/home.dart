import 'package:flutter/material.dart';
import 'package:fnlapp/Login/login.dart';
import 'package:fnlapp/Main/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    ]);

    // Actualizamos el estado para reflejar que la carga ha terminado
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkExitTest() async {

        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isDay21Completed = prefs.getBool('isDay21Completed') ?? false;
        
        setState(() {
          showExitTest = isDay21Completed;
          isExitTestEnabled = isDay21Completed;
        });
        
  }


  Future<void> loadProfile() async {
    profileData = await fetchProfile();
    if (mounted) {
      setState(() {});
    }
  }

  // --- FUNCIÓN fetchProfile MODIFICADA PARA OBTENER EL NIVEL DE ESTRÉS ---
  Future<ProfileData?> fetchProfile() async {
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
        var profileJson = json.decode(response.body);
        var profile = ProfileData.fromJson(profileJson);

        // NUEVO: Obtener el nivel de estrés del perfil (viene como string)
        String? estresLevelString = profileJson['estresLevel'];
        if (estresLevelString != null && mounted) {
          setState(() {
            nivelEstres = _mapNivelEstresFromString(estresLevelString);
          });
          print('Nivel de estrés obtenido del perfil: $nivelEstres (String: $estresLevelString)');
        }

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
  void _updateProfileImage(String newImageUrl) async {
    print('Callback recibido en HomeScreen: actualizando imagen a $newImageUrl');

    imageCache.clear();
    imageCache.clearLiveImages();
  
    await loadProfile();

    if (mounted) {
      setState(() {
      });
      print('ProfileData actualizado en HomeScreen después del callback');
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
          showExitTestModal: isExitTestEnabled,
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

  // --- FUNCIÓN obtenerNivelEstresYProgramas MODIFICADA ---
  Future<void> obtenerNivelEstresYProgramas() async {
    // La verificación principal ya se hizo en _loadInitialData.
    if (userId == null || token == null) {
      print('Error en obtenerNivelEstresYProgramas: Faltan datos de usuario.');
      return;
    }

    try {
      // MODIFICADO: Usar la nueva API para obtener las actividades diarias
      final responseProgramas = await http.get(
        Uri.parse('${Config.apiUrl2}/users/daily-activities?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (responseProgramas.statusCode == 200) {
        final responseData = jsonDecode(responseProgramas.body);
        if (mounted) {
          setState(() {
            programas = responseData['userProgramas'] ?? [];
          });
          print('Programas cargados: ${programas.length}');
        }
      } else {
        print('Error al obtener programas: ${responseProgramas.statusCode}');
        if (mounted) {
          setState(() {
            programas = [];
          });
        }
      }
    } catch (e) {
      print('Error obteniendo programas: $e');
      if (mounted) {
        setState(() {
          programas = [];
        });
      }
    }
  }


  // NUEVA FUNCIÓN para mapear strings a NivelEstres
  NivelEstres _mapNivelEstresFromString(String nivelString) {
    switch (nivelString.toUpperCase()) {
      case 'LEVE': return NivelEstres.leve;
      case 'MODERADO': return NivelEstres.moderado;
      case 'ALTO': return NivelEstres.severo;
      case 'SEVERO': return NivelEstres.severo;
      default: return NivelEstres.desconocido;
    }
  }
}

