import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:fnlapp/Login/login.dart';
import 'package:fnlapp/Login/register.dart';
import 'package:fnlapp/Main/home.dart';
import 'package:fnlapp/Preguntas/index.dart';
import 'package:fnlapp/SplashScreen/splashscreen.dart';

import 'SplashScreen/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'Util/api_service.dart';
import 'Util/app_navigator.dart';
import 'Util/token_service.dart';
import 'widgets/session_expired.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  TokenService.instance.onSessionExpired = showSessionExpiredSheet;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Funcy FNL',
      theme: AppTheme.light,
      navigatorKey: appNavigatorKey,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/index': (context) => IndexScreen(
              username: 'username',
              apiServiceWithToken: ApiService(),
            ),
      },
    );
  }
}
