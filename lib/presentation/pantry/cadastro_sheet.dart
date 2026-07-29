import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/pantry/item_tile.dart';
import 'package:despensa/presentation/pantry/pantry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Key campoNomeKey = Key('campo-nome');
const Key campoValidadeKey = Key('campo-validade');
const Key botaoSalvarKey = Key('botao-salvar');
const Key maisOpcoesKey = Key('mais-opcoes');
const Key campoQuantidadeKey = Key('campo-quantidade');
const Key campoPrecoKey = Key('campo-preco');
const Key erroCadastroKey = Key('erro-cadastro');

Future<void> abrirCadastro(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext _) => const CadastroSheet(),
  );
}

class CadastroSheet extends ConsumerStatefulWidget {
  const CadastroSheet({super.key});

  @override
  ConsumerState<CadastroSheet> createState() => _CadastroSheetState();
}

class _CadastroSheetState extends ConsumerState<CadastroSheet> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _validade = TextEditingController();
  final TextEditingController _preco = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    _validade.dispose();
    _preco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final bool gravou =
        await ref.read(cadastroControllerProvider.notifier).save();
    if (gravou && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final CadastroState estado = ref.watch(cadastroControllerProvider);
    final CadastroController controle =
        ref.read(cadastroControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              key: campoNomeKey,
              controller: _nome,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Produto',
                hintText: 'Arroz Tio João 5 kg',
                border: OutlineInputBorder(),
              ),
              onChanged: controle.nameChanged,
            ),
            const SizedBox(height: 14),
            TextField(
              key: campoValidadeKey,
              controller: _validade,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[_MascaraDeData()],
              decoration: InputDecoration(
                labelText: 'Vence em',
                hintText: 'dd/mm/aaaa',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Escolher no calendário',
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () => _escolherValidade(controle),
                ),
              ),
              onChanged: (String texto) =>
                  controle.expiresOnChanged(parseBrDate(texto)),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: maisOpcoesKey,
                onPressed: controle.toggleOptions,
                icon: Icon(
                  estado.optionsOpen
                      ? Icons.expand_less
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
                label: const Text('mais opções'),
              ),
            ),
            if (estado.optionsOpen) _Opcionais(estado: estado, preco: _preco),
            if (estado.error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                estado.error!,
                key: erroCadastroKey,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: botaoSalvarKey,
              onPressed: estado.canSave ? _salvar : null,
              child: estado.busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _escolherValidade(CadastroController controle) async {
    final DateTime hoje = DateTime.now();
    final DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: ref.read(cadastroControllerProvider).expiresOn ?? hoje,
      // Validade no passado é caso real: cadastra-se o que já venceu.
      firstDate: DateTime(hoje.year - 5),
      lastDate: DateTime(hoje.year + 20),
    );
    if (escolhida == null) return;
    _validade.text = formatBrDate(escolhida);
    controle.expiresOnChanged(escolhida);
  }
}

class _Opcionais extends ConsumerWidget {
  const _Opcionais({required this.estado, required this.preco});

  final CadastroState estado;
  final TextEditingController preco;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CadastroController controle =
        ref.read(cadastroControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: campoQuantidadeKey,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  hintText: '1',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String texto) =>
                    controle.quantityChanged(int.tryParse(texto) ?? 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<StorageLocation>(
                initialValue: estado.location,
                decoration: const InputDecoration(
                  labelText: 'Onde',
                  border: OutlineInputBorder(),
                ),
                items: StorageLocation.values
                    .map(
                      (StorageLocation l) => DropdownMenuItem<StorageLocation>(
                        value: l,
                        child: Text(locationLabel(l)),
                      ),
                    )
                    .toList(),
                onChanged: controle.locationChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          key: campoPrecoKey,
          controller: preco,
          keyboardType: TextInputType.number,
          // Dinheiro é inteiro em centavos (ADR 0003), e a máscara é o que faz
          // isso não vazar para quem digita: os dígitos viram 12,99 na hora.
          inputFormatters: <TextInputFormatter>[_MascaraDeCentavos()],
          decoration: const InputDecoration(
            labelText: 'Preço',
            prefixText: 'R\$ ',
            hintText: '0,00',
            border: OutlineInputBorder(),
          ),
          onChanged: (String texto) =>
              controle.priceCentsChanged(centavosDe(texto)),
        ),
      ],
    );
  }

}

/// Dígitos digitados para centavos. `null` quando não há dígito nenhum — campo
/// vazio é "sem preço", não "de graça".
int? centavosDe(String texto) {
  final String digitos = texto.replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) return null;
  return int.parse(digitos);
}

String reaisDe(int centavos) =>
    '${centavos ~/ 100},${(centavos % 100).toString().padLeft(2, '0')}';

/// Mostra os centavos como moeda enquanto se digita: 1299 aparece como 12,99.
class _MascaraDeCentavos extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    final int? centavos = centavosDe(novo.text);
    final String texto = centavos == null ? '' : reaisDe(centavos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Insere as barras enquanto se digita, para `dd/mm/aaaa` sair sem ginástica.
class _MascaraDeData extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    final String digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    final StringBuffer saida = StringBuffer();
    for (int i = 0; i < digitos.length && i < 8; i++) {
      if (i == 2 || i == 4) saida.write('/');
      saida.write(digitos[i]);
    }
    final String texto = saida.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
