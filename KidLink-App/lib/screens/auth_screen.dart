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

  Future<void> _registrarse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        data: {
          'nombre': _nombreCtrl.text.trim(),
          'telefono_emergencia': _telefonoCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      _mostrarVerificacion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception('No se pudo iniciar sesión.');
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RegistroScreen()),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (msg.contains('email not confirmed') ||
          msg.contains('email not verified') ||
          msg.contains('not confirmed')) {
        _mostrarErrorVerificacion();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('email not confirmed') ||
          msg.contains('email not verified') ||
          msg.contains('not confirmed')) {
        _mostrarErrorVerificacion();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarVerificacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              '¡Registro casi completado!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hemos enviado un enlace de verificación a tu correo. '
              'Por favor, confírmalo antes de iniciar sesión en KidLink.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarErrorVerificacion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No puedes ingresar: Por favor, revisa tu bandeja de entrada '
          'y verifica tu correo electrónico antes de continuar.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campos = <Widget>[
      if (_esRegistro)
        TextFormField(
          controller: _nombreCtrl,
          enabled: !_cargando,
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
        enabled: !_cargando,
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
        enabled: !_cargando,
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
          enabled: !_cargando,
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
                  onPressed: _cargando ? null : (_esRegistro ? _registrarse : _iniciarSesion),
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
                onPressed: _cargando ? null : () => setState(() => _esRegistro = !_esRegistro),
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
