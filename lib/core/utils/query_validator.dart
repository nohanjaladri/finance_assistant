/// query_validator.dart
/// Bertanggung jawab memvalidasi SQL yang di-generate AI
/// agar hanya SELECT yang bisa dieksekusi (Safe Select Only)
library;

class QueryValidator {
  // ✅ Keyword yang DIIZINKAN
  static const _allowedKeywords = [
    'SELECT',
    'FROM',
    'WHERE',
    'GROUP BY',
    'ORDER BY',
    'HAVING',
    'WITH',
    'JOIN',
    'LEFT JOIN',
    'INNER JOIN',
    'LIMIT',
    'OFFSET',
    'AS',
    'ON',
    'AND',
    'OR',
    'NOT',
    'IN',
    'LIKE',
    'BETWEEN',
    'IS',
    'NULL',
    'COUNT',
    'SUM',
    'AVG',
    'MIN',
    'MAX',
    'DISTINCT',
    'CASE',
    'WHEN',
    'THEN',
    'ELSE',
    'END',
    'STRFTIME',
    'DATE',
    'COALESCE',
    'ROUND',
  ];

  // 🚫 Keyword yang DIBLOKIR KERAS
  static const _blockedKeywords = [
    'DELETE',
    'DROP',
    'UPDATE',
    'INSERT',
    'ALTER',
    'CREATE',
    'ATTACH',
    'DETACH',
    'PRAGMA',
    'VACUUM',
    'REINDEX',
    'REPLACE',
    'TRUNCATE',
    'EXEC',
    'EXECUTE',
  ];

  // 🏦 Tabel yang DIIZINKAN untuk di-query
  static const _allowedTables = ['transactions', 'messages'];

  /// Validasi utama — mengembalikan [QueryValidationResult]
  static QueryValidationResult validate(String sql) {
    final normalized = sql.trim().toUpperCase();

    // 1. Harus diawali SELECT atau WITH (untuk CTE)
    if (!normalized.startsWith('SELECT') && !normalized.startsWith('WITH')) {
      return QueryValidationResult.fail(
        'Query harus diawali dengan SELECT atau WITH.',
      );
    }

    // 2. Cek blacklist keyword
    for (final blocked in _blockedKeywords) {
      // Gunakan word boundary agar "SELECTED" tidak ter-flag
      final pattern = RegExp(r'\b' + blocked + r'\b');
      if (pattern.hasMatch(normalized)) {
        return QueryValidationResult.fail(
          'Query mengandung perintah terlarang: $blocked',
        );
      }
    }

    // 3. Cek tabel yang diakses
    final tablePattern = RegExp(
      r'\bFROM\s+(\w+)|\bJOIN\s+(\w+)',
      caseSensitive: false,
    );
    final tableMatches = tablePattern.allMatches(sql);
    for (final match in tableMatches) {
      final tableName = (match.group(1) ?? match.group(2) ?? '').toLowerCase();
      if (tableName.isNotEmpty && !_allowedTables.contains(tableName)) {
        return QueryValidationResult.fail(
          'Akses ke tabel "$tableName" tidak diizinkan.',
        );
      }
    }

    // 4. Tidak boleh ada semicolon ganda (SQL injection via stacked queries)
    final cleanSql = sql.replaceAll(
      RegExp(r"'[^']*'"),
      '',
    ); // hapus string literal
    if (cleanSql.contains(';') && cleanSql.indexOf(';') < cleanSql.length - 1) {
      return QueryValidationResult.fail('Multiple statements tidak diizinkan.');
    }

    return QueryValidationResult.ok(sql.trim());
  }
}

/// Hasil validasi query
class QueryValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? sanitizedQuery;

  QueryValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.sanitizedQuery,
  });

  factory QueryValidationResult.ok(String query) =>
      QueryValidationResult._(isValid: true, sanitizedQuery: query);

  factory QueryValidationResult.fail(String message) =>
      QueryValidationResult._(isValid: false, errorMessage: message);
}
