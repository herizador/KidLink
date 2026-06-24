import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/constants.dart';
import 'dashboard_screen.dart';

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
  bool _ocultarPassword = true;

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
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_unread, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Registro casi completado!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navy),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hemos enviado un enlace de verificación a tu correo. '
              'Por favor, confírmalo antes de iniciar sesión en KidLink.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppTheme.hintText, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: AppTheme.primaryButton(),
                child: const Text('Entendido'),
              ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/KidLink Logo.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'KidLink',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La red de protección inteligente para tus hijos',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 40),

                if (_esRegistro)
                  TextFormField(
                    controller: _nombreCtrl,
                    enabled: !_cargando,
                    decoration: AppTheme.inputDecoration(
                      label: 'Nombre',
                      prefixIcon: const Icon(Icons.person_outline),
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
                  decoration: AppTheme.inputDecoration(
                    label: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty || !v.contains('@')) ? 'Email válido requerido' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  enabled: !_cargando,
                  decoration: AppTheme.inputDecoration(
                    label: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.hintText,
                      ),
                      onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                    ),
                  ),
                  obscureText: _ocultarPassword,
                  validator: (v) =>
                      (v == null || v.trim().length < 6) ? 'Mínimo 6 caracteres' : null,
                ),

                if (_esRegistro) const SizedBox(height: 16),
                if (_esRegistro)
                  TextFormField(
                    controller: _telefonoCtrl,
                    enabled: !_cargando,
                    decoration: AppTheme.inputDecoration(
                      label: 'Teléfono de emergencia',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _esRegistro
                        ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
                        : null,
                  ),

                const SizedBox(height: 32),

                FilledButton(
                  onPressed: _cargando ? null : (_esRegistro ? _registrarse : _iniciarSesion),
                  style: AppTheme.primaryButton(),
                  child: _cargando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : Text(
                          _esRegistro ? 'Crear Cuenta' : 'Ingresar',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: _cargando ? null : () => setState(() => _esRegistro = !_esRegistro),
                    child: Text(
                      _esRegistro
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
