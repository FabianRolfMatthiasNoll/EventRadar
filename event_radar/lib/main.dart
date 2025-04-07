import 'package:event_radar/views/event_map_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/viewmodels/event_map_viewmodel.dart';
import 'firebase_options.dart';
import 'views/event_list_screen.dart';
import 'views/event_creation_screen.dart';
import 'package:provider/provider.dart';
import 'core/viewmodels/event_creation_viewmodel.dart';
import 'core/viewmodels/event_list_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Activate App Check for development using debug providers.
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Radar',
      initialRoute: '/',
      routes: {
        '/': (context) => ChangeNotifierProvider<EventListViewModel>(
          create: (_) => EventListViewModel(),
          child: const EventListScreen(),
        ),
        '/create-event': (context) => ChangeNotifierProvider<EventCreationViewModel>(
          create: (_) => EventCreationViewModel(),
          child: const EventCreationScreen(),
        ),
        '/map-events': (context) => ChangeNotifierProvider<EventMapViewModel>(
          create: (_) => EventMapViewModel(),
          child: const EventMapScreen(),
        ),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
