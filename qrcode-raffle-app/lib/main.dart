import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  debugPrint('🚀 main() started');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('✅ WidgetsFlutterBinding initialized');

  // Disable Google Fonts runtime fetching to prevent network hang on iOS
  // This makes the app use bundled fonts or system fallback instead
  GoogleFonts.config.allowRuntimeFetching = false;
  debugPrint('✅ Google Fonts runtime fetching disabled');

  // Initialize date formatting for pt_BR locale
  await initializeDateFormatting('pt_BR', null);
  debugPrint('✅ Date formatting initialized for pt_BR');

  // Initialize Firebase with platform-specific options
  try {
    debugPrint('🔥 Starting Firebase initialization...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stack) {
    debugPrint('❌ Firebase initialization error: $e');
    debugPrint('Stack: $stack');
  }

  debugPrint('🏃 Running app...');
  runApp(
    const ProviderScope(
      child: QrCodeRaffleApp(),
    ),
  );
  debugPrint('✅ runApp() completed');
}
