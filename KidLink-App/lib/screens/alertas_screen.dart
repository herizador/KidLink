import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/alerta.dart';

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Alerta> _alertas = [];
  RealtimeChannel? _alertaChannel;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
    _escucharTiempoReal();
  }

  @override
  void dispose() {
    if (_alertaChannel != null) {
      Supabase.instance.client.removeChannel(_alertaChannel!);
    }
    super.dispose();
  }

  Future<void> _cargarAlertas() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    final tagsResponse = await supabase
        .from('ninos_tags')
        .select('id_tag, nombre_nino')
        .eq('id_padre', userId);

    final tagMap = <String, String>{};
    for (final t in tagsResponse) {
      tagMap[t['id_tag'] as String] = t['nombre_nino'] as String;
    }

    final alertasResponse = await supabase
        .from('alertas_escaneo')
        .select()
        .inFilter('id_tag', tagMap.keys.toList())
        .order('fecha_hora', ascending: false);

    final alertas = (alertasResponse as List).map((a) {
      final idTag = a['id_tag'] as String;
      return Alerta.fromSupabase(a, nombreNino: tagMap[idTag]);
    }).toList();

    if (!mounted) return;
    setState(() {
      _alertas = alertas;
      _cargando = false;
    });
  }

  void _escucharTiempoReal() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _alertaChannel = supabase
        .channel('public:alertas_escaneo')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alertas_escaneo',
          callback: (payload) async {
            if (payload.eventType != PostgresChangeEvent.insert) return;
            final newIdTag = payload.newRecord['id_tag'] as String;

            final tagRes = await supabase
                .from('ninos_tags')
                .select('nombre_nino')
                .eq('id_tag', newIdTag)
                .eq('id_padre', userId);

            if (tagRes.isEmpty) return;

            final nombre = tagRes[0]['nombre_nino'] as String;
            final alerta = Alerta.fromSupabase(payload.newRecord, nombreNino: nombre);

            if (!mounted) return;
            setState(() => _alertas.insert(0, alerta));
            HapticFeedback.heavyImpact();
          },
        );

    _alertaChannel?.subscribe();
  }

  Future<void> _marcarComoVisto(String idAlerta) async {
    await Supabase.instance.client
        .from('alertas_escaneo')
        .update({'visto': true})
        .eq('id_alerta', idAlerta);

    setState(() {
      final idx = _alertas.indexWhere((a) => a.idAlerta == idAlerta);
      if (idx != -1) {
        _alertas[idx] = Alerta(
          idAlerta: _alertas[idx].idAlerta,
          idTag: _alertas[idx].idTag,
          nombreNino: _alertas[idx].nombreNino,
          latitud: _alertas[idx].latitud,
          longitud: _alertas[idx].longitud,
          gpsActivo: _alertas[idx].gpsActivo,
          dispositivoOrigen: _alertas[idx].dispositivoOrigen,
          fechaHora: _alertas[idx].fechaHora,
          visto: true,
        );
      }
    });
  }

  void _mostrarMapa(Alerta alerta) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MapaAlerta(alerta: alerta),
    );
  }

  IconData _iconoDispositivo(String origen) {
    switch (origen.toLowerCase()) {
      case 'ios':
        return Icons.phone_iphone;
      case 'android':
        return Icons.android;
      default:
        return Icons.language;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas de escaneo')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? const Center(child: Text('No hay alertas registradas'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _alertas.length,
                  itemBuilder: (_, i) => _AlertaCard(
                    alerta: _alertas[i],
                    iconoDispositivo: _iconoDispositivo(_alertas[i].dispositivoOrigen),
                    onTap: () {
                      if (!_alertas[i].visto) _marcarComoVisto(_alertas[i].idAlerta);
                      if (_alertas[i].gpsActivo &&
                          _alertas[i].latitud != null &&
                          _alertas[i].longitud != null) {
                        _mostrarMapa(_alertas[i]);
                      }
                    },
                  ),
                ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final Alerta alerta;
  final IconData iconoDispositivo;
  final VoidCallback onTap;

  const _AlertaCard({
    required this.alerta,
    required this.iconoDispositivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sinGps = !alerta.gpsActivo || alerta.latitud == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: alerta.visto ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: sinGps ? Colors.orange.shade100 : Colors.green.shade100,
          child: Icon(
            sinGps ? Icons.location_off : Icons.location_on,
            color: sinGps ? Colors.orange : Colors.green,
          ),
        ),
        title: Text(alerta.nombreNino ?? 'Sin nombre',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatearFecha(alerta.fechaHora)),
            Row(
              children: [
                Icon(iconoDispositivo, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(alerta.dispositivoOrigen, style: const TextStyle(fontSize: 12)),
                if (!alerta.visto) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Nuevo',
                        style: TextStyle(fontSize: 10, color: Colors.red.shade800)),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatearFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _MapaAlerta extends StatelessWidget {
  final Alerta alerta;

  const _MapaAlerta({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final tieneGps = alerta.gpsActivo && alerta.latitud != null && alerta.longitud != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(alerta.nombreNino ?? 'Alerta',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_formatearFecha(alerta.fechaHora)),
            const SizedBox(height: 16),
            if (tieneGps)
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(alerta.latitud!, alerta.longitud!),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(alerta.latitud!, alerta.longitud!),
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_on,
                                size: 40, color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'El código fue escaneado en esta fecha y hora, '
                  'pero la ubicación exacta no fue compartida por el descubridor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
