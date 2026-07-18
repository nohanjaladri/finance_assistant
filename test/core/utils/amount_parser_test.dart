import 'package:flutter_test/flutter_test.dart';
import 'package:finance_assistant/core/utils/amount_parser.dart';

void main() {
  group('AmountParser Tests', () {
    test('cleanNumberString cleans formatting dots and commas correctly', () {
      expect(AmountParser.cleanNumberString('50.000'), '50000');
      expect(AmountParser.cleanNumberString('1.500.000'), '1500000');
      expect(AmountParser.cleanNumberString('50,000'), '50000');
      expect(AmountParser.cleanNumberString('1,500,000'), '1500000');
    });

    test('parseAmount parses basic numbers', () {
      expect(AmountParser.parseAmount('50000'), 50000);
      expect(AmountParser.parseAmount('100000'), 100000);
    });

    test('parseAmount parses Rp prefix', () {
      expect(AmountParser.parseAmount('Rp 50.000'), 50000);
      expect(AmountParser.parseAmount('rp. 100000'), 100000);
      expect(AmountParser.parseAmount('Rp. 1.500.000'), 1500000);
    });

    test('parseAmount parses k/rb/ribu suffixes', () {
      expect(AmountParser.parseAmount('50k'), 50000);
      expect(AmountParser.parseAmount('50 k'), 50000);
      expect(AmountParser.parseAmount('50rb'), 50000);
      expect(AmountParser.parseAmount('50 rb'), 50000);
      expect(AmountParser.parseAmount('50 ribu'), 50000);
      expect(AmountParser.parseAmount('12.5k'), 12500);
      expect(AmountParser.parseAmount('12,5 rb'), 12500);
    });

    test('parseAmount parses jt/juta suffixes', () {
      expect(AmountParser.parseAmount('1jt'), 1000000);
      expect(AmountParser.parseAmount('1.5 jt'), 1500000);
      expect(AmountParser.parseAmount('2 juta'), 2000000);
      expect(AmountParser.parseAmount('2.25 juta'), 2250000);
    });

    test('parseAmount parses Indonesian words', () {
      expect(AmountParser.parseAmount('sepuluh ribu'), 10000);
      expect(AmountParser.parseAmount('lima puluh ribu'), 50000);
      expect(AmountParser.parseAmount('seratus ribu'), 100000);
      expect(AmountParser.parseAmount('seribu'), 1000);
      expect(AmountParser.parseAmount('sejuta'), 1000000);
      expect(AmountParser.parseAmount('dua juta lima ratus ribu'), 2500000);
    });

    test('parseAmount returns null for invalid input', () {
      expect(AmountParser.parseAmount('tidak ada angka'), null);
      expect(AmountParser.parseAmount('hello world'), null);
    });
  });
}
