import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fnlapp/Main/models/profile_data.dart';
import 'package:fnlapp/Main/profile.dart';
import 'package:fnlapp/Main/testestres_form.dart';
import 'package:fnlapp/Util/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Funcy/screens/chat_screen.dart';
import '../Util/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'mitest.dart';
import 'plan.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  final int initialIndex;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  NivelEstres nivelEstres = NivelEstres.desconocido;
  List<dynamic> programas = [];
  bool isLoading = true;
  bool loadFailed = false;
  late int _selectedIndex = widget.initialIndex;
  late final Set<int> _visitedTabs = {widget.initialIndex};
  int? userId;
  String? username;
  ProfileData? profileData;
  bool isExitTestEnabled = false;
  bool hasCompletedExitTest = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');
    username = prefs.getString('username');
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    if (!silent && mounted) {
      setState(() {
        isLoading = true;
        loadFailed = false;
      });
    }

    isExitTestEnabled = prefs.getBool('isDay21Completed') ?? false;
    hasCompletedExitTest = prefs.getBool('hasCompletedExitTest') ?? false;

    await Future.wait([_loadPrograms(), _loadProfile()]);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> refresh() => _loadInitialData(silent: true);

  Future<void> _loadPrograms() async {
    try {
      final response = await ApiService().get('users/daily-activities?userId=$userId');
      final responseData = jsonDecode(response.body);
      programas = responseData['userProgramas'] ?? [];
      loadFailed = false;
    } on ApiException catch (e) {
      // Sin programa todavía: se muestra "Tu plan se está preparando".
      if (e.statusCode == 404) {
        programas = [];
        loadFailed = false;
      } else {
        debugPrint('Error obteniendo programas: $e');
        loadFailed = true;
      }
    } catch (e) {
      debugPrint('Error obteniendo programas: $e');
      loadFailed = true;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService().get('users/getprofile/$userId');
      final profileJson = json.decode(response.body);
      profileData = ProfileData.fromJson(profileJson);
      final estresLevelString = profileJson['estresLevel'];
      if (estresLevelString is String) {
        nivelEstres = _mapNivelEstresFromString(estresLevelString);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  String get _firstName {
    final source = profileData?.fullName ?? profileData?.nombres;
    final first = source?.trim().split(' ').first ?? '';
    return first.isEmpty ? (username ?? '') : first;
  }

  int get _completedDays => programas.where((p) => p['completed_date'] != null || p['completed'] == true).length;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  Future<void> _startExitTest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TestEstresQuestionScreen()),
    );
    await refresh();
  }

  Future<void> _updateProfileImage(String newImageUrl) async {
    imageCache.clear();
    imageCache.clearLiveImages();
    await _loadProfile();
    if (mounted) setState(() {});
  }

  Widget _buildTab(int index) {
    final firstName = _firstName;
    switch (index) {
      case 0:
        final modifiedProgramas = programas.map((programa) {
          final newPrograma = Map<String, dynamic>.from(programa);
          if (newPrograma['descripcion'] is String) {
            newPrograma['descripcion'] =
                (newPrograma['descripcion'] as String).replaceAll('USER', firstName.isEmpty ? 'tú' : firstName);
          }
          return newPrograma;
        }).toList();
        return PlanScreen(
          nivelEstres: nivelEstres,
          isLoading: isLoading,
          loadFailed: loadFailed,
          programas: modifiedProgramas,
          showExitTestModal: isExitTestEnabled && !hasCompletedExitTest,
          userName: firstName,
          avatarUrl: _customAvatarUrl,
          onRefresh: refresh,
          onOpenProfile: () => _onItemTapped(3),
          onStartExitTest: _startExitTest,
        );
      case 1:
        return ChatScreen(
          userId: userId ?? 0,
          username: firstName.isEmpty ? 'Usuario' : firstName,
          embedded: true,
        );
      case 2:
        return MiTestScreen(
          nivelEstres: nivelEstres,
          isExitTestEnabled: isExitTestEnabled,
          hasCompletedExitTest: hasCompletedExitTest,
          onStartExitTest: _startExitTest,
        );
      default:
        return ProfileScreen(
          profileData: profileData,
          onLogout: _handleLogout,
          onProfileImageUpdated: _updateProfileImage,
          isDay21Completed: hasCompletedExitTest,
          completedDays: _completedDays,
        );
    }
  }

  /// Solo se muestra la foto si el usuario subió una (no la imagen genérica).
  String? get _customAvatarUrl {
    final url = profileData?.profileImage;
    if (url == null || url.endsWith('/assets/user_img.jpg')) return null;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) _onItemTapped(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            for (var i = 0; i < 4; i++)
              // Cada pestaña se crea la primera vez que se visita y luego conserva su estado.
              _visitedTabs.contains(i) ? _buildTab(i) : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _selectedIndex,
          onSelected: _onItemTapped,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  NivelEstres _mapNivelEstresFromString(String nivelString) {
    switch (nivelString.toUpperCase()) {
      case 'LEVE':
        return NivelEstres.leve;
      case 'MODERADO':
        return NivelEstres.moderado;
      case 'ALTO':
      case 'SEVERO':
        return NivelEstres.severo;
      default:
        return NivelEstres.desconocido;
    }
  }
}
