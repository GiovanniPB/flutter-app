import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Key campoEmailKey = Key('campo-email');
const Key botaoEnviarKey = Key('botao-enviar');
const Key campoCodigoKey = Key('campo-codigo');
const Key erroKey = Key('erro');

class EntrarScreen extends ConsumerStatefulWidget {
  const EntrarScreen({super.key});

  @override
  ConsumerState<EntrarScreen> createState() => _EntrarScreenState();
}

class _EntrarScreenState extends ConsumerState<EntrarScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _codigo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codigo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EntrarState estado = ref.watch(entrarControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: switch (estado.step) {
            EntrarStep.email => _PassoEmail(
                controller: _email,
                estado: estado,
              ),
            EntrarStep.code => _PassoCodigo(
                controller: _codigo,
                estado: estado,
                onVoltar: () {
                  _codigo.clear();
                  ref.read(entrarControllerProvider.notifier).backToEmail();
                },
              ),
          },
        ),
      ),
    );
  }
}

class _PassoEmail extends ConsumerWidget {
  const _PassoEmail({required this.controller, required this.estado});

  final TextEditingController controller;
  final EntrarState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EntrarController controle =
        ref.read(entrarControllerProvider.notifier);

    return Column(
      children: <Widget>[
        const Spacer(),
        const Icon(Icons.kitchen, size: 48),
        const SizedBox(height: 12),
        Text('Despensa', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Sem senha. Mandamos um código para o seu e-mail.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        TextField(
          key: campoEmailKey,
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.go,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            hintText: 'nome@email.com',
            border: OutlineInputBorder(),
          ),
          onChanged: controle.emailChanged,
          onSubmitted: (_) => controle.sendCode(),
        ),
        if (estado.error != null) ...<Widget>[
          const SizedBox(height: 10),
          _Erro(estado.error!),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: botaoEnviarKey,
            onPressed: estado.canSubmitEmail ? controle.sendCode : null,
            child: estado.busy
                ? const _Girando()
                : const Text('Enviar código'),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _PassoCodigo extends ConsumerWidget {
  const _PassoCodigo({
    required this.controller,
    required this.estado,
    required this.onVoltar,
  });

  final TextEditingController controller;
  final EntrarState estado;
  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: estado.busy ? null : onVoltar,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('voltar'),
          ),
        ),
        const SizedBox(height: 24),
        Text('Confira seu e-mail', style: tema.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: tema.textTheme.bodyMedium
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
            children: <InlineSpan>[
              const TextSpan(text: 'Código de 6 dígitos enviado para '),
              TextSpan(
                text: estado.email,
                style: TextStyle(color: tema.colorScheme.onSurface),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _CamposDoCodigo(
          controller: controller,
          comErro: estado.error != null,
          habilitado: !estado.busy,
          onCompleto: (String codigo) =>
              ref.read(entrarControllerProvider.notifier).verify(codigo),
        ),
        const SizedBox(height: 12),
        if (estado.error != null) _Erro(estado.error!),
        if (estado.busy) ...<Widget>[
          const SizedBox(height: 12),
          const Center(child: _Girando()),
        ],
        const Spacer(),
        Center(
          child: TextButton(
            onPressed: estado.busy
                ? null
                : () => ref.read(entrarControllerProvider.notifier).sendCode(),
            child: const Text('Reenviar código'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Seis caixas desenhadas, um campo de texto só por cima delas — assim colar o
/// código de uma vez funciona, e o leitor de tela vê um campo, não seis.
class _CamposDoCodigo extends StatelessWidget {
  const _CamposDoCodigo({
    required this.controller,
    required this.comErro,
    required this.habilitado,
    required this.onCompleto,
  });

  final TextEditingController controller;
  final bool comErro;
  final bool habilitado;
  final ValueChanged<String> onCompleto;

  static const double _altura = 52;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cores = Theme.of(context).colorScheme;
    final String digitos = controller.text;

    return SizedBox(
      height: _altura,
      child: Stack(
        children: <Widget>[
          Row(
            children: List<Widget>.generate(6, (int i) {
              final bool preenchido = i < digitos.length;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 5 ? 0 : 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: comErro
                            ? cores.error
                            : preenchido
                                ? cores.primary
                                : cores.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        preenchido ? digitos[i] : '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: TextField(
              key: campoCodigoKey,
              controller: controller,
              enabled: habilitado,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              onChanged: (String valor) {
                if (valor.length == 6) onCompleto(valor);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro(this.mensagem);

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Text(
      mensagem,
      key: erroKey,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }
}

class _Girando extends StatelessWidget {
  const _Girando();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
