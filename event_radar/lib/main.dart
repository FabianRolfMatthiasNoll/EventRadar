import 'package:event_radar/views/chat_screen.dart';
import 'package:event_radar/views/event_creation_screen.dart';
import 'package:event_radar/views/event_list_screen.dart';
import 'package:event_radar/views/event_map_screen.dart';
import 'package:event_radar/views/event_overview_screen.dart';
import 'package:event_radar/views/profile/login_screen.dart';
import 'package:event_radar/views/profile/profile_settings_screen.dart';
import 'package:event_radar/views/profile/register_screen.dart';
import 'package:event_radar/views/profile/reset_password_screen.dart';
import 'package:event_radar/views/search_screen.dart';
import 'package:event_radar/widgets/main_scaffold.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/providers/location_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/services/auth_service.dart';
import 'core/viewmodels/event_creation_viewmodel.dart';
import 'core/viewmodels/event_list_viewmodel.dart';
import 'core/viewmodels/event_map_viewmodel.dart';
import 'core/viewmodels/event_overview_viewmodel.dart';
import 'firebase_options.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel announcementChannel =
    AndroidNotificationChannel(
      'event_announcements',
      'Event Announcements',
      description: 'Ankündigungen zu Events',
      importance: Importance.high,
    );

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  const androidInit = AndroidInitializationSettings('ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: androidInit),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(announcementChannel);

  final locationProvider = LocationProvider();
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
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // 1) Router konfigurieren
    _router = GoRouter(
      initialLocation: '/event-list',
      navigatorKey: _rootNavigatorKey,
      routes: [
        StatefulShellRoute.indexedStack(
          builder:
              (context, state, navShell) =>
                  NavbarContainer(navigationShell: navShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/event-list',
                  builder: (context, state) => EventListScreen(),
                  routes: [
                    GoRoute(
                      path: 'create-event',
                      builder:
                          (context, state) => ChangeNotifierProvider(
                            create: (_) => EventCreationViewModel(),
                            child: const EventCreationScreen(),
                          ),
                    ),
                  ],
                ),
                GoRoute(
                  path: '/event-overview/:id',
                  builder: (context, state) {
                    final eventId = state.pathParameters['id']!;
                    return ChangeNotifierProvider(
                      create: (_) => EventOverviewViewModel(eventId),
                      child: EventOverviewScreen(eventId: eventId),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'chat/:channelId',
                      builder: (context, state) {
                        final eventId = state.pathParameters['id']!;
                        final channelId = state.pathParameters['channelId']!;
                        final name = state.extra as String? ?? 'Chat';
                        final isAnnouncement = name == 'Announcements';
                        return ChatScreen(
                          eventId: eventId,
                          channelId: channelId,
                          channelName: name,
                          isAnnouncement: isAnnouncement,
                        );
                      },
                    ),
                  ],
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
                  builder: (context, state) => SearchScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              initialLocation: '/profile-settings',
              routes: [
                GoRoute(
                  path: '/profile-settings',
                  builder: (context, state) => ProfileSettingsScreen(),
                  redirect: (context, state) {
                    final loggedIn = AuthService().currentUser() != null;
                    if (!loggedIn) return '/login';
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
        GoRoute(path: '/', redirect: (_, _) => '/event-list'),
      ],
    );

    FirebaseMessaging.instance.requestPermission();

    // Foreground-Listener: In-App anzeigen oder direkt navigieren
    FirebaseMessaging.onMessage.listen((msg) {
      final data = msg.data;
      final eventId = data['eventId'] as String?;
      final channelId = data['channelId'] as String?;
      final senderId = data['senderId'] as String?;
      final myUid = AuthService().currentUser()?.uid;

      // Eigene Nachrichten ignorieren
      if (senderId == myUid) return;

      // Falls gerade offen im selben Channel, nicht duplizieren
      if (!context.mounted) return;
      final notificationState = context.read<NotificationProvider>();
      if (eventId == notificationState.currentEventId &&
          channelId == notificationState.currentChannelId) {
        return;
      }

      // Lokale Notification anzeigen
      final notif = msg.notification;
      if (notif != null && notif.android != null) {
        flutterLocalNotificationsPlugin.show(
          eventId.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              announcementChannel.id,
              announcementChannel.name,
              channelDescription: announcementChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Tap-Handler, wenn App im Hintergrund war
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final data = msg.data;
      final eventId = data['eventId'] as String?;
      final channelId = data['channelId'] as String?;
      final senderId = data['senderId'] as String?;
      final myUid = AuthService().currentUser()?.uid;
      if (eventId != null && channelId != null && senderId != myUid) {
        _router.go(
          '/event-overview/$eventId/chat/$channelId',
          extra: 'Announcements',
        );
      }
    });

    // Cold-start-Navigation
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      final data = msg?.data;
      final eventId = data?['eventId'] as String?;
      final channelId = data?['channelId'] as String?;
      final senderId = data?['senderId'] as String?;
      final myUid = AuthService().currentUser()?.uid;
      if (msg != null &&
          eventId != null &&
          channelId != null &&
          senderId != myUid) {
        // Muss nach FrameCallback, damit Router ready ist
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _router.go(
            '/event-overview/$eventId/chat/$channelId',
            extra: 'Announcements',
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: ThemeData(
        listTileTheme: ListTileThemeData(
          subtitleTextStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
          ),
        ),
        searchBarTheme: SearchBarThemeData(
          shadowColor: WidgetStateColor.resolveWith(
            (states) => Colors.transparent,
          ),
        ),
      ),
    );
  }
}
