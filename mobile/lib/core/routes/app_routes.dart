import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    "/": (context) => const LoginScreen(),
    "/home": (context) => const PlaceholderScreen(title: "Espace Pèlerin", icon: "🕌"),
    "/guide-home": (context) => const PlaceholderScreen(title: "Espace Guide", icon: "🧭"),
    "/famille-home": (context) => const PlaceholderScreen(title: "Espace Famille", icon: "👨‍👩‍👧"),
  };
  
  }
  class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String icon;

  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                  if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text("Se déconnecter", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
