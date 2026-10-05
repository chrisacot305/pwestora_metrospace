import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../widgets/scooped_nav_bar.dart';
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
  int _applicantAppsTick = 0;
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
                  key: ValueKey('apps_tab_$_applicantAppsTick'),
                  onLeaseMayHaveChanged: _recheckLease,
                  isTab: true,
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
  /// Featuring a smooth scooped cradle with elevated Report button and Navy Blue active/hover states.
  Widget _buildTenantDock(Map<String, dynamic> lease, int currentIndex) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
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
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              height: 84,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Custom sculpted white cradle bar
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ScoopedCradlePainter(
                        color: Colors.white,
                        shadowColor: const Color(0xFF0A1832),
                        cornerRadius: 32,
                        cradleWidth: 86,
                        cradleDepth: 34,
                        barTop: 18,
                      ),
                    ),
                  ),
                  // 2. Navigation items
                  Positioned(
                    top: 18,
                    left: 6,
                    right: 6,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ScoopedNavItem(
                            index: 0,
                            currentIndex: currentIndex,
                            icon: Icons.home_rounded,
                            outlineIcon: Icons.home_outlined,
                            label: 'Home',
                            onTap: (idx) => setState(() => _currentIndex = idx),
                          ),
                        ),
                        Expanded(
                          child: ScoopedNavItem(
                            index: 1,
                            currentIndex: currentIndex,
                            icon: Icons.calendar_month_rounded,
                            outlineIcon: Icons.calendar_month_outlined,
                            label: 'Schedule',
                            onTap: (idx) => setState(() => _currentIndex = idx),
                          ),
                        ),
                        // Center gap reserved for the elevated action button
                        const SizedBox(width: 68),
                        Expanded(
                          child: ScoopedNavItem(
                            index: 2,
                            currentIndex: currentIndex,
                            icon: Icons.chat_bubble_rounded,
                            outlineIcon: Icons.chat_bubble_outline_rounded,
                            label: 'Chat',
                            onTap: (idx) => setState(() => _currentIndex = idx),
                          ),
                        ),
                        Expanded(
                          child: ScoopedNavItem(
                            index: 3,
                            currentIndex: currentIndex,
                            icon: Icons.person_rounded,
                            outlineIcon: Icons.person_outline_rounded,
                            label: 'Me',
                            onTap: (idx) => setState(() => _currentIndex = idx),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 3. Elevated circular button and Report title resting in the scooped cradle
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openReportFlow(lease),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.electricBlue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0A1832).withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: AppColors.electricBlue.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Report',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A1832),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom Dock for Prospective Tenants / Applicants: Browse, Applications, Me
  Widget _buildApplicantDock(int currentIndex) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
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
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
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
                  Expanded(
                    child: ScoopedNavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.explore_rounded,
                      outlineIcon: Icons.explore_outlined,
                      label: 'Browse',
                      onTap: (idx) => setState(() => _currentIndex = idx),
                    ),
                  ),
                  Expanded(
                    child: ScoopedNavItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.assignment_rounded,
                      outlineIcon: Icons.assignment_outlined,
                      label: 'Applications',
                      onTap: (idx) => setState(() {
                        _currentIndex = idx;
                        _applicantAppsTick++;
                      }),
                    ),
                  ),
                  Expanded(
                    child: ScoopedNavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.person_rounded,
                      outlineIcon: Icons.person_outline_rounded,
                      label: 'Me',
                      onTap: (idx) => setState(() => _currentIndex = idx),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
