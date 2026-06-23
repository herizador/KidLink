import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'screens/registro_screen.dart';

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
      home: const RegistroScreen(),
    );
  }
}
