import 'package:despensa/app/app.dart';
import 'package:despensa/app/supabase.dart';
import 'package:despensa/data/auth/supabase_auth_repository.dart';
import 'package:despensa/data/pantry/supabase_pantry_repository.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/pantry/pantry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();

  final SupabaseClient cliente = Supabase.instance.client;

  runApp(
    ProviderScope(
      // O único lugar do app que amarra o domínio ao Supabase.
      overrides: [
        authRepositoryProvider
            .overrideWithValue(SupabaseAuthRepository(cliente.auth)),
        pantryRepositoryProvider
            .overrideWithValue(SupabasePantryRepository(cliente)),
      ],
      child: const DespensaApp(),
    ),
  );
}
