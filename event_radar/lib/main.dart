import 'package:event_radar/core/services/event_service.dart';
import 'package:event_radar/core/viewmodels/profile_settings_viewmodel.dart';
import 'package:event_radar/views/event_overview_screen.dart';
import 'package:event_radar/views/profile/profile_screen.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
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
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = GoRouter(
    initialLocation: '/event-list',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/event-list'
      ),
      GoRoute(
        path: '/event-list',
        builder: (context, state) => EventListScreen(),
        routes: <RouteBase>[
          GoRoute(
            path: 'create-event',
            builder: (context, state) {
              return ChangeNotifierProvider(
                create: (_) => EventCreationViewModel(),
                child: const EventCreationScreen(),
              );
            }
          ),
          GoRoute(
            path: '/event-overview/:index',
            builder: (context, state) {
              // TODO create own viewModel for EventOverviewScreen
              final id = int.parse(state.pathParameters['index']!);
              return Consumer<EventListViewModel>(
                builder: (context, viewModel, child) {
                  return EventOverviewScreen(
                    event: viewModel.events[id],
                  );
                },
              );
            }
          )
        ]
      ),
      GoRoute(
        path: '/map-events',
        builder: (context, state) => EventMapScreen()
      ),
      GoRoute(
        path: '/map-events',
        builder: (context, state) => EventMapScreen()
      ),
      GoRoute(
        path: '/profile-settings',
        builder: (context, state) => ProfileScreen()
      )
    ]
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}
