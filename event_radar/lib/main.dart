import 'package:event_radar/core/viewmodels/profile_settings_viewmodel.dart';
import 'package:event_radar/views/event_overview_screen.dart';
import 'package:event_radar/views/profile/login_screen.dart';
import 'package:event_radar/views/profile/profile_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/models/event.dart';
import 'firebase_options.dart';
import 'views/event_list_screen.dart';
import 'views/event_creation_screen.dart';
import 'views/event_map_screen.dart';
import 'package:provider/provider.dart';
import 'core/viewmodels/event_creation_viewmodel.dart';
import 'core/viewmodels/event_list_viewmodel.dart';
import 'core/viewmodels/event_map_viewmodel.dart';
import 'core/providers/location_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Preload the current location for the app.
  final LocationProvider locationProvider = LocationProvider();
  await locationProvider.updateLocation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocationProvider>.value(value: locationProvider),
        ChangeNotifierProvider<EventListViewModel>(
          create: (_) => EventListViewModel(),
        ),
        ChangeNotifierProvider<EventMapViewModel>(
          create: (_) => EventMapViewModel(),
        ),
        ChangeNotifierProvider<ProfileSettingsViewModel>(
            create: (_) => ProfileSettingsViewModel()
        ),
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
      title: 'Event Radar',
      initialRoute: '/',
      routes: {
        '/': (context) => const EventListScreen(),
        '/create-event': (context) => ChangeNotifierProvider(
          create: (_) => EventCreationViewModel(),
          child: const EventCreationScreen(),
        ),
        '/map-events': (context) => const EventMapScreen(),
        '/event-overview': (context) {
          final event = ModalRoute.of(context)?.settings.arguments as Event;
          return EventOverviewScreen(event: event);
        },
        '/profile-settings': (context) => const ProfileScreen(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
