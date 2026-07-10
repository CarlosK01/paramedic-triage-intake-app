import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/triage/data/models/triage_record_model.dart';
import 'features/triage/presentation/pages/triage_intake_page.dart';
import 'features/triage/presentation/providers/triage_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TriageRecordModelAdapter());
  final box = await Hive.openBox<TriageRecordModel>(AppConstants.triageBoxName);

  runApp(
    ProviderScope(
      overrides: [
        hiveBoxProvider.overrideWithValue(box),
      ],
      child: const ParamedicTriageApp(),
    ),
  );
}

/// Root widget. Registers an [WidgetsBindingObserver] so that bringing the
/// app back to the foreground (e.g. after the user toggles Airplane Mode
/// from the OS settings and returns) triggers an immediate sync attempt,
/// per the "handle AppLifecycleState" requirement - rather than waiting
/// solely for the connectivity-changed stream event.
class ParamedicTriageApp extends ConsumerStatefulWidget {
  const ParamedicTriageApp({super.key});

  @override
  ConsumerState<ParamedicTriageApp> createState() => _ParamedicTriageAppState();
}

class _ParamedicTriageAppState extends ConsumerState<ParamedicTriageApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncServiceProvider).attemptSyncOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reading (not just watching) syncServiceProvider here ensures the
    // service is instantiated - and therefore listening for connectivity
    // changes - as soon as the app starts, even before any record has been
    // submitted.
    ref.watch(syncServiceProvider);

    return MaterialApp(
      title: 'Paramedic Triage Intake',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const TriageIntakePage(),
    );
  }
}
