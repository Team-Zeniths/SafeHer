import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/providers/auth_provider.dart';
import 'package:frontend/features/contacts/providers/contacts_provider.dart';
import 'package:frontend/features/home/providers/safety_score_provider.dart';
import 'package:frontend/features/journey/providers/journey_provider.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/providers/theme_provider.dart';

class MockSafetyScoreProvider extends SafetyScoreProvider {
  int? _customScore;
  SafetyScoreStatus _customStatus = SafetyScoreStatus.idle;

  void setMockScore(int? score, SafetyScoreStatus status) {
    _customScore = score;
    _customStatus = status;
    notifyListeners();
  }

  @override
  int? get score => _customScore;

  @override
  SafetyScoreStatus get status => _customStatus;

  @override
  Future<void> loadScore() async {}
}

class MockContactsProvider extends ContactsProvider {
  @override
  Future<void> loadContacts() async {}
}

class MockJourneyProvider extends JourneyProvider {
  @override
  Future<void> loadHistory() async {}
}

void main() {
  testWidgets('ProfileScreen displays safety score and reacts to provider updates', (WidgetTester tester) async {
    final safetyScoreProvider = MockSafetyScoreProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<ContactsProvider>(create: (_) => MockContactsProvider()),
          ChangeNotifierProvider<JourneyProvider>(create: (_) => MockJourneyProvider()),
          ChangeNotifierProvider<SafetyScoreProvider>.value(value: safetyScoreProvider),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    // Initial state: score is not set yet (displays '--')
    expect(find.text('Safety\nScore'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);

    // Update safety score dynamically
    safetyScoreProvider.setMockScore(92, SafetyScoreStatus.loaded);
    await tester.pump();

    // Verify it updates reactively to 92
    expect(find.text('92'), findsOneWidget);

    // Update safety score again
    safetyScoreProvider.setMockScore(65, SafetyScoreStatus.loaded);
    await tester.pump();

    // Verify it updates reactively to 65
    expect(find.text('65'), findsOneWidget);
  });
}
