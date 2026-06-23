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
      supabaseKey: AppConfig.supabaseAnonKey,
    );
  }

  Future<NinoTag> insertarNino(NinoTag nino) async {
    final response = await client
        .from('ninos_tags')
        .insert(nino.toInsertMap())
        .select()
        .single();

    return NinoTag.fromSupabase(response);
  }
}
