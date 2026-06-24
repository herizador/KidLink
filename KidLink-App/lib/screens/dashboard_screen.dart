import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nino_tag.dart';
import '../services/supabase_service.dart';
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
        title: const Text('Eliminar niño'),
        content: Text('¿Estás seguro de eliminar a ${nino.nombreNino}? '
            'Las alertas asociadas también se borrarán.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
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
        title: const Text('Mis Niños'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Alertas',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AlertasScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Mi Perfil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PerfilScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _ninos.isEmpty
              ? _emptyState()
              : _listaNinos(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irARegistro(),
        child: const Icon(Icons.add),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _irARegistro(),
              icon: const Icon(Icons.add),
              label: const Text('Añadir primer niño'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
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
          onLongPress: () => _eliminarNino(_ninos[i]),
          onQr: () => _navegarQr(_ninos[i]),
        ),
      ),
    );
  }
}

class _TarjetaNino extends StatelessWidget {
  final NinoTag nino;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onQr;

  const _TarjetaNino({
    required this.nino,
    required this.onTap,
    required this.onLongPress,
    required this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: nino.urlFoto != null ? NetworkImage(nino.urlFoto!) : null,
              child: nino.urlFoto == null
                  ? Icon(Icons.child_care, size: 36, color: Colors.grey.shade500)
                  : null,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                nino.nombreNino,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: nino.activo ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                nino.activo ? 'Activa' : 'Inactiva',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: nino.activo ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            IconButton(
              onPressed: onQr,
              icon: const Icon(Icons.qr_code, size: 20),
              tooltip: 'Ver QR',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}


