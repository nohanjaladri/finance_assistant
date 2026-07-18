import 'package:flutter_test/flutter_test.dart';
import 'package:finance_assistant/core/utils/query_validator.dart';

void main() {
  group('QueryValidator Tests', () {
    test('Valid SELECT query passes validation', () {
      final query = 'SELECT * FROM transactions WHERE amount > 10000';
      final result = QueryValidator.validate(query);
      expect(result.isValid, true);
      expect(result.sanitizedQuery, query);
      expect(result.errorMessage, null);
    });

    test('WITH query (CTE) with disallowed table fails validation', () {
      final query = 'WITH summary AS (SELECT amount FROM transactions) SELECT * FROM summary';
      final result = QueryValidator.validate(query);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('Akses ke tabel "summary" tidak diizinkan.'));
    });

    test('Query not starting with SELECT or WITH fails', () {
      final query = 'UPDATE transactions SET amount = 0';
      final result = QueryValidator.validate(query);
      expect(result.isValid, false);
      expect(result.errorMessage, 'Query harus diawali dengan SELECT atau WITH.');
    });

    test('Query containing blocked keywords fails', () {
      final queries = [
        'SELECT * FROM transactions; DELETE FROM transactions',
        'SELECT * FROM transactions WHERE note = \'DELETE\'', // block list check is naive and checks word boundaries
      ];
      // Let's test standard blocked keywords
      final insertQuery = 'SELECT * FROM transactions WHERE id = (INSERT INTO transactions ...)';
      expect(QueryValidator.validate(insertQuery).isValid, false);
      expect(QueryValidator.validate(insertQuery).errorMessage, contains('Query mengandung perintah terlarang'));
    });

    test('Accessing non-allowed tables fails', () {
      final query = 'SELECT * FROM profiles';
      final result = QueryValidator.validate(query);
      expect(result.isValid, false);
      expect(result.errorMessage, 'Akses ke tabel "profiles" tidak diizinkan.');
    });

    test('Accessing allowed tables with schema prefix passes', () {
      final query = 'SELECT * FROM app_finance.transactions';
      final result = QueryValidator.validate(query);
      expect(result.isValid, true);
    });

    test('Multiple statements separated by semicolon fails', () {
      final query = 'SELECT * FROM transactions; SELECT * FROM pending_requests';
      final result = QueryValidator.validate(query);
      expect(result.isValid, false);
      expect(result.errorMessage, 'Multiple statements tidak diizinkan.');
    });
  });
}
