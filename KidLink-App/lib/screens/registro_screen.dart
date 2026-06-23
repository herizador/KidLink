import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../models/nino_tag.dart';
import '../services/supabase_service.dart';
import '../services/nfc_service.dart';
import '../widgets/nfc_bottom_sheet.dart';

enum _EstadoForm { idle, guardando, nfcEscribiendo, exito, error }

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _medicaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  _EstadoForm _estado = _EstadoForm.idle;
  String? _idTagGenerado;
  String? _mensajeError;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _medicaCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estado = _EstadoForm.guardando;
      _mensajeError = null;
    });

    try {
      final nino = NinoTag(
        nombreNino: _nombreCtrl.text.trim(),
        informacionMedica: _medicaCtrl.text.trim(),
        telefonoContacto: _telCtrl.text.trim(),
      );

      final creado = await SupabaseService.instance.insertarNino(nino);

      setState(() {
        _idTagGenerado = creado.idTag;
        _estado = _EstadoForm.idle;
      });
    } catch (e) {
      setState(() {
        _estado = _EstadoForm.error;
        _mensajeError = 'Error al guardar: ${e.toString()}';
      });
    }
  }

  Future<void> _escribirNfc() async {
    final idTag = _idTagGenerado;
    if (idTag == null) return;

    final disponible = await NfcService.instance.estaDisponible();
    if (!mounted) return;

    if (!disponible) {
      _mostrarError('NFC no disponible en este dispositivo');
      return;
    }

    final url = '${AppConfig.webUrgenciaUrl}/nino/$idTag';
    var cancelada = false;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => NfcBottomSheet(
        onCancel: () {
          cancelada = true;
          Navigator.of(ctx).pop();
        },
      ),
    );

    if (cancelada || !mounted) return;

    setState(() => _estado = _EstadoForm.nfcEscribiendo);

    try {
      await NfcService.instance.escribirEnlaceNfc(url);
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() => _estado = _EstadoForm.exito);
      HapticFeedback.heavyImpact();
      _mostrarExito();
    } catch (e) {
      setState(() => _estado = _EstadoForm.idle);
      if (e.toString().contains('User cancelled') || e.toString().contains('409')) {
        _mostrarError('Escritura NFC cancelada');
      } else if (e.toString().contains('NFC')) {
        _mostrarError('Activa el NFC en tu dispositivo');
      } else {
        _mostrarError('Error al escribir NFC: ${e.toString()}');
      }
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Pulsera grabada con éxito',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guardando = _estado == _EstadoForm.guardando;
    final nfcOcupado = _estado == _EstadoForm.nfcEscribiendo;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar en KidLink')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del niño',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Información médica',
                  hintText: 'Alergias, tipo de sangre, condiciones…',
                  prefixIcon: Icon(Icons.medical_services),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de contacto',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: guardando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Text('Guardar', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_idTagGenerado != null && !nfcOcupado)
                      ? _escribirNfc
                      : null,
                  icon: const Icon(Icons.nfc),
                  label: Text(
                    nfcOcupado ? 'Escribiendo…' : 'Grabar Pulsera/Llavero NFC',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_mensajeError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _mensajeError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
