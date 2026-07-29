import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tamanho padrão de tela dos goldens — iPhone 14, em pontos lógicos.
const Size kGoldenSize = Size(390, 844);

/// Carrega fontes reais antes de qualquer golden.
///
/// Sem isto o texto renderiza como caixinha e o PNG não serve para nada — que
/// é justamente o degrau 1 da escada deixar de existir.
///
/// Duas procedências: as fontes declaradas no `pubspec.yaml` (quando houver) e
/// a Roboto que acompanha o SDK. A segunda é resolvida a partir do próprio
/// executável do teste — sem rede e sem caminho absoluto no repositório.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFontsFromManifest();
  await _loadSdkFonts();
}

Future<void> _loadFontsFromManifest() async {
  final Iterable<dynamic> manifest;
  try {
    manifest = await rootBundle.loadStructuredData<Iterable<dynamic>>(
      'FontManifest.json',
      (String s) async => json.decode(s) as Iterable<dynamic>,
    );
  } on Object {
    return; // Projeto ainda não declara fonte própria.
  }

  for (final dynamic font in manifest) {
    final Map<String, dynamic> entry = font as Map<String, dynamic>;
    final FontLoader loader = FontLoader(entry['family'] as String);
    for (final dynamic asset in entry['fonts'] as List<dynamic>) {
      loader.addFont(
        rootBundle.load((asset as Map<String, dynamic>)['asset'] as String),
      );
    }
    await loader.load();
  }
}

Future<void> _loadSdkFonts() async {
  final Directory? fonts = _sdkFontsDir();
  if (fonts == null) {
    throw StateError(
      'Não encontrei material_fonts no SDK a partir de '
      '${Platform.resolvedExecutable}. Sem fonte real o golden vira caixinha '
      '— corrija o harness antes de gerar qualquer PNG.',
    );
  }

  await _load('Roboto', <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Italic.ttf',
  ], fonts);
  await _load('MaterialIcons', <String>['MaterialIcons-Regular.otf'], fonts);
}

Future<void> _load(String family, List<String> files, Directory dir) async {
  final FontLoader loader = FontLoader(family);
  var carregou = false;
  for (final String name in files) {
    final File file = File('${dir.path}/$name');
    if (!file.existsSync()) continue;
    loader.addFont(
      file.readAsBytes().then(ByteData.sublistView),
    );
    carregou = true;
  }
  if (carregou) await loader.load();
}

/// Sobe a partir do executável do teste até achar `bin/cache/artifacts`.
Directory? _sdkFontsDir() {
  Directory? dir = File(Platform.resolvedExecutable).parent;
  while (dir != null) {
    final Directory candidato = Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    );
    if (candidato.existsSync()) return candidato;
    final Directory pai = dir.parent;
    dir = pai.path == dir.path ? null : pai;
  }
  return null;
}

/// Envolve o widget no tema real, para o PNG refletir o app.
Widget golden(Widget child, {ThemeData? theme}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme ?? ThemeData(useMaterial3: true),
  home: Scaffold(body: Center(child: child)),
);

/// Renderiza num tamanho de tela fixo e determinístico.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  Size size = kGoldenSize,
  ThemeData? theme,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(golden(child, theme: theme));
  await tester.pumpAndSettle();
}
