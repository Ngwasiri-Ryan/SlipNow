import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/local_store.dart';
import 'data/repositories/mock_repositories.dart';
import 'data/repositories/mock_support_chat.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();

  // Swap these mock repositories for API-backed implementations once the
  // backend exists; nothing else in the app needs to change.
  final state = AppState(
    store: store,
    auth: MockAuthRepository(),
    results: MockResultsRepository(),
    payments: MockPaymentRepository(),
    support: MockSupportChatRepository(),
  )..load();

  runApp(ChangeNotifierProvider.value(value: state, child: const SlipNowApp()));
}
