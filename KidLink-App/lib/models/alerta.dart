class Alerta {
  final String idAlerta;
  final String idTag;
  final String? nombreNino;
  final double? latitud;
  final double? longitud;
  final bool gpsActivo;
  final String dispositivoOrigen;
  final DateTime fechaHora;
  final bool visto;

  Alerta({
    required this.idAlerta,
    required this.idTag,
    this.nombreNino,
    this.latitud,
    this.longitud,
    required this.gpsActivo,
    required this.dispositivoOrigen,
    required this.fechaHora,
    required this.visto,
  });

  factory Alerta.fromSupabase(Map<String, dynamic> data, {String? nombreNino}) {
    return Alerta(
      idAlerta: data['id_alerta'] as String,
      idTag: data['id_tag'] as String,
      nombreNino: nombreNino,
      latitud: (data['latitud'] as num?)?.toDouble(),
      longitud: (data['longitud'] as num?)?.toDouble(),
      gpsActivo: data['gps_activo'] as bool,
      dispositivoOrigen: data['dispositivo_origen'] as String? ?? 'Web',
      fechaHora: DateTime.parse(data['fecha_hora'] as String),
      visto: data['visto'] as bool? ?? false,
    );
  }
}
