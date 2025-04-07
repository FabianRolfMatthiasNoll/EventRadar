import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/viewmodels/event_list_viewmodel.dart';
import '../core/models/event.dart';
import '../core/utils/initials_helper.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({Key? key}) : super(key: key);

  Future<void> _refreshEvents(BuildContext context) async {
    await Provider.of<EventListViewModel>(context, listen: false).fetchEvents();
  }

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
                Navigator.pushNamed(context, '/create-event').then((_) {
                  _refreshEvents(context);
                });
              },
            ),
          ],
        ),
        body: Consumer<EventListViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return RefreshIndicator(
              onRefresh: () => _refreshEvents(context),
              child: ListView.builder(
                itemCount: viewModel.events.length,
                itemBuilder: (context, index) {
                  final Event event = viewModel.events[index];
                  final double distance = viewModel.computeDistance(event.location);
                  final String formattedDate = DateFormat('dd.MM.yyyy – HH:mm').format(event.date);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (event.image.isNotEmpty && event.image.startsWith('http'))
                          ? NetworkImage(event.image)
                          : null,
                      child: (event.image.isEmpty || !event.image.startsWith('http'))
                          ? Text(getInitials(event.title))
                          : null,
                    ),
                    title: Text(event.title),
                    subtitle: Text(
                      "0 Teilnehmer • ${distance.toStringAsFixed(1)} km • $formattedDate",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      // TODO: Navigation zum Event Details dann hier
                    },
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Suchen'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
