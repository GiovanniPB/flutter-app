import 'dart:convert';
import 'dart:io';

import 'package:despensa/data/auth/supabase_auth_repository.dart';
import 'package:despensa/data/pantry/pantry_mapper.dart';
import 'package:despensa/data/pantry/supabase_pantry_repository.dart';
import 'package:despensa/domain/auth/email.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:flutter_test/flutter_test.dart';
// `supabase_flutter` reexporta os tipos do gotrue, então não precisamos declarar
// dependência direta num pacote que já vem por baixo.
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Harness do teste de integração (ADR 0010). Roda contra o Supabase local, e
/// por isso fica fora do CI.
///
/// Configuração injetada por `tool/test_integration.sh` via `--dart-define`:
/// nenhuma URL nem chave escrita no repositório.
const String apiUrl = String.fromEnvironment('SUPABASE_URL');
const String publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
const String mailUrl = String.fromEnvironment('MAIL_URL');
const String dbContainer = String.fromEnvironment('DB_CONTAINER');

/// Falha alto quando o stack não chegou. Teste de integração que passa sem
/// banco é pior que teste que não existe.
void exigirStackLocal() {
  final Map<String, String> faltando = <String, String>{
    'SUPABASE_URL': apiUrl,
    'SUPABASE_PUBLISHABLE_KEY': publishableKey,
    'MAIL_URL': mailUrl,
    'DB_CONTAINER': dbContainer,
  }..removeWhere((_, String valor) => valor.isNotEmpty);

  if (faltando.isNotEmpty) {
    fail(
      'faltou ${faltando.keys.join(', ')}. Rode por '
      '`bash tool/test_integration.sh`, não por `flutter test` direto.',
    );
  }
}

class _MemoriaDeSessao extends supabase.GotrueAsyncStorage {
  final Map<String, String> _itens = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _itens[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _itens[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _itens.remove(key);
}

/// Uma sessão autenticada de verdade, com repositórios prontos.
class SessaoDeTeste {
  SessaoDeTeste._({
    required this.email,
    required this.userId,
    required this.accessToken,
    required this.contas,
  });

  final String email;
  final String userId;
  final String accessToken;
  final SupabaseAuthRepository contas;

  /// Um cliente recém-construído: é assim que se simula o app fechado e aberto.
  SupabasePantryRepository despensaNova() => SupabasePantryRepository(
        supabase.SupabaseClient(
          apiUrl,
          publishableKey,
          headers: <String, String>{'Authorization': 'Bearer $accessToken'},
        ),
      );

  /// Leitura direta com as mesmas colunas do repositório. Existe porque
  /// `watchItems` depende do Realtime, que é outro débito.
  Future<List<PantryItem>> lerDespensa() async {
    final List<Map<String, dynamic>> linhas = await supabase.SupabaseClient(
      apiUrl,
      publishableKey,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    )
        .from('pantry_items')
        .select(pantryItemColumns)
        .order('created_at', ascending: false);
    return linhas.map(itemFromRow).toList();
  }

  /// Apaga o usuário; a cascata leva casa, produtos e itens. Chamado em
  /// `addTearDown` por `entrar()` — teste que deixa lixo quebra o vizinho.
  Future<void> limpar() =>
      psql("delete from auth.users where id = '$userId'");
}

/// Cria um usuário novo, lê o código na caixa local e entra.
Future<SessaoDeTeste> entrar() async {
  exigirStackLocal();

  final String endereco =
      'integracao-${DateTime.now().microsecondsSinceEpoch}@exemplo.test';
  final Email email = Email.tryParse(endereco)!;

  final supabase.GoTrueClient auth = supabase.GoTrueClient(
    url: '$apiUrl/auth/v1',
    headers: <String, String>{
      'apikey': publishableKey,
      'Authorization': 'Bearer $publishableKey',
    },
    autoRefreshToken: false,
    asyncStorage: _MemoriaDeSessao(),
  );
  final SupabaseAuthRepository contas = SupabaseAuthRepository(auth);

  await contas.sendCode(email);
  await contas.verifyCode(email: email, code: await codigoDoEmail(endereco));

  final SessaoDeTeste sessao = SessaoDeTeste._(
    email: endereco,
    userId: contas.currentUser!.id,
    accessToken: auth.currentSession!.accessToken,
    contas: contas,
  );
  addTearDown(sessao.limpar);
  return sessao;
}

/// O código de 6 dígitos que chegou para aquele endereço na caixa local.
Future<String> codigoDoEmail(String destinatario) async {
  final Map<String, dynamic> caixa =
      json.decode(await _get('$mailUrl/api/v1/messages?limit=50'))
          as Map<String, dynamic>;

  for (final dynamic bruto in caixa['messages'] as List<dynamic>) {
    final String id = (bruto as Map<String, dynamic>)['ID'] as String;
    final String texto = await _get('$mailUrl/api/v1/message/$id');
    if (!texto.contains(destinatario)) continue;
    final RegExpMatch? achou = RegExp(r'\b(\d{6})\b').firstMatch(texto);
    if (achou != null) return achou.group(1)!;
  }
  fail('nenhum código de 6 dígitos para $destinatario em $mailUrl');
}

/// SQL direto no container, para conferir o que a API não mostra.
Future<String> psql(String sql) async {
  final ProcessResult r = await Process.run('docker', <String>[
    'exec',
    dbContainer,
    'psql',
    '-U',
    'postgres',
    '-d',
    'postgres',
    '-t',
    '-A',
    '-c',
    sql,
  ]);
  if (r.exitCode != 0) fail('psql falhou: ${r.stderr}');
  return (r.stdout as String).trim();
}

Future<String> _get(String url) async {
  final HttpClient cliente = HttpClient();
  try {
    final HttpClientRequest pedido = await cliente.getUrl(Uri.parse(url));
    final HttpClientResponse resposta = await pedido.close();
    return await resposta.transform(utf8.decoder).join();
  } finally {
    cliente.close();
  }
}
