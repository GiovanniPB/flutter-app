import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: DespensaApp()));
}

class DespensaApp extends StatelessWidget {
  const DespensaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despensa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AndaimeScreen(),
    );
  }
}

/// Placeholder do andaime — some na primeira fatia (`entrar`).
class AndaimeScreen extends StatelessWidget {
  const AndaimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.kitchen, size: 48),
            const SizedBox(height: 12),
            Text('Despensa', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Andaime de pé. Próxima fatia: entrar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
