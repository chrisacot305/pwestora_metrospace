import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'tickets_list_screen.dart';
import 'ticket_detail_screen.dart';
import 'browse_screen.dart';
import 'payment_arrangement_screen.dart';
import 'violation_notice_sheet.dart';
import '../widgets/luxury_rent_card.dart';

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
  late Future<List<dynamic>> _arrangementsFuture;
  late Future<List<Map<String, dynamic>>> _violationsFuture;
  String _userName = '';
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = ApiService.fetchTickets();
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
      _arrangementsFuture = ApiService.fetchInstallmentRequests();
      _violationsFuture = ApiService.fetchViolations();
    });
    await Future.wait([_ticketsFuture, _arrangementsFuture, _violationsFuture]);
    widget.onRefresh();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
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


  void _openBrowseCatalog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BrowseScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final rentAmount = (widget.lease['rent'] as num?)?.toDouble() ?? 12000.0;
    final now = DateTime.now();
    final currentMonthName = _getMonthName(now.month);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.midnightNavy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOP HEADER (GREETING & PROFILE AVATAR) =================
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello ${_userName.isNotEmpty ? _userName.split(' ').first : 'Jake'}!',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111418),
                              letterSpacing: -0.9,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Let's manage your space today.",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(3); // Me / Profile tab
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C394B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'J',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ================= STACKED LUXURY RENT CARD =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LuxuryRentCard(
                  rentAmount: rentAmount,
                  dueDate: '30 $currentMonthName ${now.year}',
                  tenantName: _userName.isNotEmpty ? _userName : (widget.lease['tenant_name']?.toString() ?? 'Jake Peralta'),
                  onPayRent: () => _showPayRentSheet(rentAmount),
                ),
              ),

              // Active Restructuring Plan Strip (if any)
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isApproved ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isApproved ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                              size: 15,
                              color: isApproved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isApproved
                                    ? 'Restructuring Active: $plan approved'
                                    : 'Restructuring: $plan under lessor review',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isApproved ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Inline Violation Strip (if any)
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        await ViolationNoticeSheet.show(
                          context,
                          violation: latest,
                          isGated: false,
                        );
                        _refresh();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isEviction ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEviction ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEviction ? Icons.gavel_rounded : Icons.info_outline_rounded,
                              size: 15,
                              color: isEviction ? AppColors.error : const Color(0xFF1E6BFF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEviction
                                    ? 'Final Notice: Lease Default (View Notice)'
                                    : (strike == 2
                                        ? '2nd Notice: ₱500 Penalty Billed (View)'
                                        : 'Formal Notice: 1 Infraction on Record (View)'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isEviction ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF64748B)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // ================= QUICK ACTIONS ISLAND (4 BUTTONS) =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Payment Plan with Peso Sign
                      _buildIslandActionItem(
                        iconWidget: const Text(
                          '₱',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111418),
                          ),
                        ),
                        label: 'Payment Plan',
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
                      ),

                      // 2. Receipts with Official Receipt Icon
                      _buildIslandActionItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Receipts',
                        onTap: () => _showReceiptsModal(rentAmount),
                      ),

                      // 3. Explore with Storefront Icon
                      _buildIslandActionItem(
                        icon: Icons.storefront_outlined,
                        label: 'Explore',
                        onTap: _openBrowseCatalog,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ================= MANAGE EXPENSES / RECENT ACTIVITY =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: 'Tenant Updates' and 'View All'
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tenant Updates',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111418),
                              letterSpacing: -0.4,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TicketsListScreen()),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E6BFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 1. Dynamic Monthly Stall Rent Row
                      _buildActivityRow(
                        icon: Icons.receipt_long_rounded,
                        title: 'Monthly Stall Rent',
                        subtitle: 'Due: 30 $currentMonthName ${now.year} • Active Lease',
                        trailing: '₱${_formatMoney(rentAmount)}',
                        onTap: () => _showPayRentSheet(rentAmount),
                      ),

                      // 2. Dynamic Maintenance Tickets from Backend
                      FutureBuilder<List<dynamic>>(
                        future: _ticketsFuture,
                        builder: (context, snapshot) {
                          final tickets = snapshot.data ?? [];
                          if (tickets.isEmpty) return const SizedBox.shrink();

                          return Column(
                            children: tickets.take(3).map((t) {
                              final ticket = t as Map<String, dynamic>;
                              return Column(
                                children: [
                                  const Divider(color: Color(0xFFF3F4F6), height: 24),
                                  _buildTicketActivityRow(ticket),
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),

                      // 3. Dynamic Payment Restructuring Arrangement from Backend (if any)
                      FutureBuilder<List<dynamic>>(
                        future: _arrangementsFuture,
                        builder: (context, snapshot) {
                          final reqs = snapshot.data ?? [];
                          if (reqs.isEmpty) return const SizedBox.shrink();

                          final latest = reqs.first as Map<String, dynamic>;
                          final plan = latest['plan_label'] ?? 'Installment Plan';
                          final status = (latest['status'] ?? 'pending').toString();
                          final isApproved = status.toLowerCase() == 'approved';

                          return Column(
                            children: [
                              const Divider(color: Color(0xFFF3F4F6), height: 24),
                              _buildActivityRow(
                                icon: isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                                title: 'Payment Arrangement',
                                subtitle: '$plan • $status',
                                trailing: isApproved ? 'Active' : 'Pending',
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
                              ),
                            ],
                          );
                        },
                      ),

                      // 4. Dynamic Infraction Notice from Backend (if any)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _violationsFuture,
                        builder: (context, snapshot) {
                          final violations = snapshot.data ?? [];
                          if (violations.isEmpty) return const SizedBox.shrink();

                          final latest = violations.first;
                          final strike = latest['strike']?.toString() ?? '1';

                          return Column(
                            children: [
                              const Divider(color: Color(0xFFF3F4F6), height: 24),
                              _buildActivityRow(
                                icon: Icons.gavel_rounded,
                                title: 'Notice of Infraction (Strike $strike)',
                                subtitle: latest['rule_name']?.toString() ?? 'Lessor Policy Update',
                                trailing: 'Notice',
                                onTap: () async {
                                  await ViolationNoticeSheet.show(
                                    context,
                                    violation: latest,
                                    isGated: false,
                                  );
                                  _refresh();
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),


              // Bottom padding for dock
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildIslandActionItem({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: iconWidget ??
                    Icon(
                      icon,
                      color: const Color(0xFF111418),
                      size: 21,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFF111418), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111418),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8A92A0),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111418),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketActivityRow(Map<String, dynamic> ticket) {
    final title = ticket['title']?.toString() ?? 'Maintenance Request';
    final category = ticket['category']?.toString() ?? 'General';
    final ticketId = '#SL-${(ticket['id'] ?? '00001').toString().padLeft(5, '0')}';
    final stageNum = (ticket['stage'] as num?)?.toInt() ?? 0;
    final stageName = stageNum < kTicketStages.length ? kTicketStages[stageNum] : 'In Progress';
    final icon = _getReportCategoryIcon(category.isNotEmpty ? category : title);

    final isResolved = stageNum >= kTicketStages.length - 1;

    return _buildActivityRow(
      icon: icon,
      title: title,
      subtitle: '$ticketId • $stageName',
      trailing: isResolved ? 'Resolved' : 'In Progress',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(ticket: ticket),
          ),
        ).then((_) => _refresh());
      },
    );
  }

  void _showPayRentSheet(double rentAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pay Monthly Rent',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnightNavy,
                  ),
                ),
                Text(
                  '₱${_formatMoney(rentAmount)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.midnightNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select preferred payment channel or request a plan:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            _buildPaymentOptionTile(
              icon: Icons.account_balance_rounded,
              title: 'Bank Transfer / InstaPay',
              subtitle: 'BDO, BPI, UnionBank, Security Bank',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bank account details copied to clipboard.')),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildPaymentOptionTile(
              icon: Icons.phone_android_rounded,
              title: 'E-Wallet',
              subtitle: 'GCash, Maya, ShopeePay',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('E-wallet payment portal opening...')),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildPaymentOptionTile(
              icon: Icons.handshake_outlined,
              title: 'Request Payment Plan',
              subtitle: 'Split rent into manageable installments',
              isHighlight: true,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PaymentArrangementScreen(
                      lease: widget.lease,
                      onArrangementSubmitted: () => _refresh(),
                    ),
                  ),
                ).then((_) => _refresh());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlight ? AppColors.warmIvory : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlight ? const Color(0xFFE2C987) : const Color(0xFFE2E8F0),
            width: isHighlight ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isHighlight ? AppColors.midnightNavy : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isHighlight ? Colors.white : AppColors.midnightNavy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  void _showReceiptsModal(double rentAmount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Receipts & Billing History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'View and download your official payment receipts:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.midnightNavy, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Billing Statement',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.midnightNavy),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₱${_formatMoney(rentAmount)} • Generated for this cycle',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Statement generated successfully.')),
                      );
                    },
                    child: const Text('View', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Previous Month Official Receipt',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.midnightNavy),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'OR #2026-09-0041 • Paid & Verified',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading official receipt PDF...')),
                      );
                    },
                    child: const Text('Download', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

