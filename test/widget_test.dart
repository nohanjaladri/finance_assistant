import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finance_assistant/presentation/widgets/pending_reminder_card.dart';
import 'package:finance_assistant/presentation/providers/finance_provider.dart';

class MockFinanceProvider extends Mock implements FinanceProvider {}

void main() {
  testWidgets('PendingBadge shows correct pending count badge', (WidgetTester tester) async {
    // Arrange
    final mockProvider = MockFinanceProvider();
    when(() => mockProvider.pendingCount).thenReturn(5);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              ChangeNotifierProvider<FinanceProvider>.value(
                value: mockProvider,
                child: const PendingBadge(),
              ),
            ],
          ),
        ),
      ),
    );

    // Assert
    expect(find.byIcon(Icons.pending_actions), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });
}
