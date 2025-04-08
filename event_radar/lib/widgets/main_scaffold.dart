import 'package:flutter/material.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int currentIndex;
  final void Function(int)? onBottomNavTap;
  final List<Widget>? appBarActions;

  const MainScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.currentIndex = 0,
    this.onBottomNavTap,
    this.appBarActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(title),
        actions: appBarActions,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onBottomNavTap ??
                (index) {
              // Global navigation handling.
              // For example, you could do:
              if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              } else if (index == 1) {
                Navigator.pushNamedAndRemoveUntil(context, '/map-events', (route) => false);
              } else if (index == 2) {
                Navigator.pushNamedAndRemoveUntil(context, '/search', (route) => false);
              }
            },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}
