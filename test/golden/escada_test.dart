import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Este teste não verifica produto nenhum — ele verifica **a escada**.
///
/// Se o PNG gerado aqui mostrar texto legível e um ícone desenhado, o degrau 1
/// está de pé: o agente consegue avaliar UI sozinho, sem build e sem o usuário
/// na frente da tela. Se mostrar caixinhas, o harness de fonte quebrou e
/// nenhum golden do projeto vale nada.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('a escada renderiza texto e ícone', (WidgetTester tester) async {
    await pumpGolden(
      tester,
      const _ProvaDaEscada(),
      size: const Size(320, 200),
    );

    await expectLater(
      find.byType(_ProvaDaEscada),
      matchesGoldenFile('goldens/escada.png'),
    );
  }, tags: <String>['golden']);
}

class _ProvaDaEscada extends StatelessWidget {
  const _ProvaDaEscada();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.kitchen, size: 44),
            const SizedBox(height: 12),
            Text(
              'Despensa',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Vence em 3 dias — 1 unidade',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
