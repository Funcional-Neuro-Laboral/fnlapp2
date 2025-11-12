import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fnlapp/Preguntas/index.dart';
import 'package:fnlapp/Main/home.dart';
import 'package:fnlapp/Main/testestres_form.dart'; // o como se llame tu test
import '../Util/api_service.dart'; 
import 'package:fnlapp/Login/login.dart';
import 'package:fnlapp/SplashScreen/splashscreen.dart';

class RouteWrapper extends StatelessWidget {
  final String routeName;

  const RouteWrapper({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final prefs = snapshot.data as SharedPreferences;
        final permisopoliticas = prefs.getBool('permisopoliticas') ?? false;
        final userresponsebool = prefs.getBool('userresponsebool') ?? false;
        final testestresbool = prefs.getBool('testestresbool') ?? false;

        // Lógica de redirección segura
        if (routeName == '/home') {
          if (!permisopoliticas || !userresponsebool || !testestresbool) {
            // Redirigir de forma segura si no completó el proceso
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/index');
            });
            return const SizedBox(); // pantalla vacía temporal
          } else {
            return HomeScreen();
          }
        }

        if (routeName == '/index') {
          // Si ya completó todo, ir a home
          if (permisopoliticas && userresponsebool && testestresbool) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
            return const SizedBox();
          }
          // Si falta el test de estrés, ir al test
          else if (permisopoliticas && userresponsebool && !testestresbool) {
            return TestEstresQuestionScreen();
          }
          // Si faltan políticas o respuestas iniciales, ir al index
          else {
            return IndexScreen(
              username: 'username',
              apiServiceWithToken: ApiService(),
            );
          }
        }

        if (routeName == '/login') {
          return LoginScreen();
        }

        // Default: splash
        return SplashScreen();
      },
    );
  }
}
