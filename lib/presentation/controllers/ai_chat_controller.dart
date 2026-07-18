/// ai_chat_controller.dart
/// Controller yang mengekstrak seluruh logika AI dari HomeScreen
/// Memproses input user, memanggil AI, mengeksekusi tool calls
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/utils/amount_parser.dart';
import '../../core/utils/query_validator.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/voice_service.dart';
import '../providers/finance_provider.dart';

class AiChatController {
  final FinanceProvider financeProvider;
  final VoiceService voiceService;

  AiChatController({required this.financeProvider, required this.voiceService});

  @visibleForTesting
  AiService? aiOverride;

  AiService get _ai => aiOverride ?? AiService(
    groqApiKey: dotenv.env['GROQ_API_KEY'] ?? '',
    geminiApiKey: dotenv.env['GEMINI_API_KEY'],
  );

  // ============================================================
  // BUILD SYSTEM CONTEXT
  // ============================================================

  Future<String> _buildPendingContext() async {
    final pendings = await financeProvider.getAllPending();
    if (pendings.isEmpty) return "Tidak ada transaksi tertunda.";

    final sb = StringBuffer();
    sb.writeln("=== DAFTAR TRANSAKSI TERTUNDA ===");
    for (var p in pendings) {
      final nama = p.nama ?? 'Belum ada';
      final nominal = p.nominal != null ? "Rp ${p.nominal}" : "Belum ada";
      sb.writeln(
        "[ID: ${p.id}] Barang: $nama | Harga: $nominal | Field Kurang: ${p.missingFields} | Pertanyaan: '${p.aiQuestion}'",
      );
    }
    sb.writeln("=================================");
    return sb.toString();
  }

  String _buildRecentTransactionsContext() {
    final chatType = financeProvider.activeChatType;
    final txs = (chatType == 'sharing') ? financeProvider.sharedTransactions : financeProvider.allTransactions;
    if (txs.isEmpty) return "Belum ada transaksi tercatat.";

    final sb = StringBuffer();
    for (var tx in txs.take(10)) {
      final timeStr = "${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}";
      final typeStr = tx.type == TransactionType.income ? 'IN' : 'OUT';
      sb.writeln("- [$typeStr] ${tx.note}: Rp ${tx.amount} (${tx.paymentMethod.value}) pada $timeStr");
    }
    return sb.toString();
  }

  // ============================================================
  // PROCESS USER MESSAGE — Main entry point
  // ============================================================

  Future<void> processMessage({
    required String userText,
    required bool isChatVisible,
  }) async {
    if (userText.trim().isEmpty) return;

    // Tambahkan pesan user ke chat
    await financeProvider.addMessage(userText, false);
    financeProvider.setAiThinking(true);

    try {
      final pendingContext = await _buildPendingContext();
      final recentTxsCtx = _buildRecentTransactionsContext();
      final chatType = financeProvider.activeChatType;
      String chatTypeInstruction = '';
      if (chatType == 'tunai') {
        chatTypeInstruction = '\n═══════════════════════════════════\nKONTEKS TABS CHAT SAAT INI:\n═══════════════════════════════════\nUser sedang berada di tab obrolan TUNAI (CASH). Secara default, jika merekam transaksi, gunakan payment_method: "tunai" kecuali jika user secara spesifik menyebutkan metode pembayaran lain.';
      } else if (chatType == 'non_tunai') {
        chatTypeInstruction = '\n═══════════════════════════════════\nKONTEKS TABS CHAT SAAT INI:\n═══════════════════════════════════\nUser sedang berada di tab obrolan NON-TUNAI (E-WALLET/DIGITAL/BANK). Secara default, jika merekam transaksi, gunakan payment_method: "non_tunai" kecuali jika user secara spesifik menyebutkan metode pembayaran lain.';
      } else if (chatType == 'sharing') {
        chatTypeInstruction = '\n═══════════════════════════════════\nKONTEKS TABS CHAT SAAT INI:\n═══════════════════════════════════\nUser sedang berada di tab obrolan SHARING (DOMPET BERSAMA). Transaksi yang dicatat akan dibagikan dengan anggota ruangan.';
      }

      final systemPrompt = _ai.buildSystemPrompt(
        pendingContext: pendingContext,
        financialSummary: financeProvider.financialSummary,
        recentTransactionsContext: recentTxsCtx,
      ) + chatTypeInstruction;

      // Bangun riwayat pesan untuk konteks AI (max 8 pesan terakhir)
      final recentHistory = financeProvider.chatHistory
          .where((m) => m['query_result'] == null && m['receipt_data'] == null)
          .toList()
          .reversed
          .take(8)
          .toList()
          .reversed
          .toList();

      final List<Map<String, dynamic>> messages = [
        {"role": "system", "content": systemPrompt},
        ...recentHistory.map(
          (m) => <String, dynamic>{
            "role": (m['is_ai'] as bool? ?? false) ? "assistant" : "user",
            "content": m['text'] as String? ?? "",
          },
        ),
        {"role": "user", "content": userText},
      ];

      final aiResponse = await _ai.sendMessage(messages);

      if (aiResponse.toolCalls != null && aiResponse.toolCalls!.isNotEmpty) {
        await _executeToolCalls(
          toolCalls: aiResponse.toolCalls!,
          agentMessage: {
            'content': aiResponse.content,
            'tool_calls': aiResponse.toolCalls,
          },
          userText: userText,
          systemPrompt: systemPrompt,
          isChatVisible: isChatVisible,
        );
      } else {
        final content =
            aiResponse.content ??
            "Saya tidak bisa memproses permintaan Anda saat ini.";
        await financeProvider.addMessage(content, true);
        if (isChatVisible) voiceService.speak(content);
      }
    } catch (e) {
      debugPrint("processMessage error: $e");
      const errMsg = "Maaf, gagal memproses permintaan. Coba lagi ya! 🙏";
      await financeProvider.addMessage(errMsg, true);
    } finally {
      financeProvider.setAiThinking(false);
    }
  }

  // ============================================================
  // EXECUTE TOOL CALLS
  // ============================================================

  Future<void> _executeToolCalls({
    required List<dynamic> toolCalls,
    required Map<String, dynamic> agentMessage,
    required String userText,
    required String systemPrompt,
    required bool isChatVisible,
  }) async {
    final recordedTxs = <Map<String, dynamic>>[];
    final interactiveQuestions = <String>[];
    final processedSignatures = <String>{};
    bool hasUpdate = false;
    bool hasCancel = false;
    bool intercepted = false;

    // Cek apakah user menyebut nominal
    final userAmount = AmountParser.parseAmount(userText);
    final userHasDigits =
        RegExp(r'\d').hasMatch(userText) || userAmount != null;

    final filteredCalls = List<dynamic>.from(toolCalls);
    final completedNotes = <String>{};

    for (final call in toolCalls) {
      final toolName = call['function']['name'] as String;
      Map<String, dynamic> args = {};
      try {
        final raw = call['function']['arguments'];
        args =
            jsonDecode(raw is String ? raw : jsonEncode(raw))
                as Map<String, dynamic>;
      } catch (_) {}

      if (toolName == 'record_transaction') {
        final note = args['note']?.toString().toLowerCase() ?? '';
        if (note.isNotEmpty) completedNotes.add(note);
      } else if (toolName == 'update_pending_state') {
        final missing = (args['remaining_missing_fields'] as List?) ?? [];
        final updatedAmount = args['updated_amount'];
        if (missing.isEmpty && updatedAmount != null) {
          final note = args['updated_note']?.toString().toLowerCase() ?? '';
          if (note.isNotEmpty) completedNotes.add(note);
        }
      }
    }

    if (completedNotes.isNotEmpty) {
      filteredCalls.removeWhere((call) {
        final toolName = call['function']['name'] as String;
        if (toolName == 'create_pending_state') {
          Map<String, dynamic> args = {};
          try {
            final raw = call['function']['arguments'];
            args =
                jsonDecode(raw is String ? raw : jsonEncode(raw))
                    as Map<String, dynamic>;
          } catch (_) {}
          final partialNote =
              args['partial_note']?.toString().toLowerCase() ?? '';
          if (partialNote.isEmpty ||
              completedNotes.contains(partialNote) ||
              completedNotes.any(
                (c) => c.contains(partialNote) || partialNote.contains(c),
              )) {
            debugPrint(
              "Filtering out redundant create_pending_state for: $partialNote",
            );
            return true;
          }
        }
        return false;
      });
    }

    for (final call in filteredCalls) {
      final toolName = call['function']['name'] as String;
      final toolCallId = call['id'] as String? ?? '';
      Map<String, dynamic> args = {};
      try {
        final raw = call['function']['arguments'];
        args =
            jsonDecode(raw is String ? raw : jsonEncode(raw))
                as Map<String, dynamic>;
      } catch (e) {
        debugPrint("Error parsing tool arguments: $e");
      }

      debugPrint("Executing tool: $toolName with args: $args");

      await _executeSingleTool(
        toolName: toolName,
        toolCallId: toolCallId,
        args: args,
        userText: userText,
        userHasDigits: userHasDigits,
        systemPrompt: systemPrompt,
        agentMessage: agentMessage,
        recordedTxs: recordedTxs,
        interactiveQuestions: interactiveQuestions,
        processedSignatures: processedSignatures,
        interceptedRef: (v) => intercepted = v,
        hasUpdateRef: (v) => hasUpdate = v,
        hasCancelRef: (v) => hasCancel = v,
        isChatVisible: isChatVisible,
      );
    }

    // Post-processing: tampilkan struk jika ada transaksi
    if (recordedTxs.isNotEmpty) {
      await financeProvider.addMessage("Transaksi berhasil dicatat! ✅", true);
      await financeProvider.addMessage(
        "RECEIPT_DATA",
        true,
        receiptData: {'transactions': recordedTxs},
      );
      if (isChatVisible) voiceService.speak("Transaksi berhasil dicatat.");
    }

    if (hasUpdate) {
      await financeProvider.addMessage(
        "Data transaksi berhasil diperbarui! ✅",
        true,
      );
    }
    if (hasCancel) {
      await financeProvider.addMessage(
        "Transaksi tertunda dibatalkan. ✅",
        true,
      );
    }

    if (interactiveQuestions.isNotEmpty) {
      final q = interactiveQuestions.first;
      await financeProvider.addMessage(q, true);
      if (isChatVisible) voiceService.speak(q);
    } else if (intercepted && recordedTxs.isEmpty) {
      await financeProvider.addMessage("Berapa nominalnya?", true);
    }

    // Refresh data setelah semua tool selesai
    await financeProvider.refreshAll();
  }

  Future<void> _executeSingleTool({
    required String toolName,
    required String toolCallId,
    required Map<String, dynamic> args,
    required String userText,
    required bool userHasDigits,
    required String systemPrompt,
    required Map<String, dynamic> agentMessage,
    required List<Map<String, dynamic>> recordedTxs,
    required List<String> interactiveQuestions,
    required Set<String> processedSignatures,
    required Function(bool) interceptedRef,
    required Function(bool) hasUpdateRef,
    required Function(bool) hasCancelRef,
    required bool isChatVisible,
  }) async {
    switch (toolName) {
      // ─────────────────────────────────────────────────────
      case 'record_transaction':
        final rawAmount = args['amount']?.toString() ?? '';
        final amount =
            int.tryParse(AmountParser.cleanNumberString(rawAmount)) ??
            AmountParser.parseAmount(rawAmount) ??
            0;

        if (amount <= 0) {
          interceptedRef(true);
          final note = args['note'] as String? ?? 'Transaksi';
          final question = "Berapa nominal/harga untuk $note?";
          final pmStr = args['payment_method'] as String? ?? 'tunai';
          final pm = pmStr == 'non_tunai'
              ? PaymentMethod.nonTunai
              : PaymentMethod.tunai;
          await financeProvider.savePending(
            originalInput: userText,
            nama: note,
            nominal: null,
            aiQuestion: question,
            reason: "User tidak menyebutkan nominal",
            category: args['category'] as String? ?? 'Other',
            type: args['type'] as String? ?? 'OUT',
            paymentMethod: pm,
            missingFields: ['amount'],
          );
          interactiveQuestions.add(question);
          return;
        }

        // Anti-halusinasi: jika AI memberikan nominal tapi user tidak
        if (!userHasDigits && amount > 0) {
          interceptedRef(true);
          final note = args['note'] as String? ?? 'Item';
          await financeProvider.savePending(
            originalInput: userText,
            nama: note,
            nominal: null,
            aiQuestion: "Berapa nominal untuk $note?",
            reason:
                "Anti-halusinasi: AI mendapat harga tapi user tidak menyebutnya",
            category: args['category'] as String? ?? 'Other',
            type: args['type'] as String? ?? 'OUT',
            paymentMethod: PaymentMethod.tunai,
            missingFields: ['amount'],
          );
          return;
        }

        if (amount > 0) {
          final note = args['note'] as String? ?? 'Transaksi';
          final sig = "${note.toLowerCase()}_$amount";
          if (!processedSignatures.contains(sig)) {
            processedSignatures.add(sig);
            final type = args['type'] as String? ?? 'OUT';
            final category = args['category'] as String? ?? 'Other';
            final pmStr = args['payment_method'] as String? ?? 'tunai';
            final pm = pmStr == 'non_tunai'
                ? PaymentMethod.nonTunai
                : PaymentMethod.tunai;

            await financeProvider.addTransaction(
              amount: amount,
              note: note,
              type: type,
              category: category,
              paymentMethod: pm,
            );
            recordedTxs.add({
              'note': note,
              'amount': amount,
              'type': type,
              'payment_method': pm.label,
            });

            // Clean up any matching pending request
            try {
              final pendings = await financeProvider.getAllPending();
              final noteLower = note.toLowerCase();
              for (final p in pendings) {
                final pId = p.id;
                final pName = p.nama?.toLowerCase() ?? '';
                if (pId != null &&
                    pName.isNotEmpty &&
                    (noteLower.contains(pName) || pName.contains(noteLower))) {
                  debugPrint(
                    "Auto-completing matching pending request [ID: $pId] for note: $note",
                  );
                  await financeProvider.completePending(pId);
                }
              }
            } catch (e) {
              debugPrint("Error auto-completing matching pending: $e");
            }
          }
        }
        break;

      // ─────────────────────────────────────────────────────
      case 'create_pending_state':
        final partialNote = args['partial_note'] as String? ?? '';
        final aiQuestion =
            args['ai_generated_question'] as String? ?? 'Mohon lengkapi data.';
        int? aiAmount;
        if (args['partial_amount'] != null) {
          aiAmount = AmountParser.parseAmount(
            args['partial_amount'].toString(),
          );
        }
        final missing =
            (args['missing_fields'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];

        await financeProvider.savePending(
          originalInput: userText,
          nama: partialNote.isEmpty ? null : partialNote,
          nominal: aiAmount,
          aiQuestion: aiQuestion,
          reason: "Data tidak lengkap dari input user",
          type: 'OUT',
          missingFields: missing,
          partialData: {'note': partialNote},
        );
        interactiveQuestions.add(aiQuestion);
        break;

      // ─────────────────────────────────────────────────────
      case 'update_pending_state':
        final pId = int.tryParse(args['pending_id']?.toString() ?? '') ?? -1;
        final missing =
            (args['remaining_missing_fields'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        final nextQ = args['next_ai_question'] as String? ?? '';
        int? updatedAmount;
        if (args['updated_amount'] != null) {
          updatedAmount = int.tryParse(
            AmountParser.cleanNumberString(args['updated_amount'].toString()),
          );
        }
        final updatedNote = args['updated_note'] as String? ?? 'Transaksi';

        if (pId != -1) {
          if (missing.isEmpty && updatedAmount != null && updatedAmount > 0) {
            // Pending selesai → konversi ke transaksi
            final pmStr = args['payment_method'] as String? ?? 'tunai';
            final pm = pmStr == 'non_tunai'
                ? PaymentMethod.nonTunai
                : PaymentMethod.tunai;

            final sig = "${updatedNote.toLowerCase()}_$updatedAmount";
            if (!processedSignatures.contains(sig)) {
              processedSignatures.add(sig);
              await financeProvider.addTransaction(
                amount: updatedAmount,
                note: updatedNote,
                type: 'OUT',
                category: 'Other',
                paymentMethod: pm,
              );
              recordedTxs.add({
                'note': updatedNote,
                'amount': updatedAmount,
                'type': 'OUT',
                'payment_method': pm.label,
              });
            }
            await financeProvider.completePending(pId);
          } else {
            await financeProvider.updatePending(
              pId,
              nama: updatedNote,
              nominal: updatedAmount,
              missingFields: missing,
              aiQuestion: nextQ,
            );
            if (nextQ.isNotEmpty) interactiveQuestions.add(nextQ);
          }
        }
        break;

      // ─────────────────────────────────────────────────────
      case 'cancel_pending_state':
        final pId = int.tryParse(args['pending_id']?.toString() ?? '') ?? -1;
        if (pId != -1) {
          await financeProvider.cancelPending(pId);
          hasCancelRef(true);
        }
        break;

      // ─────────────────────────────────────────────────────
      case 'update_transaction':
        final id = int.tryParse(args['id']?.toString() ?? '') ?? -1;
        int? newAmount;
        if (args['new_amount'] != null) {
          newAmount = int.tryParse(
            AmountParser.cleanNumberString(args['new_amount'].toString()),
          );
        }
        final newNote = args['new_note'] as String?;
        final newPm = args['new_payment_method'] as String?;

        if (id != -1) {
          await financeProvider.updateTransaction(
            id,
            amount: newAmount,
            note: newNote,
            paymentMethod: newPm == 'non_tunai'
                ? PaymentMethod.nonTunai
                : newPm == 'tunai'
                ? PaymentMethod.tunai
                : null,
          );
          hasUpdateRef(true);
        }
        break;

      // ─────────────────────────────────────────────────────
      case 'query_database':
        final sql = args['sql'] as String? ?? '';
        if (sql.isEmpty) break;

        final validation = QueryValidator.validate(sql);
        if (!validation.isValid) {
          await financeProvider.addMessage(
            "Query tidak valid: ${validation.errorMessage}",
            true,
          );
          break;
        }

        final rows = await financeProvider.executeQuery(
          validation.sanitizedQuery!,
        );
        final resultContent = rows.isEmpty
            ? "Tidak ada data ditemukan."
            : "Ditemukan ${rows.length} data:\n${rows.take(20).map((r) => r.toString()).join('\n')}";

        final vizType = args['viz_type'] as String? ?? 'auto';
        final summaryPrompt = args['summary_prompt'] as String? ?? '';

        final ai = _ai;
        final pendingCtx = await _buildPendingContext();
        final recentTxsCtx = _buildRecentTransactionsContext();
        final aiSummary = await ai.summarizeQueryResult(
          systemPrompt: ai.buildSystemPrompt(
            pendingContext: pendingCtx,
            financialSummary: financeProvider.financialSummary,
            recentTransactionsContext: recentTxsCtx,
          ),
          userText: userText,
          agentMessage: agentMessage,
          toolCallId: toolCallId,
          resultContent: resultContent,
        );

        if (rows.isEmpty ||
            (rows.length == 1 && rows.first.values.length <= 2)) {
          await financeProvider.addMessage(aiSummary, true);
        } else {
          await financeProvider.addMessage(
            aiSummary,
            true,
            queryResult: {'rows': rows, 'columns': rows.first.keys.toList()},
            vizType: vizType,
          );
        }

        if (isChatVisible) voiceService.speak(aiSummary);
        break;

      // ─────────────────────────────────────────────────────
      case 'ask_clarification':
        final q = args['question'] as String? ?? 'Bisa diperjelas?';
        await financeProvider.addMessage(q, true);
        if (isChatVisible) voiceService.speak(q);
        break;

      // ─────────────────────────────────────────────────────
      case 'general_response':
        final answer = args['answer'] as String? ?? '';
        if (answer.isNotEmpty) {
          await financeProvider.addMessage(answer, true);
          if (isChatVisible) voiceService.speak(answer);
        }
        break;
    }
  }
}
