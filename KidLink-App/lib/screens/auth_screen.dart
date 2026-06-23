import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _esRegistro = true;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text.trim();

      if (_esRegistro) {
        final supabase = Supabase.instance.client;
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'nombre': _nombreCtrl.text.trim(),
            'telefono_emergencia': _telefonoCtrl.text.trim(),
          },
        );
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RegistroScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campos = <Widget>[
      if (_esRegistro)
        TextFormField(
          controller: _nombreCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          validator: _esRegistro
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
              : null,
        ),
      if (_esRegistro) const SizedBox(height: 16),
      TextFormField(
        controller: _emailCtrl,
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email),
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (v) =>
            (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Email válido requerido' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordCtrl,
        decoration: const InputDecoration(
          labelText: 'Contraseña',
          prefixIcon: Icon(Icons.lock),
          border: OutlineInputBorder(),
        ),
        obscureText: true,
        validator: (v) =>
            (v == null || v.trim().length < 6) ? 'Mínimo 6 caracteres' : null,
      ),
      if (_esRegistro) const SizedBox(height: 16),
      if (_esRegistro)
        TextFormField(
          controller: _telefonoCtrl,
          decoration: const InputDecoration(
            labelText: 'Teléfono de emergencia',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: _esRegistro
              ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
              : null,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_esRegistro ? 'Crear cuenta' : 'Iniciar sesión')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...campos,
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _cargando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : Text(
                          _esRegistro ? 'Registrarse' : 'Iniciar sesión',
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _esRegistro = !_esRegistro),
                child: Text(
                  _esRegistro
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : '¿No tienes cuenta? Regístrate',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
