import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/app/app_target.dart';

/// Point d'entrée commun : initialise le stockage local et les formats de
/// date, puis lance [EcoApp] pour la cible demandée.
Future<void> runEcoApp(AppTarget target) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeDateFormatting('fr');
  runApp(
    ProviderScope(
      overrides: [appTargetProvider.overrideWithValue(target)],
      child: const EcoApp(),
    ),
  );
}
