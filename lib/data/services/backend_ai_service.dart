import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BackendAiResponse {
  final String reply;
  final String intent;
  final Map<String, dynamic> extractedData;
  final List<String> logs;

  BackendAiResponse({
    required this.reply,
    required this.intent,
    required this.extractedData,
    required this.logs,
  });

  factory BackendAiResponse.fromJson(Map<String, dynamic> json) {
    return BackendAiResponse(
      reply: json['reply'] as String? ?? 'Gagal memproses.',
      intent: json['intent'] as String? ?? 'UNKNOWN',
      extractedData: json['extracted_data'] as Map<String, dynamic>? ?? {},
      logs: (json['logs'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

class BackendAiService {
  final Dio _dio = Dio();
  final String baseUrl = "https://finance-assistant-gilt.vercel.app";

  Future<BackendAiResponse?> sendMessage(String message, {String userId = "default_user"}) async {
    debugPrint("=== AI PROCESS START ===");
    debugPrint("[AI INPUT] User ID: $userId");
    debugPrint("[AI INPUT] Message: \"$message\"");
    debugPrint("[AI INPUT] API URL: $baseUrl/chat");
    try {
      final response = await _dio.post(
        "$baseUrl/chat",
        data: {
          "message": message,
          "user_id": userId,
        },
      );

      debugPrint("[AI HTTP STATUS] Status Code: ${response.statusCode}");
      if (response.statusCode == 200 && response.data != null) {
        debugPrint("[AI HTTP RESPONSE] Raw Data: ${response.data}");
        final aiResponse = BackendAiResponse.fromJson(response.data as Map<String, dynamic>);
        debugPrint("[AI OUTPUT] Reply: \"${aiResponse.reply}\"");
        debugPrint("[AI OUTPUT] Intent: \"${aiResponse.intent}\"");
        debugPrint("[AI OUTPUT] Extracted Data: ${aiResponse.extractedData}");
        debugPrint("=== AI PROCESS END ===");
        return aiResponse;
      } else {
        debugPrint("[AI HTTP RESPONSE] Failed status or empty data: ${response.data}");
      }
    } catch (e) {
      debugPrint("=== AI PROCESS ERROR ===");
      debugPrint("[AI ERROR] BackendAiService error: $e");
    }
    debugPrint("=== AI PROCESS END (WITH NULL RESPONSE) ===");
    return null;
  }

  Future<String?> transcribeAudio(String filePath) async {
    try {
      debugPrint("[STT WHISPER] Transcribing file: $filePath");
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'audio.m4a'),
      });
      final response = await _dio.post(
        "$baseUrl/transcribe",
        data: formData,
      );
      if (response.statusCode == 200 && response.data != null) {
        debugPrint("[STT WHISPER] Response: ${response.data}");
        return response.data['text'] as String?;
      }
    } catch (e) {
      debugPrint("[STT WHISPER] Error transcribing audio: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> simulateEntryAgent(String message) async {
    try {
      final response = await _dio.post("$baseUrl/agent/entry", data: {"message": message});
      if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error Entry Agent Sim: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> simulateAnalystAgent(String query, String userId) async {
    try {
      final response = await _dio.post("$baseUrl/agent/analyst", data: {"message": query, "user_id": userId});
      if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error Analyst Agent Sim: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> simulateBudgetAgent(String userId) async {
    try {
      final response = await _dio.get("$baseUrl/agent/budget/$userId");
      if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error Budget Agent Sim: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> simulateSearchAgent(String message) async {
    try {
      final response = await _dio.post("$baseUrl/agent/search", data: {"message": message});
      if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Error Search Agent Sim: $e");
    }
    return null;
  }
}
