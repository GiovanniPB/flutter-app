import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuração vem de `--dart-define-from-file=env/<flavor>.json` (ADR 0001).
/// No cliente, só a chave publicável — a service-role nunca entra aqui.
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

/// Falha alto e cedo: app sem configuração é bug de execução, não estado de
/// interface.
Future<void> initSupabase() async {
  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY não chegaram. Rode com '
      '--dart-define-from-file=env/dev.json (veja env/dev.example.json).',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}
