import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'views/event_list_screen.dart';
import 'views/event_creation_screen.dart';
import 'package:provider/provider.dart';
import 'core/viewmodels/event_creation_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
        '/': (context) => const EventListScreen(),
        // Wrap the EventCreationScreen with ChangeNotifierProvider so that
        // Provider.of<EventCreationViewModel> can find the viewmodel in its context.
        '/create-event': (context) => ChangeNotifierProvider(
          create: (_) => EventCreationViewModel(),
          child: const EventCreationScreen(),
        ),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
