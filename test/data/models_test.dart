import 'package:flutter_test/flutter_test.dart';
import 'package:finance_assistant/data/models/transaction_model.dart';
import 'package:finance_assistant/data/models/pending_model.dart';
import 'package:finance_assistant/data/models/room_model.dart';

void main() {
  group('TransactionModel Tests', () {
    final now = DateTime.now();
    final sampleJson = {
      'id': 123,
      'user_id': 'user-1',
      'room_id': 'room-1',
      'amount': 50000,
      'note': 'Beli Kopi',
      'type': 'OUT',
      'category': 'F&B',
      'payment_method': 'tunai',
      'created_at': now.toIso8601String(),
    };

    test('fromJson parses correctly', () {
      final model = TransactionModel.fromJson(sampleJson);
      expect(model.id, 123);
      expect(model.userId, 'user-1');
      expect(model.roomId, 'room-1');
      expect(model.amount, 50000);
      expect(model.note, 'Beli Kopi');
      expect(model.type, TransactionType.expense);
      expect(model.category, 'F&B');
      expect(model.paymentMethod, PaymentMethod.tunai);
    });

    test('toJson serializes correctly', () {
      final model = TransactionModel(
        id: 123,
        userId: 'user-1',
        roomId: 'room-1',
        amount: 50000,
        note: 'Beli Kopi',
        type: TransactionType.expense,
        category: 'F&B',
        paymentMethod: PaymentMethod.tunai,
        createdAt: now,
      );
      final json = model.toJson();
      expect(json['id'], 123);
      expect(json['user_id'], 'user-1');
      expect(json['room_id'], 'room-1');
      expect(json['amount'], 50000);
      expect(json['note'], 'Beli Kopi');
      expect(json['type'], 'OUT');
      expect(json['payment_method'], 'tunai');
    });

    test('classifyPaymentMethod classifies non-tunai categories', () {
      expect(TransactionModel.classifyPaymentMethod('EWallet'), PaymentMethod.nonTunai);
      expect(TransactionModel.classifyPaymentMethod('Transfer_In'), PaymentMethod.nonTunai);
      expect(TransactionModel.classifyPaymentMethod('Other'), PaymentMethod.tunai);
    });
  });

  group('PendingModel Tests', () {
    final now = DateTime.now();
    test('fromJson & toJson work correctly', () {
      final json = {
        'id': 1,
        'user_id': 'user-1',
        'original_input': 'beli bakso',
        'nama': 'bakso',
        'nominal': null,
        'quantity': 1,
        'missing_fields': ['nominal'],
        'partial_data': {'nama': 'bakso'},
        'ai_question': 'Berapa harganya?',
        'reason': 'nominal missing',
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final model = PendingModel.fromJson(json);
      expect(model.id, 1);
      expect(model.isResolvable, false);
      expect(model.missingFieldsLabel, 'harga/nominal');

      final serialized = model.toJson();
      expect(serialized['original_input'], 'beli bakso');
      expect(serialized['missing_fields'], ['nominal']);
    });
  });

  group('RoomModel Tests', () {
    final now = DateTime.now();
    test('fromJson parses RoomModel and RoomMember correctly', () {
      final json = {
        'id': 'room-id',
        'owner_id': 'owner-id',
        'room_code': 'ABCDEF',
        'name': 'Dompet Bersama',
        'is_active': true,
        'created_at': now.toIso8601String(),
        'room_members': [
          {
            'id': 10,
            'room_id': 'room-id',
            'user_id': 'user-1',
            'role': 'owner',
            'joined_at': now.toIso8601String(),
            'profiles': {'email': 'owner@test.com'}
          }
        ]
      };

      final model = RoomModel.fromJson(json);
      expect(model.id, 'room-id');
      expect(model.roomCode, 'ABCDEF');
      expect(model.members.length, 1);
      expect(model.members.first.isOwner, true);
      expect(model.members.first.email, 'owner@test.com');
    });
  });
}
