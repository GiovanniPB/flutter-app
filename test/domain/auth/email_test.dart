import 'package:despensa/domain/auth/email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Email.tryParse', () {
    test('normaliza espaços nas pontas e caixa', () {
      expect(Email.tryParse('  Giovanni@Exemplo.COM  ')?.value,
          'giovanni@exemplo.com');
    });

    test('aceita endereço comum', () {
      expect(Email.tryParse('ana.silva+lista@exemplo.com.br')?.value,
          'ana.silva+lista@exemplo.com.br');
    });

    test('recusa o que não tem chance de ser endereço', () {
      const List<String> invalidos = <String>[
        '',
        '   ',
        'ana',
        'ana@',
        '@exemplo.com',
        'ana@exemplo',
        'ana@exemplo.c',
        'a na@exemplo.com',
        'ana@exemplo .com',
        'ana@@exemplo.com',
      ];
      for (final String cru in invalidos) {
        expect(Email.tryParse(cru), isNull, reason: 'aceitou "$cru"');
      }
    });

    test('dois iguais são iguais depois de normalizar', () {
      expect(Email.tryParse(' A@B.CO '), Email.tryParse('a@b.co'));
    });
  });
}
