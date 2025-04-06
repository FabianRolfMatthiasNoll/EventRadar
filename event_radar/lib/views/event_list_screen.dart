import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/viewmodels/event_creation_viewmodel.dart';
import '../core/viewmodels/event_list_viewmodel.dart';
import 'event_creation_screen.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EventListViewModel>(
      create: (_) => EventListViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Events'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider(
                      create: (_) => EventCreationViewModel(),
                      child: const EventCreationScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<EventListViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              itemCount: viewModel.events.length,
              itemBuilder: (context, index) {
                final event = viewModel.events[index];
                double distance = viewModel.computeDistance(event.location);
                String formattedDate =
                DateFormat('dd.MM.yyyy').format(event.date);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      event.image.isNotEmpty
                          ? event.image
                          : event.title.substring(0, 1),
                    ),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    "0 Teilnehmer • ${distance.toStringAsFixed(1)} km • $formattedDate",
                    style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    // Hier könntest du z. B. in den Event-Detail Screen navigieren.
                  },
                );
              },
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.search), label: 'Suchen'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profil'),
          ],
          // currentIndex und onTap können hier erweitert werden.
        ),
      ),
    );
  }
}
