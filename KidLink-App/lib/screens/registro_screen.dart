import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/nino_tag.dart';
import '../services/supabase_service.dart';
import '../services/nfc_service.dart';
import '../theme/constants.dart';
import '../widgets/nfc_bottom_sheet.dart';
import 'alertas_screen.dart';

enum _EstadoForm { idle, guardando, nfcEscribiendo, exito, error }

class RegistroScreen extends StatefulWidget {
  final NinoTag? ninoParaEditar;

  const RegistroScreen({super.key, this.ninoParaEditar});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _medicaCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  final _picker = ImagePicker();
  File? _imageFile;

  _EstadoForm _estado = _EstadoForm.idle;
  String? _idTagGenerado;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    final nino = widget.ninoParaEditar;
    if (nino != null) {
      _nombreCtrl.text = nino.nombreNino;
      _medicaCtrl.text = nino.informacionMedica;
      _telCtrl.text = nino.telefonoContacto;
      _idTagGenerado = nino.idTag;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _medicaCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512);
    if (xFile != null) {
      setState(() => _imageFile = File(xFile.path));
    }
  }

  void _mostrarSelectorFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OpcionFoto(
                icon: Icons.camera_alt,
                label: 'Cámara',
                onTap: () {
                  Navigator.of(context).pop();
                  _seleccionarFoto(ImageSource.camera);
                },
              ),
              _OpcionFoto(
                icon: Icons.photo_library,
                label: 'Galería',
                onTap: () {
                  Navigator.of(context).pop();
                  _seleccionarFoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _subirFoto() async {
    final file = _imageFile!;
    final bytes = await file.readAsBytes();
    final path = 'subidas/foto_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await Supabase.instance.client.storage
        .from('fotos_ninos')
        .uploadBinary(path, bytes);

    return Supabase.instance.client.storage
        .from('fotos_ninos')
        .getPublicUrl(path);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _mostrarError('Sesión expirada. Reinicia la aplicación para iniciar sesión de nuevo.');
      return;
    }

    setState(() {
      _estado = _EstadoForm.guardando;
      _mensajeError = null;
    });

    try {
      String? urlFoto;
      if (_imageFile != null) {
        urlFoto = await _subirFoto();
      }

      final editing = widget.ninoParaEditar != null;
      final nino = NinoTag(
        idTag: editing ? widget.ninoParaEditar!.idTag : null,
        idPadre: userId,
        nombreNino: _nombreCtrl.text.trim(),
        informacionMedica: _medicaCtrl.text.trim(),
        telefonoContacto: _telCtrl.text.trim(),
        urlFoto: urlFoto ?? widget.ninoParaEditar?.urlFoto,
      );

      final creado = editing
          ? await SupabaseService.instance.actualizarNino(nino)
          : await SupabaseService.instance.insertarNino(nino);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF059669), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Pulsera grabada con éxito',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.navy),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: AppTheme.primaryButton(),
                child: const Text('Aceptar'),
              ),
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
      appBar: AppBar(
        title: Text(widget.ninoParaEditar != null ? 'Editar niño' : 'Registrar en KidLink'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de alertas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlertasScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _mostrarSelectorFoto,
                  child: Container(
                    decoration: AppTheme.cardDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                          child: _imageFile == null
                              ? const Icon(Icons.add_a_photo, size: 32, color: AppTheme.primary)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _imageFile == null ? 'Añadir foto' : 'Cambiar foto',
                          style: const TextStyle(fontSize: 13, color: AppTheme.hintText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreCtrl,
                decoration: AppTheme.inputDecoration(
                  label: 'Nombre del niño',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicaCtrl,
                decoration: AppTheme.inputDecoration(
                  label: 'Información médica',
                  hint: 'Alergias, tipo de sangre, condiciones…',
                  prefixIcon: const Icon(Icons.medical_services_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telCtrl,
                decoration: AppTheme.inputDecoration(
                  label: 'Teléfono de contacto',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: guardando ? null : _guardar,
                style: AppTheme.primaryButton(),
                child: guardando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    : const Text('Guardar datos del niño'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (_idTagGenerado != null && !nfcOcupado)
                    ? _escribirNfc
                    : null,
                icon: const Icon(Icons.nfc),
                label: Text(
                  nfcOcupado ? 'Escribiendo…' : 'Grabar Pulsera / Llavero NFC',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade400,
                  minimumSize: const Size.fromHeight(AppTheme.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.inputRadius),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              if (_mensajeError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _mensajeError!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
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

class _OpcionFoto extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OpcionFoto({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue.shade600, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
