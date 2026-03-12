class AmountParser {
  static const Map<String, int> _wordNumbers = {
    'nol': 0,
    'satu': 1,
    'dua': 2,
    'tiga': 3,
    'empat': 4,
    'lima': 5,
    'enam': 6,
    'tujuh': 7,
    'delapan': 8,
    'sembilan': 9,
    'sepuluh': 10,
    'sebelas': 11,
    'dua belas': 12,
    'tiga belas': 13,
    'empat belas': 14,
    'lima belas': 15,
    'enam belas': 16,
    'tujuh belas': 17,
    'delapan belas': 18,
    'sembilan belas': 19,
    'dua puluh': 20,
    'tiga puluh': 30,
    'empat puluh': 40,
    'lima puluh': 50,
    'enam puluh': 60,
    'tujuh puluh': 70,
    'delapan puluh': 80,
    'sembilan puluh': 90,
    'seratus': 100,
    'dua ratus': 200,
    'tiga ratus': 300,
    'empat ratus': 400,
    'lima ratus': 500,
    'enam ratus': 600,
    'tujuh ratus': 700,
    'delapan ratus': 800,
    'sembilan ratus': 900,
    'seribu': 1000,
    'sejuta': 1000000,
  };

  static int? _wordToInt(String word) {
    word = word.trim();
    if (word.isEmpty) return null;
    if (_wordNumbers.containsKey(word)) return _wordNumbers[word];
    for (final tens in [20, 30, 40, 50, 60, 70, 80, 90]) {
      final tw = _wordNumbers.entries
          .firstWhere(
            (e) => e.value == tens,
            orElse: () => const MapEntry('', 0),
          )
          .key;
      if (tw.isEmpty) continue;
      if (word.startsWith(tw)) {
        final rest = word.substring(tw.length).trim();
        if (rest.isEmpty) return tens;
        final ones = _wordNumbers[rest];
        if (ones != null && ones < 10) return tens + ones;
      }
    }
    return int.tryParse(word);
  }

  static int? _parseWordAmount(String text) {
    final lower = text.toLowerCase();
    final jutaReg = RegExp(
      r'(?:(\d+)|([a-z]+?(?:\s+[a-z]+?)*?))\s+juta(?:\s+(?:(\d+)|([a-z]+?(?:\s+[a-z]+?)*?))\s+ribu)?',
    );
    final jutaMatch = jutaReg.firstMatch(lower);
    if (jutaMatch != null) {
      int? jv =
          int.tryParse(jutaMatch.group(1) ?? '') ??
          _wordToInt(jutaMatch.group(2) ?? '');
      if (jv != null && jv > 0) {
        int total = jv * 1000000;
        final rs = (jutaMatch.group(3) ?? jutaMatch.group(4) ?? '').trim();
        if (rs.isNotEmpty) {
          int? rv = int.tryParse(rs) ?? _wordToInt(rs);
          if (rv != null) total += rv * 1000;
        }
        return total;
      }
    }
    final ratusRibuReg = RegExp(
      r'(?:(\d+)|([a-z]+(?:\s+[a-z]+)*))\s+ratus\s+ribu',
    );
    final rrm = ratusRibuReg.firstMatch(lower);
    if (rrm != null) {
      int? v =
          int.tryParse(rrm.group(1) ?? '') ?? _wordToInt(rrm.group(2) ?? '');
      if (v != null && v > 0) return v * 100000;
    }
    final ribuReg = RegExp(
      r'(?:(\d+(?:[.,]\d+)?)|([a-z]+(?:\s+[a-z]+)*))\s+ribu',
    );
    final rm = ribuReg.firstMatch(lower);
    if (rm != null) {
      final raw = rm.group(1);
      if (raw != null) {
        final v = double.tryParse(raw.replaceAll(',', '.'));
        if (v != null && v > 0) return (v * 1000).round();
      }
      int? v = _wordToInt(rm.group(2) ?? '');
      if (v != null && v > 0) return v * 1000;
    }
    final ratusReg = RegExp(r'(?:(\d+)|([a-z]+(?:\s+[a-z]+)*))\s+ratus');
    final ratm = ratusReg.firstMatch(lower);
    if (ratm != null) {
      int? v =
          int.tryParse(ratm.group(1) ?? '') ?? _wordToInt(ratm.group(2) ?? '');
      if (v != null && v > 0) return v * 100;
    }
    for (final e in _wordNumbers.entries) {
      if (lower.contains(e.key) && e.value > 0) return e.value;
    }
    return null;
  }

  static String cleanNumberString(String raw) {
    final dc = '.'.allMatches(raw).length;
    final cc = ','.allMatches(raw).length;
    if (dc == 0 && cc == 0) return raw;
    if (dc > 1) return raw.replaceAll('.', '');
    if (cc > 1) return raw.replaceAll(',', '');
    if (dc == 1 && cc == 0) {
      final parts = raw.split('.');
      if (parts.last.length == 3 && parts.first.length <= 3)
        return raw.replaceAll('.', '');
      return parts.first;
    }
    if (cc == 1 && dc == 0) {
      final parts = raw.split(',');
      if (parts.last.length == 3 && parts.first.length <= 3)
        return raw.replaceAll(',', '');
      return parts.first;
    }
    if (dc == 1 && cc == 1) {
      final di = raw.indexOf('.');
      final ci = raw.indexOf(',');
      if (di < ci) return raw.replaceAll('.', '').split(',').first;
      return raw.replaceAll(',', '').split('.').first;
    }
    return raw.replaceAll(RegExp(r'[.,]'), '');
  }

  static int? parseAmount(String text) {
    final lower = text.toLowerCase().trim();
    final jutaDigit = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:juta|jt\b)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (jutaDigit != null) {
      final v = double.tryParse(jutaDigit.group(1)!.replaceAll(',', '.'));
      if (v != null && v > 0) return (v * 1000000).round();
    }
    final ribuDigit = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:rb|ribu|k\b)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (ribuDigit != null) {
      final v = double.tryParse(ribuDigit.group(1)!.replaceAll(',', '.'));
      if (v != null && v > 0) return (v * 1000).round();
    }
    final rp = RegExp(
      r'rp\.?\s*([\d.,]+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (rp != null) {
      final v = int.tryParse(cleanNumberString(rp.group(1)!));
      if (v != null && v > 0) return v;
    }
    final num = RegExp(r'\b(\d[\d.,]*\d|\d+)\b').firstMatch(lower);
    if (num != null) {
      final v = int.tryParse(cleanNumberString(num.group(1)!));
      if (v != null && v > 0) return v;
    }
    return _parseWordAmount(lower);
  }
}
