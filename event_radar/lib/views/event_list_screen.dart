import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/models/event.dart';
import '../core/providers/location_provider.dart';
import '../core/viewmodels/event_list_viewmodel.dart';
import '../widgets/event_tile.dart';
import '../widgets/main_scaffold.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = Provider.of<LocationProvider>(context);
    final userPosition = locationProvider.currentPosition;
    if (userPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final isLoggedIn = user != null;

        return MainScaffold(
          title: "Meine Events",
          floatingActionButton:
              isLoggedIn
                  ? FloatingActionButton(
                    onPressed: () => context.go("/event-list/create-event"),
                    child: const Icon(Icons.add),
                  )
                  : null,
          body:
              isLoggedIn
                  ? StreamBuilder<List<Event>>(
                    stream:
                        Provider.of<EventListViewModel>(
                          context,
                          listen: false,
                        ).userEventsStream,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text("Fehler: ${snap.error}"));
                      }
                      final events = snap.data;
                      if (events == null || events.isEmpty) {
                        return const Center(
                          child: Text("Keine Events gefunden."),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => locationProvider.updateLocation(),
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder:
                              (ctx, i) => EventTile(
                                event: events[i],
                                userPosition: userPosition,
                              ),
                        ),
                      );
                    },
                  )
                  : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Du hast keine eingetragenen Events. "
                            "Logge dich ein, um Events zu erstellen oder beizutreten.",
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go("/login"),
                            child: const Text("Einloggen"),
                          ),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }
}
