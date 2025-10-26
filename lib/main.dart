import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/db_service.dart';
import 'services/club_service.dart';
import 'services/comms_service.dart';
import 'services/file_gps_service.dart';
import 'services/voice_coach.dart';
import 'services/hole_service.dart';
import 'services/practice_session_service.dart';
import 'services/goal_service.dart';

import 'screens/splash_screen.dart';
import 'screens/setup_clubs_screen.dart';
import 'screens/rover_connect_screen.dart';
import 'screens/distance_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/practice_sessions_screen.dart';
import 'screens/goals_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = DbService();
  await db.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DbService>.value(value: db),           // ONE initialized instance
        ChangeNotifierProvider(create: (_) => ClubService()),
        ChangeNotifierProvider(create: (_) => CommsService()..init()),
        ChangeNotifierProvider(create: (_) => FileGpsService()),
        ChangeNotifierProvider(create: (_) => VoiceCoach()..init()),
        ChangeNotifierProvider(create: (_) => HoleService()),
        ChangeNotifierProvider(create: (_) => PracticeSessionService()..init()),
        ChangeNotifierProvider(create: (_) => GoalService()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7AB36F),
        scaffoldBackgroundColor: const Color(0xFFEAF4FF), // light blue
      ),
      home: const SplashScreen(),
      routes: {
        '/setup':     (_) => const SetupClubsScreen(),
        '/connect':   (_) => const RoverConnectScreen(),
        '/distance':  (_) => const DistanceScreen(),
        '/recommend': (_) => const RecommendScreen(),
        '/history':   (_) => const HistoryScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/sessions':  (_) => const PracticeSessionsScreen(),
        '/goals':     (_) => const GoalsScreen(),
      },
    );
  }
}
