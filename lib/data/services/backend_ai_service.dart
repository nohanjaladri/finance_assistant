import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BackendAiResponse {
  final String reply;
  final String intent;
  final Map<String, dynamic> extractedData;

  BackendAiResponse({
    required this.reply,
    required this.intent,
    required this.extractedData,
  });

  factory BackendAiResponse.fromJson(Map<String, dynamic> json) {
    return BackendAiResponse(
      reply: json['reply'] as String? ?? 'Gagal memproses.',
      intent: json['intent'] as String? ?? 'UNKNOWN',
      extractedData: json['extracted_data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class BackendAiService {
  final Dio _dio = Dio();
  final String baseUrl = "https://finance-assistant-gilt.vercel.app";

  Future<BackendAiResponse?> sendMessage(String message, {String userId = "default_user"}) async {
    try {
      final response = await _dio.post(
        "$baseUrl/chat",
        data: {
          "message": message,
          "user_id": userId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return BackendAiResponse.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("BackendAiService error: $e");
    }
    return null;
  }
}
