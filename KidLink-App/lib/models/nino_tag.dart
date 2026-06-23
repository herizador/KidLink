class NinoTag {
  final String? idTag;
  final String? idPadre;
  final String nombreNino;
  final String informacionMedica;
  final String? contactoAlternativo;
  final String telefonoContacto;
  final String? urlFoto;
  final bool activo;

  NinoTag({
    this.idTag,
    this.idPadre,
    required this.nombreNino,
    this.informacionMedica = '',
    this.contactoAlternativo,
    required this.telefonoContacto,
    this.urlFoto,
    this.activo = true,
  });

  Map<String, dynamic> toInsertMap() {
    final map = <String, dynamic>{
      'nombre_nino': nombreNino,
      'informacion_medica': informacionMedica,
      'contacto_alternativo': contactoAlternativo,
      'telefono_contacto': telefonoContacto,
      'activo': activo,
    };
    if (idPadre != null) map['id_padre'] = idPadre;
    return map;
  }

  factory NinoTag.fromSupabase(Map<String, dynamic> data) {
    return NinoTag(
      idTag: data['id_tag'] as String?,
      idPadre: data['id_padre'] as String?,
      nombreNino: data['nombre_nino'] as String,
      informacionMedica: data['informacion_medica'] as String? ?? '',
      contactoAlternativo: data['contacto_alternativo'] as String?,
      telefonoContacto: data['telefono_contacto'] as String,
      urlFoto: data['url_foto'] as String?,
      activo: data['activo'] as bool? ?? true,
    );
  }
}
