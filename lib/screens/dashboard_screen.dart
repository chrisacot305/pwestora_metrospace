import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'tickets_list_screen.dart';
import 'ticket_detail_screen.dart';
import 'payment_arrangement_screen.dart';
import 'rent_payment_screen.dart';
import 'violation_notice_sheet.dart';
import 'receipts_history_screen.dart';
import 'messages_screen.dart';
import 'my_applications_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/luxury_rent_card.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> lease;
  final VoidCallback onRefresh;
  final Function(int)? onNavigateTab;
  final List<Map<String, dynamic>>? allLeases;
  final int activeLeaseIndex;
  final Function(int index, Map<String, dynamic> lease)? onLeaseChanged;

  const DashboardScreen({
    super.key,
    required this.lease,
    required this.onRefresh,
    this.onNavigateTab,
    this.allLeases,
    this.activeLeaseIndex = 0,
    this.onLeaseChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<dynamic>> _ticketsFuture;
  late Future<List<dynamic>> _arrangementsFuture;
  late Future<List<Map<String, dynamic>>> _violationsFuture;
  late Future<String> _rentStatusFuture;
  String _userName = '';
  String _companyName = '';
  bool _gateChecked = false;

  // GlobeOne-style multi-account switcher state
  List<Map<String, dynamic>> _allLeases = [];
  int _selectedLeaseIndex = 0;
  int _carouselPageIndex = 0;
  late PageController _cardPageController;

  @override
  void initState() {
    super.initState();
    _selectedLeaseIndex = widget.activeLeaseIndex;
    _carouselPageIndex = widget.activeLeaseIndex;
    _cardPageController = PageController(
      viewportFraction: 0.94,
      initialPage: widget.activeLeaseIndex,
    );
    if (widget.allLeases != null && widget.allLeases!.isNotEmpty) {
      _allLeases = widget.allLeases!;
    }
    _ticketsFuture = ApiService.fetchTickets();
    _arrangementsFuture = ApiService.fetchInstallmentRequests();
    _violationsFuture = ApiService.fetchViolations();
    _rentStatusFuture = ApiService.getDemoRentStatus();
    _loadUserName();
    _loadAllLeases();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingViolations();
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allLeases != null && widget.allLeases != oldWidget.allLeases) {
      setState(() {
        _allLeases = widget.allLeases!;
      });
    }
    if (widget.activeLeaseIndex != _selectedLeaseIndex && _cardPageController.hasClients) {
      setState(() {
        _selectedLeaseIndex = widget.activeLeaseIndex;
        _carouselPageIndex = widget.activeLeaseIndex;
      });
      _cardPageController.jumpToPage(widget.activeLeaseIndex);
    }
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllLeases() async {
    try {
      final list = (widget.allLeases != null && widget.allLeases!.isNotEmpty)
          ? widget.allLeases!
          : await ApiService.fetchAllActiveLeases(initialLease: widget.lease);
      if (mounted) {
        setState(() {
          _allLeases = list;
          if (_selectedLeaseIndex >= _allLeases.length) {
            _selectedLeaseIndex = 0;
            _carouselPageIndex = 0;
          }
        });
        if (_allLeases.isNotEmpty && _selectedLeaseIndex < _allLeases.length) {
          widget.onLeaseChanged?.call(_selectedLeaseIndex, _allLeases[_selectedLeaseIndex]);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allLeases = [widget.lease];
        });
      }
    }
  }

  Map<String, dynamic> get _activeLease {
    if (_allLeases.isNotEmpty && _selectedLeaseIndex < _allLeases.length) {
      return _allLeases[_selectedLeaseIndex];
    }
    return widget.lease;
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
    final company = await ApiService.getCompanyName();
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        if (company != null && company.isNotEmpty) _companyName = company;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _ticketsFuture = ApiService.fetchTickets();
      _arrangementsFuture = ApiService.fetchInstallmentRequests();
      _violationsFuture = ApiService.fetchViolations();
      _rentStatusFuture = ApiService.getDemoRentStatus();
    });
    await Future.wait([_ticketsFuture, _arrangementsFuture, _violationsFuture, _loadAllLeases()]);
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






  Widget _buildExpandBusinessCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF0B1B3D)]
              : [const Color(0xFF0B1B3D), const Color(0xFF162D63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E6BFF).withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1B3D).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6BFF).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E6BFF).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_business_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'BUSINESS EXPANSION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Expand to Another Space',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Browse prime retail stalls, kiosks, and commercial units to open your next branch.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  height: 1.35,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onNavigateTab?.call(2),
              icon: const Icon(Icons.explore_rounded, size: 16),
              label: const Text('Browse Available Stalls'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rentAmount = (_activeLease['rent'] as num?)?.toDouble() ?? 12000.0;
    final now = DateTime.now();
    final currentMonthName = _getMonthName(now.month);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.midnightNavy,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOP HEADER (PWESTORA BRAND & PROFILE AVATAR) =================
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
                    // Brand Logo + Pwestora Name (Prominent & bold)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'img/Frame 2.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pwestora',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF111418),
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Chat Button (Option 6: Minimalist Outlined Rounded Balloon on Floating Disc)
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MessagesScreen(
                              onNavigateTab: widget.onNavigateTab,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : const Color(0xFF0F172A).withValues(alpha: 0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            SvgPicture.asset(
                              'img/comment-alt-dots.svg',
                              width: 21,
                              height: 21,
                              colorFilter: ColorFilter.mode(
                                isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F172A),
                                BlendMode.srcIn,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ================= STACKED LUXURY RENT CARD CAROUSEL (PAGEVIEW) =================
              FutureBuilder<String>(
                future: _rentStatusFuture,
                builder: (context, rentStatusSnap) {
                  final rentStatus = rentStatusSnap.data ?? 'normal';
                  final isOverdue = rentStatus == 'overdue';
                  final isGracePeriod = rentStatus == 'grace_period';
                  final overdueSubtext = isOverdue ? 'October + November' : null;

                  return FutureBuilder<List<dynamic>>(
                    future: _arrangementsFuture,
                    builder: (context, snapshot) {
                      final reqs = snapshot.data ?? [];
                      final latest = reqs.isNotEmpty ? (reqs.first as Map<String, dynamic>) : null;
                      final status = (latest?['status'] ?? '').toString().toLowerCase();
                      final plan = latest?['plan_label'] ?? '2 payments';
                      final isApproved = status == 'approved';
                      final isPending = status == 'pending';
                      final hasRestructuring = !isOverdue && (isApproved || isPending);
                      final currentPart = (latest?['current_part'] as int?) ?? 1;
                      final effectiveDueDate = hasRestructuring && isApproved && currentPart > 1
                          ? '15 Nov ${now.year}'
                          : '30 $currentMonthName ${now.year}';

                      final leaseList = _allLeases.isNotEmpty ? _allLeases : [widget.lease];

                      return Column(
                        children: [
                          SizedBox(
                            height: 232,
                            child: PageView.builder(
                              controller: _cardPageController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: leaseList.length + 1,
                              onPageChanged: (idx) {
                                setState(() {
                                  _carouselPageIndex = idx;
                                  if (idx < leaseList.length) {
                                    _selectedLeaseIndex = idx;
                                    widget.onLeaseChanged?.call(idx, leaseList[idx]);
                                  }
                                });
                              },
                              itemBuilder: (context, index) {
                                if (index == leaseList.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: _buildExpandBusinessCard(isDark),
                                  );
                                }

                                final leaseItem = leaseList[index];
                                final itemRent = (leaseItem['rent'] as num?)?.toDouble() ?? 12000.0;
                                final itemEffectiveRent = isOverdue ? (itemRent * 2 + 500) : itemRent;
                                final itemCompany = (leaseItem['business_name'] ?? '').toString().trim();
                                final itemEffectiveCompany = itemCompany.isNotEmpty
                                    ? itemCompany
                                    : (_companyName.isNotEmpty ? _companyName : '');
                                final itemTenantName = itemEffectiveCompany.isNotEmpty
                                    ? itemEffectiveCompany
                                    : (_userName.isNotEmpty ? _userName : (leaseItem['tenant_name']?.toString() ?? 'Tenant'));
                                final itemPropertyName = (leaseItem['property_name'] ?? 'Commercial Stall').toString();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: LuxuryRentCard(
                                    rentAmount: itemEffectiveRent,
                                    dueDate: effectiveDueDate,
                                    propertyName: itemPropertyName,
                                    tenantName: itemTenantName,
                                    activeArrangement: hasRestructuring ? latest : null,
                                    isOverdue: isOverdue,
                                    isGracePeriod: isGracePeriod,
                                    graceDaysRemaining: 5,
                                    overdueSubtext: overdueSubtext,
                                    onArrangementTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PaymentArrangementScreen(
                                            lease: leaseItem,
                                            onArrangementSubmitted: () => _refresh(),
                                          ),
                                        ),
                                      ).then((_) => _refresh());
                                    },
                                    onPayRent: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => RentPaymentScreen(
                                            lease: leaseItem,
                                            rentAmount: itemRent,
                                            isOverdue: isOverdue,
                                            activeArrangement: hasRestructuring ? latest : null,
                                            onPaymentSubmitted: () => _refresh(),
                                          ),
                                        ),
                                      ).then((_) => _refresh());
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Animated Carousel Dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(leaseList.length + 1, (i) {
                              final isSelected = i == _carouselPageIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isSelected ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1E6BFF)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          // Active Restructuring Plan Strip (if any)
                          if (hasRestructuring)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentArrangementScreen(
                                        lease: _activeLease,
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
                            ),
                        ],
                      );
                    },
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
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark ? Border.all(color: const Color(0xFF262626), width: 1) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
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
                        isDark: isDark,
                        iconWidget: Text(
                          '₱',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF111418),
                          ),
                        ),
                        label: 'Payment Plan',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PaymentArrangementScreen(
                                lease: _activeLease,
                                onArrangementSubmitted: () => _refresh(),
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                      ),

                      // 2. Receipts with Official Receipt Icon
                      _buildIslandActionItem(
                        isDark: isDark,
                        icon: Icons.receipt_long_rounded,
                        label: 'Receipts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptsHistoryScreen(
                                lease: _activeLease,
                                rentAmount: rentAmount,
                              ),
                            ),
                          );
                        },
                      ),

                      // 3. Applications with Assignment Icon (My Applications for business expansion)
                      _buildIslandActionItem(
                        isDark: isDark,
                        icon: Icons.assignment_outlined,
                        label: 'Applications',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MyApplicationsScreen(
                                isTab: false,
                                onLeaseMayHaveChanged: _refresh,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                      ),

                      // 4. Maintenance with build_circle_outlined Icon
                      _buildIslandActionItem(
                        isDark: isDark,
                        icon: Icons.build_circle_outlined,
                        label: 'Maintenance',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TicketsListScreen(),
                            ),
                          ).then((_) => _refresh());
                        },
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
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isDark ? Border.all(color: const Color(0xFF262626), width: 1) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
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
                          Text(
                            'Tenant Updates',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF111418),
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
                        isDark: isDark,
                        icon: Icons.receipt_long_rounded,
                        title: 'Monthly Stall Rent',
                        subtitle: 'Due: 30 $currentMonthName ${now.year} • Active Lease',
                        trailing: '₱${_formatMoney(rentAmount)}',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RentPaymentScreen(
                                lease: _activeLease,
                                rentAmount: rentAmount,
                                onPaymentSubmitted: () => _refresh(),
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
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
                                  Divider(color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6), height: 24),
                                  _buildTicketActivityRow(ticket, isDark: isDark),
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
                              Divider(color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6), height: 24),
                              _buildActivityRow(
                                isDark: isDark,
                                icon: isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                                title: 'Payment Arrangement',
                                subtitle: '$plan • $status',
                                trailing: isApproved ? 'Active' : 'Pending',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentArrangementScreen(
                                        lease: _activeLease,
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
                              Divider(color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6), height: 24),
                              _buildActivityRow(
                                isDark: isDark,
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
    bool isDark = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: isDark ? Border.all(color: const Color(0xFF262626), width: 1) : null,
              ),
              child: Center(
                child: iconWidget ??
                    Icon(
                      icon,
                      color: isDark ? Colors.white : const Color(0xFF111418),
                      size: 21,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
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
    bool isDark = false,
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
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(13),
                border: isDark ? Border.all(color: const Color(0xFF262626), width: 0.8) : null,
              ),
              child: Icon(icon, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF111418), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111418),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF8A92A0),
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
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111418),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketActivityRow(Map<String, dynamic> ticket, {bool isDark = false}) {
    final title = ticket['title']?.toString() ?? 'Maintenance Request';
    final category = ticket['category']?.toString() ?? 'General';
    final ticketId = '#SL-${(ticket['id'] ?? '00001').toString().padLeft(5, '0')}';
    final stageNum = (ticket['stage'] as num?)?.toInt() ?? 0;
    final stageName = stageNum < kTicketStages.length ? kTicketStages[stageNum] : 'In Progress';
    final icon = _getReportCategoryIcon(category.isNotEmpty ? category : title);

    final isResolved = stageNum >= kTicketStages.length - 1;

    return _buildActivityRow(
      isDark: isDark,
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

}


