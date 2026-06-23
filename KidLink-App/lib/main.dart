import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'screens/registro_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.instance.initialize();
  runApp(const KidLinkApp());
}

class KidLinkApp extends StatelessWidget {
  const KidLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = SupabaseService.instance.client.auth.currentSession;

    if (session != null) {
      return const RegistroScreen();
    }

    return const AuthScreen();
  }
}
