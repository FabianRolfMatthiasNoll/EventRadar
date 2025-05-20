import 'package:event_radar/views/chat_screen.dart';
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
import 'views/event_creation_screen.dart';
import 'views/event_list_screen.dart';
import 'views/event_map_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// Hintergrund-Handler für FCM
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel announcementChannel =
    AndroidNotificationChannel(
      'event_announcements', // id
      'Event Announcements', // name
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

  // 1) Initialisiere flutter_local_notifications mit Default-Icon
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('ic_launcher');
  final InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse resp) {
      // hier könntest du Payload verarbeiten, falls nötig
    },
  );

  // 2) Notification-Channel für Android erstellen
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(announcementChannel);

  // Hintergrund-Nachrichten-Handler registrieren
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

    // Router-Konfiguration
    _router = GoRouter(
      initialLocation: '/event-list',
      navigatorKey: _rootNavigatorKey,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
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
        GoRoute(path: '/', redirect: (context, state) => '/event-list'),
      ],
    );

    FirebaseMessaging.instance.requestPermission();

    // FOREGROUND-Listener: In-App-Benachrichtigungen anzeigen
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final data = msg.data;
      final eventId = data['eventId'] as String?;
      final channelId = data['channelId'] as String?;
      final senderId = data['senderId'] as String?;
      final myUid = AuthService().currentUser()?.uid;

      // a) Eigene Nachrichten ignorieren
      if (senderId != null && senderId == myUid) return;

      // b) Wenn ich gerade im Announcement-Channel dieses Events bin, ignorieren
      final notifState = context.read<NotificationProvider>();
      if (eventId == notifState.currentEventId &&
          channelId == notifState.currentChannelId) {
        return;
      }

      // c) Nur die letzte Notification pro Event zeigen
      final notifId = eventId.hashCode;

      // d) Eigentliche Anzeige
      final notification = msg.notification;
      final android = notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notifId, // ersetzt vorherige Notification für dieses Event!
          notification.title,
          notification.body,
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

    // 2) Tap-Handler (App im Hintergrund oder komplett geschlossen)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final data = msg.data;
      final eventId = data['eventId'] as String?;
      final channelId = data['channelId'] as String?;
      final senderId = data['senderId'] as String?;
      final myUid = AuthService().currentUser()?.uid;

      if (eventId == null || channelId == null || senderId == myUid) return;

      // use the router, not context.go
      _router.go(
        '/event-overview/$eventId/chat/$channelId',
        extra: 'Announcements',
      );
    });

    // when cold‐start via tap
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
