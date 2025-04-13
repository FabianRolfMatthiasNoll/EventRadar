import 'package:event_radar/views/event_overview_screen.dart';
import 'package:event_radar/views/profile/login_screen.dart';
import 'package:event_radar/views/profile/profile_settings_screen.dart';
import 'package:event_radar/views/profile/register_screen.dart';
import 'package:event_radar/views/profile/reset_password_screen.dart';
import 'package:event_radar/widgets/main_scaffold.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'core/services/auth_service.dart';
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});



  final _router = GoRouter(
    initialLocation: '/event-list',
    navigatorKey: _rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (contest, state, navigationShell) {
          return NavbarContainer(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
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
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/event-overview/:index',
                builder: (context, state) {
                  // TODO create own viewModel for EventOverviewScreen
                  // TODO use id instead of index
                  final id = int.parse(state.pathParameters['index']!);
                  return Consumer<EventListViewModel>(
                    builder: (context, viewModel, child) {
                      return EventOverviewScreen(
                        event: viewModel.events[id],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map-events',
                builder: (context, state) => EventMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder:
                    (context, state) =>
                        Center(child: Text('Not Implemented yet.')),
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: '/profile-settings',
            routes: [
              GoRoute(
                path: '/profile-settings',
                builder: (context, state) {
                  final user = AuthService().currentUser();
                  return ProfileSettingsScreen(
                    email: user?.email,
                    name: user?.displayName,
                  );
                },
                redirect: (context, state) {
                  // redirect to login if not logged in
                  final loggedIn = AuthService().currentUser() != null;
                  if (!loggedIn) {
                    return '/login';
                  }
                  return null;
                },
              ),
              GoRoute(
                path: '/login',
                builder: (context, state) => LoginScreen(),
                routes: [
                  GoRoute(
                    path: 'register',
                    builder: (context, state) => RegisterScreen(),
                  ),
                  GoRoute(
                    path: 'reset-password',
                    builder: (context, state) => ResetPasswordScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/', redirect: (context, state) => '/event-list'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
