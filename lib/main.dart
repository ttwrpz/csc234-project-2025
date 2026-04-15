import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/local_db_service.dart';
import 'services/preferences_service.dart';
import 'utils/sync_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/garden_provider.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize services
  final authService = AuthService();
  final firestoreService = FirestoreService();
  final storageService = StorageService();
  final localDbService = LocalDbService();
  final preferencesService = PreferencesService();

  await localDbService.init();

  final syncManager = SyncManager(
    firestoreService: firestoreService,
    localDbService: localDbService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            preferencesService: preferencesService,
          )..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: authService,
            firestoreService: firestoreService,
            storageService: storageService,
            localDbService: localDbService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MoodProvider(
            firestoreService: firestoreService,
            storageService: storageService,
            localDbService: localDbService,
            syncManager: syncManager,
          ),
        ),
        ChangeNotifierProvider(create: (_) => GardenProvider()),
      ],
      child: const MoodBloomApp(),
    ),
  );
}
