import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slipnow/app.dart';
import 'package:slipnow/data/local/local_store.dart';
import 'package:slipnow/data/repositories/mock_repositories.dart';
import 'package:slipnow/data/repositories/mock_support_chat.dart';
import 'package:slipnow/state/app_state.dart';
import 'package:slipnow/ui/widgets/app_button.dart';

Future<AppState> _state() async {
  SharedPreferences.setMockInitialValues({});
  final state = AppState(
    store: await LocalStore.open(),
    auth: MockAuthRepository(),
    results: MockResultsRepository(),
    payments: MockPaymentRepository(),
    support: MockSupportChatRepository(),
  )..load();
  return state;
}

Future<void> _settle(WidgetTester tester, [int ms = 600]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
    await tester.scrollUntilVisible(finder, 200, scrollable: vertical.last);
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.ensureVisible(finder);
  await _settle(tester, 400);
  await tester.tap(finder);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('full journey: onboarding, signup, search, pay, view slip', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = await _state();
    await tester.pumpWidget(ChangeNotifierProvider.value(value: state, child: const SlipNowApp()));
    await _settle(tester);

    expect(find.text('Find your name'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await _settle(tester);
    expect(find.text('Pay with Mobile Money'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await _settle(tester);
    await tester.tap(find.text('Get started'));
    await _settle(tester, 2000);

    expect(find.text('Your GCE grades. Without the trip.'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await _settle(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ada Test');
    await tester.enterText(fields.at(1), '670000000');
    await tester.enterText(fields.at(2), 'secret1!');
    await _settle(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Create account'));
    await _settle(tester, 1500);

    expect(find.text('Hi, Ada'), findsOneWidget);
    expect(find.text('The 2026 GCE results have been released'), findsOneWidget);
    expect(find.text('RELEASED'), findsOneWidget);

    for (final tab in ['Slips', 'Profile', 'Search']) {
      await tester.tap(find.text(tab).last);
      await _settle(tester);
    }
    expect(find.text('Search your results'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Njuh');
    await _settle(tester);
    expect(find.text('Centre 11045 · 05210417'), findsOneWidget);
    await _tap(tester, find.widgetWithText(AppButton, 'Search'));
    await _settle(tester, 2000);
    expect(find.text('Your result'), findsOneWidget);
    await _reveal(tester, find.text('Pay to unlock your slip'));
    expect(find.text('Pay to unlock your slip'), findsOneWidget);
    await _reveal(tester, find.text('GCE Board result'));
    expect(find.text('GCE Board result'), findsOneWidget);
    await _reveal(tester, find.text('Collect your original slip'));
    expect(find.text('Collect your original slip'), findsOneWidget);
    await _tap(tester, find.text('Unlock slip'));
    await _settle(tester);
    expect(find.text('Unlock your slip'), findsOneWidget);
    expect(find.text('Detected: MTN MoMo'), findsOneWidget);
    await _tap(tester, find.text('Continue to payment'));
    await _settle(tester);
    expect(find.text('Confirm payment'), findsOneWidget);
    expect(find.text('Approve the prompt on your phone'), findsOneWidget);
    await _tap(tester, find.text('I have confirmed'));
    await _settle(tester, 3500);
    expect(find.text('Payment successful'), findsOneWidget);
    await _tap(tester, find.text('View my official slip'));
    await _settle(tester, 1500);

    expect(state.purchases, hasLength(1));
    expect(find.text('OFFICIAL RESULT SLIP'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close PDF viewer'));
    await _settle(tester);
    expect(find.text('Slip unlocked'), findsWidgets);
    await _reveal(tester, find.text('Unlocked'));
    expect(find.text('Unlocked'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    await tester.tap(find.text('Profile').last);
    await _settle(tester);

    await _tap(tester, find.text('Payment receipts'));
    await _settle(tester);
    expect(find.text('PAID'), findsOneWidget);
    expect(find.text('1 slip unlocked'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _settle(tester);

    await _tap(tester, find.text('Live chat'));
    await _settle(tester, 1000);
    expect(find.text('SlipNow Support'), findsOneWidget);
    expect(find.textContaining('Hi Ada! I am Brenda'), findsOneWidget);
    await _tap(tester, find.text('💳 My payment failed'));
    await _settle(tester, 7000);
    expect(state.chat.messages.where((m) => m.fromMe), hasLength(1));
    expect(find.textContaining('send me the transaction ID'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Thank you');
    await _settle(tester, 200);
    await tester.tap(find.bySemanticsLabel('Send'));
    await _settle(tester, 7000);
    expect(find.textContaining('Thank you'), findsOneWidget);
    expect(find.textContaining('You are welcome'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _settle(tester);

    await _tap(tester, find.text('Dark mode'));
    await _settle(tester);
    expect(state.darkMode, isTrue);
    await _tap(tester, find.text('Language · English'));
    await _settle(tester, 3000);
    expect(find.text('Profil'), findsWidgets);
  });
}
