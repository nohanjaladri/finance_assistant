import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:finance_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:finance_assistant/presentation/providers/finance_provider.dart';
import 'package:finance_assistant/data/services/voice_service.dart';
import 'package:finance_assistant/data/services/ai_service.dart';
import 'package:finance_assistant/data/models/transaction_model.dart';

class MockFinanceProvider extends Mock implements FinanceProvider {}
class MockVoiceService extends Mock implements VoiceService {}
class MockAiService extends Mock implements AiService {}

void main() {
  late AiChatController controller;
  late MockFinanceProvider mockProvider;
  late MockVoiceService mockVoice;
  late MockAiService mockAi;

  setUpAll(() {
    dotenv.testLoad(fileInput: '''
      GROQ_API_KEY=test-groq-key
      GEMINI_API_KEY=test-gemini-key
    ''');
  });

  setUp(() {
    mockProvider = MockFinanceProvider();
    mockVoice = MockVoiceService();
    mockAi = MockAiService();

    controller = AiChatController(
      financeProvider: mockProvider,
      voiceService: mockVoice,
    )..aiOverride = mockAi;

    // Default stubs
    when(() => mockProvider.addMessage(
          any(),
          any(),
          receiptData: any(named: 'receiptData'),
          queryResult: any(named: 'queryResult'),
          vizType: any(named: 'vizType'),
        )).thenAnswer((_) async {});
    when(() => mockProvider.setAiThinking(any())).thenReturn(null);
  });

  group('AiChatController Tests', () {
    test('processMessage handles text and updates provider states', () async {
      // Arrange
      final userText = 'Halo, tolong catat pengeluaran saya';
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      
      // Stub provider state changes
      when(() => mockProvider.addMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockProvider.setAiThinking(any())).thenReturn(null);

      // Stub AI response
      final mockResponse = AiResponse(
        content: 'Halo! Saya siap membantu mencatat keuangan Anda.',
        usedProvider: AiProvider.groq,
      );
      
      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt Context');

      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);
      when(() => mockVoice.speak(any())).thenAnswer((_) async {});

      // Act
      await controller.processMessage(userText: userText, isChatVisible: true);

      // Assert
      verify(() => mockProvider.addMessage(userText, false)).called(1);
      verify(() => mockProvider.setAiThinking(true)).called(1);
      verify(() => mockProvider.addMessage('Halo! Saya siap membantu mencatat keuangan Anda.', true)).called(1);
      verify(() => mockVoice.speak('Halo! Saya siap membantu mencatat keuangan Anda.')).called(1);
      verify(() => mockProvider.setAiThinking(false)).called(1);
    });

    test('processMessage handles empty text gracefully', () async {
      // Act
      await controller.processMessage(userText: '   ', isChatVisible: true);

      // Assert
      verifyNever(() => mockProvider.addMessage(any(), any()));
      verifyNever(() => mockProvider.setAiThinking(any()));
    });

    test('processMessage handles record_transaction tool call from AI', () async {
      // Arrange
      final userText = 'Beli bensin 20000';
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      
      // Stub provider methods
      when(() => mockProvider.addMessage(any(), any(), receiptData: any(named: 'receiptData')))
          .thenAnswer((_) async {});
      when(() => mockProvider.setAiThinking(any())).thenReturn(null);
      when(() => mockProvider.addTransaction(
            amount: 20000,
            note: 'Bensin',
            type: 'OUT',
            category: 'Transport',
            paymentMethod: PaymentMethod.tunai,
          )).thenAnswer((_) async => null);
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      // Mock AI response with tool call
      final mockResponse = AiResponse(
        content: 'Mencatat bensin...',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_1',
            'type': 'function',
            'function': {
              'name': 'record_transaction',
              'arguments': '{"amount": "20000", "note": "Bensin", "type": "OUT", "category": "Transport", "payment_method": "tunai"}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.addTransaction(
            amount: 20000,
            note: 'Bensin',
            type: 'OUT',
            category: 'Transport',
            paymentMethod: PaymentMethod.tunai,
          )).called(1);
    });

    test('processMessage handles create_pending_state tool call for incomplete user input', () async {
      // Arrange
      final userText = 'Saya beli bakso'; // No amount
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      
      when(() => mockProvider.addMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockProvider.setAiThinking(any())).thenReturn(null);
      when(() => mockProvider.savePending(
            originalInput: userText,
            nama: 'bakso',
            nominal: null,
            aiQuestion: 'Berapa harga baksonya?',
            reason: any(named: 'reason'),
            type: 'OUT',
            missingFields: ['nominal'],
            partialData: {'note': 'bakso'},
          )).thenAnswer((_) async => null);
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      final mockResponse = AiResponse(
        content: 'Harga baksonya berapa ya?',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_2',
            'type': 'function',
            'function': {
              'name': 'create_pending_state',
              'arguments': '{"partial_note": "bakso", "ai_generated_question": "Berapa harga baksonya?", "missing_fields": ["nominal"]}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.savePending(
            originalInput: userText,
            nama: 'bakso',
            nominal: null,
            aiQuestion: 'Berapa harga baksonya?',
            reason: any(named: 'reason'),
            type: 'OUT',
            missingFields: ['nominal'],
            partialData: {'note': 'bakso'},
          )).called(1);
    });

    test('processMessage handles update_pending_state tool call to complete transaction', () async {
      // Arrange
      final userText = '15 ribu'; // User answers the pending question
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      
      when(() => mockProvider.addMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockProvider.setAiThinking(any())).thenReturn(null);
      when(() => mockProvider.addTransaction(
            amount: 15000,
            note: 'bakso',
            type: 'OUT',
            category: 'Other',
            paymentMethod: PaymentMethod.tunai,
          )).thenAnswer((_) async => null);
      when(() => mockProvider.completePending(45)).thenAnswer((_) async => true);
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      final mockResponse = AiResponse(
        content: 'Mencatat bakso Rp 15.000...',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_3',
            'type': 'function',
            'function': {
              'name': 'update_pending_state',
              'arguments': '{"pending_id": "45", "updated_note": "bakso", "updated_amount": "15000", "remaining_missing_fields": []}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.addTransaction(
            amount: 15000,
            note: 'bakso',
            type: 'OUT',
            category: 'Other',
            paymentMethod: PaymentMethod.tunai,
          )).called(1);
      verify(() => mockProvider.completePending(45)).called(1);
    });

    test('processMessage handles cancel_pending_state tool call', () async {
      // Arrange
      final userText = 'batal';
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      
      when(() => mockProvider.cancelPending(45)).thenAnswer((_) async => true);
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      final mockResponse = AiResponse(
        content: 'Membatalkan...',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_4',
            'type': 'function',
            'function': {
              'name': 'cancel_pending_state',
              'arguments': '{"pending_id": "45"}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.cancelPending(45)).called(1);
    });

    test('processMessage handles update_transaction tool call', () async {
      // Arrange
      final userText = 'Ubah nominal transaksi 123 jadi 50 ribu';
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      
      when(() => mockProvider.updateTransaction(
            123,
            amount: 50000,
            note: any(named: 'note'),
            paymentMethod: any(named: 'paymentMethod'),
          )).thenAnswer((_) async => true);
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      final mockResponse = AiResponse(
        content: 'Mengupdate transaksi...',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_5',
            'type': 'function',
            'function': {
              'name': 'update_transaction',
              'arguments': '{"id": "123", "new_amount": "50000"}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.updateTransaction(
            123,
            amount: 50000,
            note: any(named: 'note'),
            paymentMethod: any(named: 'paymentMethod'),
          )).called(1);
    });

    test('processMessage handles query_database tool call', () async {
      // Arrange
      final userText = 'Berapa total pengeluaran bulan ini?';
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      
      final mockRows = [{'total': 150000}];
      when(() => mockProvider.executeQuery('SELECT SUM(amount) FROM transactions'))
          .thenAnswer((_) async => mockRows);
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      final mockResponse = AiResponse(
        content: 'Membaca database...',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_6',
            'type': 'function',
            'function': {
              'name': 'query_database',
              'arguments': '{"sql": "SELECT SUM(amount) FROM transactions", "viz_type": "auto", "summary_prompt": "Tampilkan total"}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);
      when(() => mockAi.summarizeQueryResult(
            systemPrompt: any(named: 'systemPrompt'),
            userText: any(named: 'userText'),
            agentMessage: any(named: 'agentMessage'),
            toolCallId: any(named: 'toolCallId'),
            resultContent: any(named: 'resultContent'),
          )).thenAnswer((_) async => 'Total pengeluaran Anda adalah Rp 150.000');

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.executeQuery('SELECT SUM(amount) FROM transactions')).called(1);
      verify(() => mockProvider.addMessage('Total pengeluaran Anda adalah Rp 150.000', true)).called(1);
    });

    test('processMessage handles ask_clarification tool call', () async {
      // Arrange
      final userText = 'catat itu';
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      final mockResponse = AiResponse(
        content: 'Meminta klarifikasi...',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_7',
            'type': 'function',
            'function': {
              'name': 'ask_clarification',
              'arguments': '{"question": "Catat transaksi apa ya?", "context": "Input tidak jelas"}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.addMessage('Catat transaksi apa ya?', true)).called(1);
    });

    test('processMessage handles general_response tool call', () async {
      // Arrange
      final userText = 'Tips menabung';
      
      when(() => mockProvider.getAllPending()).thenAnswer((_) async => []);
      when(() => mockProvider.activeChatType).thenReturn('tunai');
      when(() => mockProvider.chatHistory).thenReturn([]);
      when(() => mockProvider.allTransactions).thenReturn([]);
      when(() => mockProvider.financialSummary).thenReturn({});
      when(() => mockProvider.refreshAll()).thenAnswer((_) async {});

      final mockResponse = AiResponse(
        content: 'Menjawab...',
        usedProvider: AiProvider.groq,
        toolCalls: [
          {
            'id': 'call_8',
            'type': 'function',
            'function': {
              'name': 'general_response',
              'arguments': '{"answer": "Cobalah menabung minimal 10% dari pemasukan.", "topic_category": "savings"}'
            }
          }
        ],
      );

      when(() => mockAi.buildSystemPrompt(
            pendingContext: any(named: 'pendingContext'),
            financialSummary: any(named: 'financialSummary'),
            recentTransactionsContext: any(named: 'recentTransactionsContext'),
          )).thenReturn('System Prompt');
      when(() => mockAi.sendMessage(any())).thenAnswer((_) async => mockResponse);

      // Act
      await controller.processMessage(userText: userText, isChatVisible: false);

      // Assert
      verify(() => mockProvider.addMessage('Cobalah menabung minimal 10% dari pemasukan.', true)).called(1);
    });
  });
}
