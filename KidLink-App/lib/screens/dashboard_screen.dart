import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nino_tag.dart';
import '../services/supabase_service.dart';
import '../theme/constants.dart';
import 'registro_screen.dart';
import 'alertas_screen.dart';
import 'perfil_screen.dart';
import 'qr_screen.dart';
import 'auth_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<NinoTag> _ninos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNinos();
  }

  Future<void> _cargarNinos() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final ninos = await SupabaseService.instance.obtenerNinos(userId);
    if (!mounted) return;
    setState(() {
      _ninos = ninos;
      _cargando = false;
    });
  }

  Future<void> _eliminarNino(NinoTag nino) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever, color: Color(0xFFDC2626), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              '¿Estás seguro de que deseas eliminar a ${nino.nombreNino}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta acción es irreversible y borrará todo su historial de alertas de forma permanente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.hintText, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Eliminar permanentemente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16, color: AppTheme.hintText)),
            ),
          ],
        ),
      ),
    );

    if (confirmado != true) return;

    await SupabaseService.instance.eliminarNino(nino.idTag!);
    _cargarNinos();
  }

  void _irARegistro({NinoTag? nino}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegistroScreen(ninoParaEditar: nino),
      ),
    ).then((_) => _cargarNinos());
  }

  void _navegarQr(NinoTag nino) {
    const url = String.fromEnvironment('WEB_URGENCIA_URL');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QrScreen(nino: nino, webUrgenciaUrl: url),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Niños', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.navy),
            tooltip: 'Alertas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlertasScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.navy),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.navy),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _cargando
          ? _skeleton()
          : _ninos.isEmpty
              ? _emptyState()
              : _listaNinos(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _irARegistro(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Añadir niño', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _skeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0)),
              ),
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.child_care, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes niños registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              'Añade un niño y graba su pulsera NFC para empezar',
              style: TextStyle(fontSize: 14, color: AppTheme.hintText),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _irARegistro(),
              icon: const Icon(Icons.add),
              label: const Text('Añadir primer niño'),
              style: AppTheme.primaryButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listaNinos() {
    return RefreshIndicator(
      onRefresh: _cargarNinos,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _ninos.length,
        itemBuilder: (_, i) => _TarjetaNino(
          nino: _ninos[i],
          onTap: () => _irARegistro(nino: _ninos[i]),
          onQr: () => _navegarQr(_ninos[i]),
          onEliminar: () => _eliminarNino(_ninos[i]),
          onEstadoCambiado: (_) => _cargarNinos(),
        ),
      ),
    );
  }
}

class _TarjetaNino extends StatefulWidget {
  final NinoTag nino;
  final VoidCallback onTap;
  final VoidCallback? onQr;
  final VoidCallback onEliminar;
  final ValueChanged<bool> onEstadoCambiado;

  const _TarjetaNino({
    required this.nino,
    required this.onTap,
    this.onQr,
    required this.onEliminar,
    required this.onEstadoCambiado,
  });

  @override
  State<_TarjetaNino> createState() => _TarjetaNinoState();
}

class _TarjetaNinoState extends State<_TarjetaNino> {
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _activo = widget.nino.activo;
  }

  Future<void> _toggleActivo(bool value) async {
    setState(() => _activo = value);
    try {
      await SupabaseService.instance.actualizarEstadoActivo(
        widget.nino.idTag!,
        value,
      );
      widget.onEstadoCambiado(value);
    } catch (_) {
      setState(() => _activo = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacidad = _activo ? 1.0 : 0.55;

    return Opacity(
      opacity: opacidad,
      child: Container(
        decoration: AppTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: widget.nino.urlFoto != null
                        ? NetworkImage(widget.nino.urlFoto!)
                        : null,
                    child: widget.nino.urlFoto == null
                        ? Icon(Icons.child_care, size: 36, color: Colors.grey.shade500)
                        : null,
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: widget.onEliminar,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _activo ? const Color(0xFFFEE2E2) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: _activo ? const Color(0xFFDC2626) : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.nino.nombreNino,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.navy),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _activo ? 'Activa' : 'Inactiva',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _activo ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch.adaptive(
                    value: _activo,
                    onChanged: _toggleActivo,
                    activeColor: AppTheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              if (_activo) ...[
                const SizedBox(height: 4),
                IconButton(
                  onPressed: widget.onQr,
                  icon: const Icon(Icons.qr_code, size: 20, color: AppTheme.primary),
                  tooltip: 'Ver QR',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


