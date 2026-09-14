import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'browse_screen.dart';
import 'my_applications_screen.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'messages_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late Future<Map<String, dynamic>?> _leaseFuture;

  @override
  void initState() {
    super.initState();
    _leaseFuture = ApiService.fetchLeaseStatus();
  }

  /// Re-checks lease status without needing to log out
  Future<void> _recheckLease() async {
    final result = await ApiService.fetchLeaseStatus();
    if (!mounted) return;
    setState(() {
      _leaseFuture = Future.value(result);
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _leaseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final lease = snapshot.data; // null = applicant/prospect

        if (lease != null) {
          final screens = [
            DashboardScreen(lease: lease, onRefresh: _recheckLease),
            BrowseScreen(onLeaseMayHaveChanged: _recheckLease),
            const MessagesScreen(),
            const ProfileScreen(),
          ];
          return Scaffold(
            body: IndexedStack(index: _index, children: screens),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront),
                    label: 'Browse',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: 'Messages',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Account',
                  ),
                ],
              ),
            ),
          );
        }

        final screens = [
          BrowseScreen(onLeaseMayHaveChanged: _recheckLease),
          MyApplicationsScreen(onLeaseMayHaveChanged: _recheckLease),
          const ProfileScreen(),
        ];
        return Scaffold(
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Applications',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
