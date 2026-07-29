import 'package:despensa/domain/auth/auth_repository.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/auth/entrar_screen.dart';
import 'package:despensa/presentation/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DespensaApp extends StatelessWidget {
  const DespensaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despensa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const _Portao(),
    );
  }
}

/// Decide a primeira tela pela sessão. Enquanto o stream não resolveu, mostra
/// vazio — piscar a tela de login para quem já está dentro é pior que esperar.
class _Portao extends ConsumerWidget {
  const _Portao();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AuthUser?> sessao = ref.watch(authUserProvider);

    return sessao.when(
      data: (AuthUser? usuario) =>
          usuario == null ? const EntrarScreen() : const HomeScreen(),
      loading: () => const Scaffold(body: SizedBox.shrink()),
      error: (_, _) => const EntrarScreen(),
    );
  }
}
