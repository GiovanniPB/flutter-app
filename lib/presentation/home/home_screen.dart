import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Key sairKey = Key('sair');

/// Casca da home. Nesta fatia mostra só o vazio — a lista de vencendo e o FAB
/// nascem nas fatias seguintes, junto com as ações que disparam.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vencendo'),
        actions: <Widget>[
          IconButton(
            key: sairKey,
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.mood,
                size: 40,
                color: tema.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              // Vazio aqui é sucesso, não erro: nada vencendo é a melhor
              // notícia que este app pode dar.
              Text('Nada vencendo', style: tema.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Sua despensa está em dia.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
