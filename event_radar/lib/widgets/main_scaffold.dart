import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavbarScaffold extends StatelessWidget {
  final Widget? floatingActionButton;
  final StatefulNavigationShell navigationShell;

  void _onTap(index) {
    navigationShell.goBranch(
      index,
      // Go to initial location if tapped item is already active
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  const NavbarScaffold({
    super.key,
    this.floatingActionButton,
    required this.navigationShell,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: floatingActionButton,
      // Only display the bottom navigation bar if showBottomNavigation is true
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karte'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Suche'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class TopBarScaffold extends StatelessWidget {
  const TopBarScaffold({
    super.key,
    this.showBackButton = true,
    required this.title,
    this.body,
    this.appBarActions = const [],
  });
  final bool showBackButton;
  final String title;
  final Widget? body;
  final List<Widget> appBarActions;

  Widget? leadingIcon(BuildContext context) {
    // Only show the back button if showBackButton is true AND there's a route to pop.
    if (showBackButton && context.canPop()) {
      return IconButton(icon: BackButtonIcon(), onPressed: () => context.pop());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: leadingIcon(context),
        title: Text(title),
        actions: appBarActions,
      ),
      body: body,
    );
  }
}

class FABScaffold extends StatelessWidget {
  const FABScaffold({super.key, required this.floatingActionButton, this.body});

  final FloatingActionButton floatingActionButton;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(floatingActionButton: floatingActionButton, body: body);
  }
}
