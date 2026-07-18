/// app_config.dart
/// Konfigurasi global aplikasi untuk mendukung satu database multi-schema
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Nama schema PostgreSQL kustom untuk aplikasi ini
  static String get schema => dotenv.env['APP_SCHEMA'] ?? 'app_finance';
}
