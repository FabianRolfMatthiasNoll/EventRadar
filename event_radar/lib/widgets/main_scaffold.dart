import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavbarContainer extends StatelessWidget {
  final Widget? floatingActionButton;
  final StatefulNavigationShell navigationShell;

  void _onTap(index) {
    navigationShell.goBranch(
      index,
      // Go to initial location if tapped item is already active
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  const NavbarContainer({
    super.key,
    this.floatingActionButton,
    required this.navigationShell,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
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

class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    this.showBackButton = true,
    required this.title,
    this.body,
    this.appBarActions = const [],
    this.floatingActionButton,
  });
  final bool showBackButton;
  final String title;
  final Widget? body;
  final List<Widget> appBarActions;
  final Widget? floatingActionButton;

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
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}
