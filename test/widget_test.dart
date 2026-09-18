import 'package:eco_responsable/core/theme/app_theme.dart';
import 'package:eco_responsable/core/widgets/status_badge.dart';
import 'package:eco_responsable/features/auth/presentation/welcome_screen.dart';
import 'package:eco_responsable/shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Welcome affiche le CTA Commencer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const WelcomeScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Éco-Responsable'), findsWidgets);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('StatusBadge affiche Signalé', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge(status: ReportStatus.reported)),
      ),
    );
    expect(find.text('Signalé'), findsOneWidget);
  });
}
