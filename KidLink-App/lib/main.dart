import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
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
      home: const _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  bool _revisando = true;
  bool? _tieneSesion;

  @override
  void initState() {
    super.initState();
    _revisarSesion();
  }

  Future<void> _revisarSesion() async {
    final session = SupabaseService.instance.client.auth.currentSession;
    if (!mounted) return;
    setState(() {
      _tieneSesion = session != null;
      _revisando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_revisando) return const SplashScreen();

    if (_tieneSesion == true) {
      return const DashboardScreen();
    }

    return const AuthScreen();
  }
}
