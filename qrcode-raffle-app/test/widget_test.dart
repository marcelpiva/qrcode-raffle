import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qrcode_raffle_app/app.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: QrCodeRaffleApp(),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('QR Code Raffle'), findsOneWidget);
  });
}
