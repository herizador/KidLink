import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/alerta.dart';
import '../theme/constants.dart';

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
      appBar: AppBar(
        title: const Text('Alertas de escaneo', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _cargando
          ? _skeleton()
          : _alertas.isEmpty
              ? const Center(child: Text('No hay alertas registradas', style: TextStyle(color: AppTheme.hintText)))
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

  Widget _skeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppTheme.cardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: sinGps ? Colors.orange.shade100 : Colors.green.shade100,
                child: Icon(
                  sinGps ? Icons.location_off : Icons.location_on,
                  color: sinGps ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alerta.nombreNino ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatearFecha(alerta.fechaHora),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(iconoDispositivo, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(alerta.dispositivoOrigen, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        if (!alerta.visto) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Nuevo', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
            ],
          ),
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
                        userAgentPackageName: 'com.kidlink.kidlink_app',
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
