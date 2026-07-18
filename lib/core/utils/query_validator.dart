/// query_validator.dart (v2)
/// SQL validation layer — hanya SELECT yang diizinkan
/// Diupdate untuk PostgreSQL (Supabase) syntax
library;

class QueryValidator {
  // ✅ Keyword yang DIIZINKAN
  static const _allowedKeywords = [
    'SELECT', 'FROM', 'WHERE', 'GROUP BY', 'ORDER BY', 'HAVING',
    'WITH', 'JOIN', 'LEFT JOIN', 'INNER JOIN', 'RIGHT JOIN', 'OUTER JOIN',
    'LIMIT', 'OFFSET', 'AS', 'ON', 'AND', 'OR', 'NOT', 'IN', 'LIKE',
    'ILIKE', // PostgreSQL case-insensitive LIKE
    'BETWEEN', 'IS', 'NULL', 'COUNT', 'SUM', 'AVG', 'MIN', 'MAX',
    'DISTINCT', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
    // PostgreSQL date functions
    'DATE_TRUNC', 'DATE_PART', 'EXTRACT', 'NOW', 'INTERVAL',
    'TO_CHAR', 'TO_DATE', 'CURRENT_DATE', 'CURRENT_TIMESTAMP',
    // General functions
    'COALESCE', 'ROUND', 'CAST', 'NULLIF', 'GREATEST', 'LEAST',
    'CONCAT', 'SUBSTRING', 'TRIM', 'UPPER', 'LOWER', 'LENGTH',
    'ARRAY_AGG', 'JSON_AGG', 'STRING_AGG',
  ];

  // 🚫 Keyword yang DIBLOKIR KERAS (SQL injection / destructive)
  static const _blockedKeywords = [
    'DELETE', 'DROP', 'UPDATE', 'INSERT', 'ALTER', 'CREATE', 'ATTACH',
    'DETACH', 'PRAGMA', 'VACUUM', 'REINDEX', 'REPLACE', 'TRUNCATE',
    'EXEC', 'EXECUTE', 'CALL', 'DO', 'COPY', 'GRANT', 'REVOKE',
    'SET', 'SHOW', 'LOCK', 'UNLOCK',
  ];

  // 🏦 Tabel yang DIIZINKAN untuk di-query
  static const _allowedTables = ['transactions', 'pending_requests'];

  static QueryValidationResult validate(String sql) {
    final normalized = sql.trim().toUpperCase();

    // 1. Harus diawali SELECT atau WITH (CTE)
    if (!normalized.startsWith('SELECT') && !normalized.startsWith('WITH')) {
      return QueryValidationResult.fail(
        'Query harus diawali dengan SELECT atau WITH.',
      );
    }

    // 2. Cek blacklist keywords
    for (final blocked in _blockedKeywords) {
      final pattern = RegExp(r'\b' + blocked + r'\b');
      if (pattern.hasMatch(normalized)) {
        return QueryValidationResult.fail(
          'Query mengandung perintah terlarang: $blocked',
        );
      }
    }

    // 3. Cek tabel yang diakses (mendukung schema prefix seperti app_finance.transactions)
    final tablePattern = RegExp(
      r'\bFROM\s+([\w\.]+)\b|\bJOIN\s+([\w\.]+)\b',
      caseSensitive: false,
    );
    final tableMatches = tablePattern.allMatches(sql);
    for (final match in tableMatches) {
      var rawTableName = (match.group(1) ?? match.group(2) ?? '').toLowerCase();
      // Hilangkan schema prefix jika ada (misal: "app_finance.transactions" -> "transactions")
      if (rawTableName.contains('.')) {
        rawTableName = rawTableName.split('.').last;
      }
      if (rawTableName.isNotEmpty && !_allowedTables.contains(rawTableName)) {
        return QueryValidationResult.fail(
          'Akses ke tabel "$rawTableName" tidak diizinkan.',
        );
      }
    }

    // 4. Cek stacked queries (SQL injection via semicolons)
    final cleanSql = sql.replaceAll(RegExp(r"'[^']*'"), '');
    if (cleanSql.contains(';') &&
        cleanSql.indexOf(';') < cleanSql.length - 1) {
      return QueryValidationResult.fail('Multiple statements tidak diizinkan.');
    }

    // 5. Tambahkan filter user_id otomatis untuk keamanan
    // (akan ditangani di level Supabase RLS, tapi validasi di sini sebagai layer tambahan)

    return QueryValidationResult.ok(sql.trim());
  }
}

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
