import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rlds_church_app/data/repositories/church_sync_repository.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_bloc.dart';
import 'package:rlds_church_app/presentation/screens/church_splash_screen.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local offline-first storage and caching
  await Hive.initFlutter();

  await Hive.openBox('offline_queue');
  await Hive.openBox('auth_cache');
  await Hive.openBox('church_content_cache');

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
        child: ListenableBuilder(
          listenable: AppStateNotifier.instance,
          builder: (context, _) {
            return MaterialApp(
              title: 'The Church of Jesus Christ Restoration Ministry',
              debugShowCheckedModeBanner: false,
              themeMode: AppStateNotifier.instance.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1E3A8A), // Deep liturgical blue
                  secondary: const Color(0xFFD97706), // Stewardship gold
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: const Color(0xFFF9FAFB),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1E3A8A),
                  secondary: const Color(0xFFF59E0B),
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF0F172A),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
              home: const ChurchSplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
