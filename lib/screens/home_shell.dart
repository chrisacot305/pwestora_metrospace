import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
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
  int _currentIndex = 0; // 0: Home, 1: Schedule, 2: Chat, 3: Me
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
            body: Center(child: CircularProgressIndicator(color: AppColors.electricBlue)),
          );
        }

        final lease = snapshot.data ?? {
          'tenant_id': 1,
          'rent': 12000.0,
          'property_name': 'Pwestora Commercial',
          'unit_label': 'Unit 302 • 3rd Floor',
          'open_tickets': 1,
        };

        final screens = [
          DashboardScreen(
            lease: lease,
            onRefresh: _recheckLease,
            onNavigateTab: (idx) => setState(() => _currentIndex = idx),
          ),
          ScheduleScreen(lease: lease),
          MessagesScreen(
            onNavigateTab: (idx) => setState(() => _currentIndex = idx),
          ),
          ProfileScreen(lease: lease),
        ];

        return Scaffold(
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex.clamp(0, screens.length - 1),
            children: screens,
          ),
          bottomNavigationBar: _buildCustomBottomDock(lease),
        );
      },
    );
  }

  Widget _buildCustomBottomDock(Map<String, dynamic>? lease) {
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
            // 1. Home
            _buildDockItem(
              index: 0,
              icon: Icons.home_rounded,
              outlineIcon: Icons.home_outlined,
              label: 'Home',
            ),

            // 2. Schedule
            _buildDockItem(
              index: 1,
              icon: Icons.calendar_month_rounded,
              outlineIcon: Icons.calendar_month_outlined,
              label: 'Schedule',
            ),

            // 3. Central Action Button: (+) Report
            _buildCentralActionButton(lease),

            // 4. Chat
            _buildDockItem(
              index: 2,
              icon: Icons.chat_bubble_rounded,
              outlineIcon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
            ),

            // 5. Me
            _buildDockItem(
              index: 3,
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
    required int index,
    required IconData icon,
    required IconData outlineIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 58,
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
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.electricBlue : AppColors.ink400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralActionButton(Map<String, dynamic>? lease) {
    return GestureDetector(
      onTap: () => _openReportFlow(lease),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: AppDecorations.electricGlowButton(radius: 999),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
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
