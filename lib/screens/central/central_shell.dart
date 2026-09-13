import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'central_home_screen.dart';
import 'my_agenda_screen.dart';
import 'my_events_screen.dart';

class CentralShell extends StatefulWidget {
  const CentralShell({super.key});

  @override
  State<CentralShell> createState() => _CentralShellState();
}

class _CentralShellState extends State<CentralShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: 'Découvrir',
    ),
    NavigationDestination(
      icon: Icon(Icons.confirmation_number_outlined),
      selectedIcon: Icon(Icons.confirmation_number_rounded),
      label: 'Mes events',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      selectedIcon: Icon(Icons.event_note_rounded),
      label: 'Agenda',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  static const _pages = [
    CentralHomeScreen(),
    MyEventsScreen(),
    MyAgendaScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 920) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    extended: constraints.maxWidth >= 1180,
                    groupAlignment: -.45,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                    destinations: _destinations
                        .map(
                          (destination) => NavigationRailDestination(
                            icon: destination.icon,
                            selectedIcon: destination.selectedIcon,
                            label: Text(destination.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: IndexedStack(index: _index, children: _pages),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
