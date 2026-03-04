import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    "/": (context) => const LoginScreen(),
  
  };
}