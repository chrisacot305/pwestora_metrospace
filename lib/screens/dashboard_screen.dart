import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'tickets_list_screen.dart';
import 'ticket_detail_screen.dart';
import 'browse_screen.dart';
import 'property_detail_screen.dart';
import 'payment_arrangement_screen.dart';
import 'violation_notice_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> lease;
  final VoidCallback onRefresh;
  final Function(int)? onNavigateTab;

  const DashboardScreen({
    super.key,
    required this.lease,
    required this.onRefresh,
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> _ticketsFuture;
  late Future<List<dynamic>> _propertiesFuture;
  late Future<List<dynamic>> _arrangementsFuture;
  late Future<List<Map<String, dynamic>>> _violationsFuture;
  String _userName = 'Juan Dela Cruz';
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = ApiService.fetchTickets();
    _propertiesFuture = ApiService.fetchProperties();
    _arrangementsFuture = ApiService.fetchInstallmentRequests();
    _violationsFuture = ApiService.fetchViolations();
    _loadUserName();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingViolations();
    });
  }

  Future<void> _checkPendingViolations() async {
    if (_gateChecked) return;
    _gateChecked = true;
    try {
      final violations = await _violationsFuture;
      if (!mounted) return;
      // Find the highest unacknowledged violation
      final unack = violations.where((v) => (v['acknowledged'] == 0 || v['acknowledged'] == false)).toList();
      if (unack.isNotEmpty) {
        final target = unack.first;
        await ViolationNoticeSheet.show(
          context,
          violation: target,
          isGated: true,
        );
        _refresh();
      }
    } catch (_) {}
  }

  Future<void> _loadUserName() async {
    final name = await ApiService.getUserName();
    if (name != null && name.isNotEmpty && mounted) {
      setState(() => _userName = name);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _ticketsFuture = ApiService.fetchTickets();
      _propertiesFuture = ApiService.fetchProperties();
      _arrangementsFuture = ApiService.fetchInstallmentRequests();
      _violationsFuture = ApiService.fetchViolations();
    });
    await Future.wait([_ticketsFuture, _propertiesFuture, _arrangementsFuture, _violationsFuture]);
    widget.onRefresh();
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getShortMonth(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[(month - 1).clamp(0, 11)];
  }

  String _formatMoney(num val) {
    final str = val.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  IconData _getReportCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('elect') || cat.contains('light') || cat.contains('power')) {
      return Icons.bolt_rounded; // Lightning for electrical
    } else if (cat.contains('plumb') || cat.contains('water') || cat.contains('leak') || cat.contains('pipe')) {
      return Icons.water_drop_rounded;
    } else if (cat.contains('comfort') || cat.contains('cr') || cat.contains('toilet') || cat.contains('bath')) {
      return Icons.bathtub_outlined;
    } else if (cat.contains('ac') || cat.contains('hvac') || cat.contains('cool')) {
      return Icons.ac_unit_rounded;
    } else if (cat.contains('door') || cat.contains('lock') || cat.contains('key')) {
      return Icons.lock_outline_rounded;
    } else if (cat.contains('clean') || cat.contains('trash') || cat.contains('pest')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.build_rounded;
  }

  Color _getReportCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('rent') || cat.contains('pay')) {
      return AppColors.tagRent;
    } else if (cat.contains('building') || cat.contains('amenit') || cat.contains('event')) {
      return AppColors.tagBuilding;
    }
    return AppColors.tagMaintenance;
  }

  void _openBrowseCatalog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BrowseScreen()),
    );
  }

  Future<void> _openLessorWebpage() async {
    final uri = Uri.parse('https://www.pwestora.com/index.php');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open https://www.pwestora.com/index.php')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  void _openPropertyDetail(int propertyId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PropertyDetailScreen(propertyId: propertyId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rentAmount = (widget.lease['rent'] as num?)?.toDouble() ?? 12000.0;
    final now = DateTime.now();
    final currentMonthName = _getMonthName(now.month);
    final rentDueLabel = '$currentMonthName Rent';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.electricBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOP HERO WITH DARK NAVY BACKGROUND =================
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF071739),
                        Color(0xFF0F2C69),
                        Color(0xFF1E6BFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Glowing Circle Top-Right (Matching Payment Restructuring screen)
                      Positioned(
                        top: -35,
                        right: -35,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.13),
                          ),
                        ),
                      ),
                      // Secondary Subtle Soft Glow Circle
                      Positioned(
                        bottom: -25,
                        right: 80,
                        child: Container(
                          width: 95,
                          height: 95,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E6BFF).withValues(alpha: 0.18),
                          ),
                        ),
                      ),

                      // Header Content
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 20,
                          left: 22,
                          right: 22,
                          bottom: 54, // Clean fixed bottom padding
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Tappable User Avatar (Links to Profile/Me screen)
                            InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                if (widget.onNavigateTab != null) {
                                  widget.onNavigateTab!(3); // Me tab
                                }
                              },
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.8),
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                                child: Center(
                                  child: Text(
                                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // 2. Text Greeting & Username
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getTimeBasedGreeting(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _userName,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= OVERLAPPING WHITE RENT CARD =================
              Transform.translate(
                offset: const Offset(0, -32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF081836).withValues(alpha: 0.09),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFF081836).withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Rent Icon & Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C244F),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Rent',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0B1B3D),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                                    SizedBox(width: 3),
                                    Text(
                                      'Active',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Second Row: Dynamic Rent Month
                          Text(
                            rentDueLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Third Row: ₱12,000 + Due in 5 days
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '₱${_formatMoney(rentAmount)}',
                                style: const TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF07142E),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              // Due in 5 days pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Due in 5 days',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E6BFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Fourth Row: Due Date on left + "Request Arrangement" link on right
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Due $currentMonthName 30, ${now.year}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              // Request Arrangement Action Link
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentArrangementScreen(
                                        lease: widget.lease,
                                        onArrangementSubmitted: () => _refresh(),
                                      ),
                                    ),
                                  ).then((_) => _refresh());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.handshake_outlined, size: 13, color: Color(0xFF1E6BFF)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Request Arrangement',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E6BFF),
                                        ),
                                      ),
                                      SizedBox(width: 1),
                                      Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF1E6BFF)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Fifth Row: Active / Pending Restructuring Plan Badge (if any)
                          FutureBuilder<List<dynamic>>(
                            future: _arrangementsFuture,
                            builder: (context, snapshot) {
                              final reqs = snapshot.data ?? [];
                              if (reqs.isEmpty) return const SizedBox.shrink();

                              final latest = reqs.first as Map<String, dynamic>;
                              final status = (latest['status'] ?? 'pending').toString().toLowerCase();
                              final plan = latest['plan_label'] ?? '2 payments';
                              final isApproved = status == 'approved';
                              final isPending = status == 'pending';

                              if (!isApproved && !isPending) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PaymentArrangementScreen(
                                          lease: widget.lease,
                                          onArrangementSubmitted: () => _refresh(),
                                        ),
                                      ),
                                    ).then((_) => _refresh());
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isApproved ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                                          size: 13,
                                          color: isApproved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isApproved
                                                ? 'Restructuring Active: $plan approved'
                                                : 'Restructuring: $plan under lessor review',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isApproved ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Optional Inline Notice Strip (Only shows when an infraction is active)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _violationsFuture,
                            builder: (context, snapshot) {
                              final violations = snapshot.data ?? [];
                              if (violations.isEmpty) return const SizedBox.shrink();

                              final latest = violations.first;
                              final strike = latest['strike'] is int
                                  ? latest['strike'] as int
                                  : int.tryParse(latest['strike']?.toString() ?? '1') ?? 1;
                              final isEviction = strike >= 3;

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    await ViolationNoticeSheet.show(
                                      context,
                                      violation: latest,
                                      isGated: false,
                                    );
                                    _refresh();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isEviction ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isEviction ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isEviction ? Icons.gavel_rounded : Icons.info_outline_rounded,
                                          size: 13,
                                          color: isEviction ? AppColors.error : const Color(0xFF1E6BFF),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isEviction
                                                ? 'Final Notice: Lease Default (View Notice)'
                                                : (strike == 2
                                                    ? '2nd Notice: ₱500 Penalty Billed (View)'
                                                    : 'Formal Notice: 1 Infraction on Record (View)'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isEviction ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF64748B)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // Sixth Row: Long Full-Width Pay Rent Button Below Details
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Payment gateway: Ready to proceed to payment options.'),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: AppDecorations.glowButton(radius: 16),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pay Rent • ₱${_formatMoney(rentAmount)}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
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

              // Small offset gap before Schedule
              const SizedBox(height: 4),

              // ================= UPCOMING SCHEDULE SECTION =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Schedule',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1B3D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(1); // Schedule tab index
                        }
                      },
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E6BFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Schedule Card Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A1832).withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FutureBuilder<List<dynamic>>(
                    future: _ticketsFuture,
                    builder: (context, snapshot) {
                      final tickets = snapshot.data ?? [];
                      final openTickets = tickets.where((t) {
                        final stage = (t['stage'] as num?)?.toInt() ?? 0;
                        return stage < 7;
                      }).toList();

                      final scheduleItems = <Widget>[];

                      // 1. Rent Due item
                      final endOfMonthDay = DateTime(now.year, now.month + 1, 0).day;
                      scheduleItems.add(
                        _buildScheduleItem(
                          month: _getShortMonth(now.month),
                          day: '$endOfMonthDay',
                          title: 'Rent Due',
                          subtitle: '₱${_formatMoney(rentAmount)} • Monthly Rent',
                          markerColor: const Color(0xFF10B981),
                        ),
                      );

                      // 2. Open maintenance tickets
                      for (int i = 0; i < openTickets.length.clamp(0, 2); i++) {
                        final t = openTickets[i] as Map<String, dynamic>;
                        final createdAtStr = t['created_at']?.toString() ?? '';
                        final dt = DateTime.tryParse(createdAtStr) ?? now;
                        final stage = (t['stage'] as num?)?.toInt() ?? 0;
                        final stageName = stage < kTicketStages.length ? kTicketStages[stage] : 'In Progress';
                        final contractor = t['contractor']?.toString();
                        final subtitle = (contractor != null && contractor.isNotEmpty)
                            ? 'Contractor: $contractor'
                            : '${widget.lease['unit_label'] ?? 'Unit'} • $stageName';

                        scheduleItems.add(
                          const Divider(color: Color(0xFFF1F4F9), height: 1, indent: 70),
                        );
                        scheduleItems.add(
                          _buildScheduleItem(
                            month: _getShortMonth(dt.month),
                            day: '${dt.day}',
                            title: t['title']?.toString() ?? 'Maintenance Request',
                            subtitle: subtitle,
                            markerColor: _getReportCategoryColor(t['category']?.toString() ?? 'maintenance'),
                          ),
                        );
                      }

                      return Column(
                        children: scheduleItems,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= ACTIVE REPORT SECTION (WITH DYNAMIC CATEGORY ICON) =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Report',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1B3D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TicketsListScreen()),
                        );
                      },
                      child: const Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E6BFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Active Report Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FutureBuilder<List<dynamic>>(
                  future: _ticketsFuture,
                  builder: (context, snapshot) {
                    final tickets = snapshot.data ?? [];
                    final openTickets = tickets.where((t) {
                      final stage = (t['stage'] as num?)?.toInt() ?? 0;
                      return stage < 7;
                    }).toList();

                    if (openTickets.isEmpty) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TicketsListScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0A1832).withValues(alpha: 0.04),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Color(0xFF10B981),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'All Systems Normal',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0B1B3D),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'No active maintenance reports',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final latest = openTickets.first as Map<String, dynamic>;
                    final categoryStr = latest['category']?.toString() ?? 'Maintenance';
                    final title = latest['title'] ?? 'Maintenance Request';
                    final ticketId = '#SL-${(latest['id'] ?? '00001').toString().padLeft(5, '0')}';
                    final stageNum = (latest['stage'] as num?)?.toInt() ?? 0;
                    final stageName = stageNum < kTicketStages.length ? kTicketStages[stageNum] : 'In Progress';
                    final reportColor = _getReportCategoryColor(categoryStr.isNotEmpty ? categoryStr : title);

                    // Accurate, matched category icon
                    final matchedIcon = _getReportCategoryIcon(categoryStr.isNotEmpty ? categoryStr : title);

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TicketDetailScreen(ticket: latest),
                          ),
                        ).then((_) => _refresh());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A1832).withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Category color tinted circle with matching colored icon (e.g. orange for maintenance)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: reportColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                matchedIcon,
                                color: reportColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Ticket info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0B1B3D),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$ticketId  •  $stageName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ================= ANNOUNCEMENTS SECTION =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Announcements',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1B3D),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Announcements Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A1832).withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Neutral squircle with speaker icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.campaign_outlined,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Text
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Building Announcements',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0B1B3D),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'No new announcements today',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= PROPERTY DISCOVERY FEED =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Explore Prime Spaces',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B1B3D),
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Looking for your next branch or kiosk?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _openBrowseCatalog,
                      child: Row(
                        children: const [
                          Text(
                            'Browse all',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E6BFF),
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF1E6BFF)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal Swipeable Property Feed
              FutureBuilder<List<dynamic>>(
                future: _propertiesFuture,
                builder: (context, snapshot) {
                  final properties = snapshot.data ?? [];
                  if (properties.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    height: 165,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: properties.length.clamp(0, 6),
                      itemBuilder: (context, index) {
                        final prop = properties[index] as Map<String, dynamic>;
                        return _buildPropertyFeedCard(prop);
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // "Want to be a lessor? Click here" Gradient Banner Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildLessorCard(),
              ),

              // Bottom padding for dock
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyFeedCard(Map<String, dynamic> prop) {
    final title = prop['name'] ?? 'Commercial Space';
    final type = prop['type'] ?? 'Retail';
    final address = prop['address'] ?? 'Bacolod City';
    final rent = (prop['asking_rent'] as num?)?.toDouble() ?? 8500.0;
    final id = (prop['id'] as num?)?.toInt() ?? 1;
    final coverPhoto = prop['cover_photo'] as String?;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPropertyDetail(id),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1832).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with real cover photo + Type Badge & Price Pill
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 98,
                      width: double.infinity,
                      child: coverPhoto != null && coverPhoto.isNotEmpty
                          ? Image.network(
                              coverPhoto,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderPhoto(type),
                            )
                          : _buildPlaceholderPhoto(type),
                    ),

                    // Top dark gradient overlay for badge readability
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Property Type Chip (Top Left)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1B3D).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    // Price Tag (Bottom Right)
                    Positioned(
                      bottom: 6,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E6BFF),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        child: Text(
                          '₱${_formatMoney(rent)}/mo',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Property details
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1B3D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF64748B)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPhoto(String type) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0B1B3D),
        gradient: LinearGradient(
          colors: [Color(0xFF0F2552), Color(0xFF08152E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(type),
          color: Colors.white.withValues(alpha: 0.6),
          size: 38,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'food stall':
      case 'food & dining':
        return Icons.restaurant_rounded;
      case 'retail':
        return Icons.storefront_rounded;
      case 'office':
        return Icons.business_rounded;
      case 'storage':
        return Icons.inventory_2_rounded;
      default:
        return Icons.store_rounded;
    }
  }

  Widget _buildLessorCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF071739),
            Color(0xFF0F2C69),
            Color(0xFF1E6BFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E6BFF).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openLessorWebpage,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.real_estate_agent_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Want to be a lessor?',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'List your spaces & reach verified tenants',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Click here',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF071739),
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_outward_rounded,
                        size: 11,
                        color: Color(0xFF071739),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleItem({
    required String month,
    required String day,
    required String title,
    required String subtitle,
    required Color markerColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Date box
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1B3D),
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1B3D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Colored vertical pill marker & line
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: markerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1B3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

