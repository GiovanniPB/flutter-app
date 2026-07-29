# Despensa

Controle de despensa doméstica: mostra em segundos o que está perto de vencer e
torna o cadastro de compras rápido o bastante para não ser abandonado.

- **Como trabalhar aqui:** [`AGENTS.md`](AGENTS.md)
- **O que é o produto:** [`docs/product.md`](docs/product.md)
- **Por que as coisas são assim:** [`docs/adr/`](docs/adr)
- **Onde estamos:** [`docs/state.md`](docs/state.md)

## Rodar

```bash
fvm flutter pub get
cp env/dev.example.json env/dev.json   # preencher com o projeto Supabase
fvm flutter run -d macos --dart-define-from-file=env/dev.json
```

Flutter fixado em 3.44.6 via [`fvm`](https://fvm.app) (`.fvmrc`).
