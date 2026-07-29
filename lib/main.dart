import 'package:despensa/app/app.dart';
import 'package:despensa/app/supabase.dart';
import 'package:despensa/data/auth/supabase_auth_repository.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();

  runApp(
    ProviderScope(
      overrides: [
        // O único lugar do app que amarra o domínio ao Supabase.
        authRepositoryProvider.overrideWithValue(
          SupabaseAuthRepository(Supabase.instance.client.auth),
        ),
      ],
      child: const DespensaApp(),
    ),
  );
}
