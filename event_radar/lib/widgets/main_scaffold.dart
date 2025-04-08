import 'package:flutter/material.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final int? currentIndex;
  final bool showBackButton;
  final Widget? floatingActionButton;
  final void Function(int)? onBottomNavTap;
  final List<Widget>? appBarActions;
  final bool showBottomNavigation;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    this.currentIndex,
    this.showBackButton = true,
    this.floatingActionButton,
    this.onBottomNavTap,
    this.appBarActions,
    this.showBottomNavigation = true,
  });
  // TODO: The Scaffolding should be placed on a layer. All screens that are below that
  // layer have it above it they dont. Then this can be a stateful widget keeping its state.
  // Probably also more performance style. => Will do that tomorrow
  // Or build it so that the Bottompart CAN (not MUST) be switched upon instantiation then we
  // could handle different setups like later in a chat and still have the top bar?
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Only show the back button if showBackButton is true AND there's a route to pop.
        leading: showBackButton && Navigator.canPop(context)
            ? IconButton(
          icon: const BackButtonIcon(),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        title: Text(title),
        actions: appBarActions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      // Only display the bottom navigation bar if showBottomNavigation is true
      bottomNavigationBar: showBottomNavigation
          ? BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // If currentIndex is null, set to 0 but style it to match unselected state. I know its dirty
        // but a good way before the restructuring with the stateful bar then we could just have the last
        // selected for example
        currentIndex: currentIndex ?? 0,
        onTap: onBottomNavTap ??
                (index) {
              // Global navigation handling.
              if (index == 0) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              } else if (index == 1) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/map-events', (route) => false);
              } else if (index == 2) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/search', (route) => false);
              } else if (index == 3) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/profile-settings', (route) => false);
              }
            },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karte'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Suche'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        // If currentIndex is null, set selected and unselected colors to the same value.
        selectedItemColor: currentIndex == null ? Theme.of(context).unselectedWidgetColor : Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
      )
          : null,
    );
  }
}
