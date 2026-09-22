import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'browse_screen.dart';
import 'my_applications_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'ticket_create_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  late Future<Map<String, dynamic>?> _leaseFuture;

  @override
  void initState() {
    super.initState();
    _leaseFuture = ApiService.fetchLeaseStatus();
  }

  Future<void> _recheckLease() async {
    final result = await ApiService.fetchLeaseStatus();
    if (!mounted) return;
    setState(() {
      _leaseFuture = Future.value(result);
    });
  }

  void _openReportFlow(Map<String, dynamic>? lease) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TicketCreateScreen(lease: lease),
      ),
    );
    if (created == true) {
      _recheckLease();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _leaseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.electricBlue),
            ),
          );
        }

        final lease = snapshot.data;
        final hasActiveLease = lease != null;

        // Build screens based on user state
        final List<Widget> screens = hasActiveLease
            ? [
                DashboardScreen(
                  lease: lease,
                  onRefresh: _recheckLease,
                  onNavigateTab: (idx) => setState(() => _currentIndex = idx),
                ),
                ScheduleScreen(lease: lease),
                MessagesScreen(
                  onNavigateTab: (idx) => setState(() => _currentIndex = idx),
                ),
                ProfileScreen(
                  lease: lease,
                  onNavigateTab: (idx) => setState(() => _currentIndex = idx),
                  onLeaseMayHaveChanged: _recheckLease,
                ),
              ]
            : [
                BrowseScreen(onLeaseMayHaveChanged: _recheckLease),
                MyApplicationsScreen(
                  onLeaseMayHaveChanged: _recheckLease,
                  isTab: true,
                ),
                MessagesScreen(
                  onNavigateTab: (idx) => setState(() => _currentIndex = idx),
                ),
                ProfileScreen(
                  lease: null,
                  onNavigateTab: (idx) => setState(() => _currentIndex = idx),
                  onLeaseMayHaveChanged: _recheckLease,
                ),
              ];

        final safeIndex = _currentIndex.clamp(0, screens.length - 1);

        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          bottomNavigationBar: hasActiveLease
              ? _buildTenantDock(lease, safeIndex)
              : _buildApplicantDock(safeIndex),
        );
      },
    );
  }

  /// Bottom Dock for Active Tenants: Home, Schedule, (+) Report, Chat, Me
  Widget _buildTenantDock(Map<String, dynamic> lease, int currentIndex) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 18, top: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg.withValues(alpha: 0.0),
            AppColors.bg.withValues(alpha: 0.95),
            AppColors.bg,
          ],
        ),
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1832).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF0A1832).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDockItem(
              targetIndex: 0,
              currentIndex: currentIndex,
              icon: Icons.home_rounded,
              outlineIcon: Icons.home_outlined,
              label: 'Home',
            ),
            _buildDockItem(
              targetIndex: 1,
              currentIndex: currentIndex,
              icon: Icons.calendar_month_rounded,
              outlineIcon: Icons.calendar_month_outlined,
              label: 'Schedule',
            ),
            _buildCentralReportButton(lease),
            _buildDockItem(
              targetIndex: 2,
              currentIndex: currentIndex,
              icon: Icons.chat_bubble_rounded,
              outlineIcon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
            ),
            _buildDockItem(
              targetIndex: 3,
              currentIndex: currentIndex,
              icon: Icons.person_rounded,
              outlineIcon: Icons.person_outline_rounded,
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Dock for Prospective Tenants / Applicants: Browse, Applications, Chat, Me
  Widget _buildApplicantDock(int currentIndex) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 18, top: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg.withValues(alpha: 0.0),
            AppColors.bg.withValues(alpha: 0.95),
            AppColors.bg,
          ],
        ),
      ),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1832).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF0A1832).withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDockItem(
              targetIndex: 0,
              currentIndex: currentIndex,
              icon: Icons.explore_rounded,
              outlineIcon: Icons.explore_outlined,
              label: 'Browse',
            ),
            _buildDockItem(
              targetIndex: 1,
              currentIndex: currentIndex,
              icon: Icons.assignment_rounded,
              outlineIcon: Icons.assignment_outlined,
              label: 'Applications',
            ),
            _buildDockItem(
              targetIndex: 2,
              currentIndex: currentIndex,
              icon: Icons.chat_bubble_rounded,
              outlineIcon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
            ),
            _buildDockItem(
              targetIndex: 3,
              currentIndex: currentIndex,
              icon: Icons.person_rounded,
              outlineIcon: Icons.person_outline_rounded,
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required int targetIndex,
    required int currentIndex,
    required IconData icon,
    required IconData outlineIcon,
    required String label,
  }) {
    final isSelected = currentIndex == targetIndex;

    return InkWell(
      onTap: () => setState(() => _currentIndex = targetIndex),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? icon : outlineIcon,
              color: isSelected ? AppColors.electricBlue : AppColors.ink400,
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.electricBlue : AppColors.ink400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralReportButton(Map<String, dynamic>? lease) {
    return GestureDetector(
      onTap: () => _openReportFlow(lease),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppDecorations.electricGlowButton(radius: 999),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Report',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.electricBlue,
            ),
          ),
        ],
      ),
    );
  }
}
