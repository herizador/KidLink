import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/nino_tag.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();
  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  // --- Niños ---

  Future<NinoTag> insertarNino(NinoTag nino) async {
    final response = await client
        .from('ninos_tags')
        .insert(nino.toInsertMap())
        .select()
        .single();

    return NinoTag.fromSupabase(response);
  }

  Future<NinoTag> actualizarNino(NinoTag nino) async {
    final response = await client
        .from('ninos_tags')
        .update(nino.toInsertMap())
        .eq('id_tag', nino.idTag)
        .select()
        .single();

    return NinoTag.fromSupabase(response);
  }

  Future<void> eliminarNino(String idTag) async {
    await client.from('ninos_tags').delete().eq('id_tag', idTag);
  }

  Future<List<NinoTag>> obtenerNinos(String idPadre) async {
    final response = await client
        .from('ninos_tags')
        .select()
        .eq('id_padre', idPadre)
        .order('nombre_nino');

    return (response as List).map((e) => NinoTag.fromSupabase(e)).toList();
  }

  Future<NinoTag?> obtenerNinoPorId(String idTag) async {
    final response = await client
        .from('ninos_tags')
        .select()
        .eq('id_tag', idTag)
        .single();

    return NinoTag.fromSupabase(response);
  }

  // --- Perfil del padre ---

  Future<Map<String, dynamic>> obtenerPerfil(String userId) async {
    final response = await client
        .from('perfiles_padres')
        .select()
        .eq('id', userId)
        .single();

    return response;
  }

  Future<void> actualizarPerfil(String userId, Map<String, dynamic> data) async {
    await client.from('perfiles_padres').update(data).eq('id', userId);
  }
}
