import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_assistant/presentation/providers/finance_provider.dart';
import 'package:finance_assistant/data/services/supabase_service.dart';
import 'package:finance_assistant/data/models/transaction_model.dart';
import 'package:finance_assistant/data/models/pending_model.dart';
import 'package:finance_assistant/data/models/room_model.dart';

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late FinanceProvider provider;
  late MockSupabaseService mockDb;

  setUpAll(() {
    registerFallbackValue(TransactionType.expense);
    registerFallbackValue(PaymentMethod.tunai);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockDb = MockSupabaseService();
    provider = FinanceProvider()..dbOverride = mockDb;
  });

  group('FinanceProvider Tests', () {
    test(
      'refreshAll loads transactions and updates financial status',
      () async {
        // Arrange
        final now = DateTime.now();
        final mockTransactions = [
          TransactionModel(
            id: 1,
            userId: 'user-1',
            amount: 50000,
            note: 'Gaji',
            type: TransactionType.income,
            category: 'Salary',
            paymentMethod: PaymentMethod.nonTunai,
            createdAt: now,
          ),
          TransactionModel(
            id: 2,
            userId: 'user-1',
            amount: 15000,
            note: 'Bakso',
            type: TransactionType.expense,
            category: 'F&B',
            paymentMethod: PaymentMethod.tunai,
            createdAt: now,
          ),
        ];

        when(
          () => mockDb.getPersonalTransactions(limit: any(named: 'limit')),
        ).thenAnswer((_) async => mockTransactions);
        when(
          () => mockDb.getChatMessages(
            chatType: any(named: 'chatType'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);
        when(() => mockDb.getPendingCount()).thenAnswer((_) async => 2);
        when(() => mockDb.getMyRoomCode()).thenAnswer((_) async => 'CODE123');
        when(
          () => mockDb.getFinancialSummary(),
        ).thenAnswer((_) async => {'total': 35000});

        // Act
        await provider.refreshAll();

        // Assert
        expect(provider.syncStatus, SyncStatus.synced);
        expect(provider.allTransactions.length, 2);
        expect(provider.totalIn, 50000);
        expect(provider.totalOut, 15000);
        expect(provider.tunaiOut, 15000);
        expect(provider.nonTunaiIn, 50000);
        expect(provider.pendingCount, 2);
        expect(provider.myRoomCode, 'CODE123');
      },
    );

    test('setActiveChatType updates chat type and notifies listeners', () {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.setActiveChatType('non_tunai');
      expect(provider.activeChatType, 'non_tunai');
      expect(notified, true);
    });

    test('addTransaction triggers db insert and refreshes data', () async {
      // Arrange
      final now = DateTime.now();
      final newTx = TransactionModel(
        id: 3,
        userId: 'user-1',
        amount: 20000,
        note: 'Gojek',
        type: TransactionType.expense,
        category: 'Transport',
        paymentMethod: PaymentMethod.nonTunai,
        createdAt: now,
      );

      when(
        () => mockDb.addTransaction(
          amount: 20000,
          note: 'Gojek',
          type: 'OUT',
          category: 'Transport',
          paymentMethod: PaymentMethod.nonTunai,
          roomId: any(named: 'roomId'),
        ),
      ).thenAnswer((_) async => newTx);

      // stub refreshAll dependencies
      when(
        () => mockDb.getPersonalTransactions(limit: any(named: 'limit')),
      ).thenAnswer((_) async => [newTx]);
      when(
        () => mockDb.getChatMessages(
          chatType: any(named: 'chatType'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);
      when(() => mockDb.getPendingCount()).thenAnswer((_) async => 0);
      when(() => mockDb.getMyRoomCode()).thenAnswer((_) async => '');
      when(() => mockDb.getFinancialSummary()).thenAnswer((_) async => {});

      // Act
      final result = await provider.addTransaction(
        amount: 20000,
        note: 'Gojek',
        type: 'OUT',
        category: 'Transport',
        paymentMethod: PaymentMethod.nonTunai,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 3);
      verify(
        () => mockDb.addTransaction(
          amount: 20000,
          note: 'Gojek',
          type: 'OUT',
          category: 'Transport',
          paymentMethod: PaymentMethod.nonTunai,
          roomId: any(named: 'roomId'),
        ),
      ).called(1);
    });

    test(
      'joinRoom connects user to sharing room and registers listener',
      () async {
        // Arrange
        final room = RoomModel(
          id: 'room-123',
          ownerId: 'owner-1',
          roomCode: 'ROOMXYZ',
          name: 'Dompet Bersama',
          createdAt: DateTime.now(),
          members: [],
        );

        when(
          () => mockDb.joinRoomByCode('ROOMXYZ'),
        ).thenAnswer((_) async => room);
        when(
          () => mockDb.listenToSharedTransactions(
            roomId: 'room-123',
            onUpdate: any(named: 'onUpdate'),
          ),
        ).thenAnswer((_) {});
        when(
          () => mockDb.getSharedTransactions(
            roomId: 'room-123',
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        final result = await provider.joinRoom('ROOMXYZ');

        // Assert
        expect(result, isNotNull);
        expect(provider.activeRoom?.id, 'room-123');
        expect(provider.isSharingConnected, true);
        expect(provider.isSharingEnabled, true);
        verify(
          () => mockDb.listenToSharedTransactions(
            roomId: 'room-123',
            onUpdate: any(named: 'onUpdate'),
          ),
        ).called(1);
      },
    );

    test(
      'leaveCurrentRoom disconnects user and cleans up room state',
      () async {
        // Arrange
        provider.activeRoom = RoomModel(
          id: 'room-123',
          ownerId: 'owner-1',
          roomCode: 'ROOMXYZ',
          name: 'Dompet Bersama',
          createdAt: DateTime.now(),
        );
        provider.isSharingConnected = true;

        when(() => mockDb.leaveRoom('room-123')).thenAnswer((_) async => true);
        when(() => mockDb.stopListeningToShared()).thenAnswer((_) {});

        // Act
        await provider.leaveCurrentRoom();

        // Assert
        expect(provider.activeRoom, isNull);
        expect(provider.isSharingConnected, false);
        verify(() => mockDb.leaveRoom('room-123')).called(1);
        verify(() => mockDb.stopListeningToShared()).called(1);
      },
    );

    test(
      'chatHistory returns shared history in sharing mode when connected',
      () async {
        // Arrange
        provider.isSharingConnected = true;
        provider.setActiveChatType('sharing');
        provider.activeRoom = RoomModel(
          id: 'room-123',
          ownerId: 'owner-1',
          roomCode: 'ROOMXYZ',
          name: 'Dompet Bersama',
          createdAt: DateTime.now(),
        );

        final mockMsg = {'text': 'Hello Shared', 'is_ai': false};
        provider.sharedChatHistory = [mockMsg];

        // Act & Assert
        expect(provider.chatHistory, contains(mockMsg));
      },
    );
  });
}
