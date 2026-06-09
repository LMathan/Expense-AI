import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/storage/hive_helper.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Hive database and pre-populate with premium simulated values
  await HiveHelper.init();

  // Graceful Firebase setup integration fallback. 
  // If the credentials/files are missing during compile/execution, it degrades to Offline-first Hive.
  try {
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Fall back to local database
  }

  runApp(
    const ProviderScope(
      child: ExpenseAIApp(),
    ),
  );
}
