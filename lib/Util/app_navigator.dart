import 'package:flutter/material.dart';

/// Navegador global, para reaccionar a eventos que ocurren fuera de una
/// pantalla (por ejemplo, cuando la sesión expira).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
