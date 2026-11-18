import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rlds_church_app/data/repositories/church_sync_repository.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_bloc.dart';
import 'package:rlds_church_app/presentation/screens/church_splash_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized before asynchronous startup tasks
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive for local offline-first storage and caching
  await Hive.initFlutter();

  // Open Hive boxes to store offline transaction queues, user sessions, and cached content
  await Hive.openBox('offline_queue');
  await Hive.openBox('auth_cache');
  await Hive.openBox('church_content_cache');

  // Initialize repository
  final syncRepository = ChurchSyncRepository();

  runApp(RLDSChurchApp(syncRepository: syncRepository));
}

class RLDSChurchApp extends StatelessWidget {
  final ChurchSyncRepository syncRepository;

  const RLDSChurchApp({super.key, required this.syncRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChurchSyncRepository>.value(value: syncRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ChurchSyncBloc>(
            create: (context) => ChurchSyncBloc(syncRepository),
          ),
        ],
        child: MaterialApp(
          title: 'RLDS Church Restoration Ministry',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A), // Deep liturgical blue
              secondary: const Color(0xFFD97706), // Stewardship gold accent
            ),
            scaffoldBackgroundColor: const Color(0xFFF9FAFB),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
          ),
          home: const ChurchSplashScreen(),
        ),
      ),
    );
  }
}
