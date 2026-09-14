import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'tickets_list_screen.dart';
import 'ticket_detail_screen.dart';
import 'lease_contract_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> lease;
  final VoidCallback onRefresh;
  const DashboardScreen({super.key, required this.lease, required this.onRefresh});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: (DateTime.now().weekday - 1)));
  int _selectedDayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
  late Future<List<dynamic>> _ticketsFuture;

  final List<String> _dayNames = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final List<String> _shortDays = const ['M', 'T', 'W', 'TH', 'F', 'S', 'S'];

  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _ticketsFuture = ApiService.fetchTickets();
  }

  Future<void> _refresh() async {
    setState(() {
      _ticketsFuture = ApiService.fetchTickets();
    });
    await _ticketsFuture;
    widget.onRefresh();
  }

  // Helper to get the 7 days of the current week
  List<DateTime> _getWeekDays() {
    return List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));
  }

  // Generate dynamic tenant items for each day based on backend tickets and lease data
  List<Map<String, dynamic>> _getItemsForDay(DateTime date, List<dynamic> tickets) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final weekday = date.weekday; // 1 = Mon, 7 = Sun

    List<Map<String, dynamic>> items = [];

    // 1. Rent Due (Calculated from active backend lease)
    final rentAmount = (widget.lease['rent'] as num?)?.toDouble() ?? 0;
    if (weekday == 1 && rentAmount > 0) {
      items.add({
        'type': 'due',
        'title': 'Monthly Lease Rent Due',
        'subtitle': '${widget.lease['property_name'] ?? 'Commercial Space'} · ₱${_formatMoney(rentAmount)}',
        'time': '5:00 PM Deadline',
        'icon': Icons.payments_rounded,
        'color': AppColors.primary,
        'bg': AppColors.accentSoft,
        'tag': 'Rent Payment',
        'ticket': null,
      });
    }

    // 2. Real Backend Maintenance Reports from tickets_list.php
    for (int idx = 0; idx < tickets.length; idx++) {
      final t = tickets[idx] as Map<String, dynamic>;
      final stage = (t['stage'] as num?)?.toInt() ?? 0;
      final stageName = stage < kTicketStages.length ? kTicketStages[stage] : 'Stage $stage';
      final category = (t['category'] ?? 'general').toString().toLowerCase();
      final icon = kCategoryIcons[category] ?? Icons.build_rounded;
      final priority = (t['priority'] ?? 'medium').toString().toLowerCase();
      final (pColor, pBg) = kPriorityColors[priority] ?? (AppColors.primary, AppColors.accentSoft);

      DateTime? ticketDate;
      if (t['created_at'] != null) {
        ticketDate = DateTime.tryParse(t['created_at'].toString());
      }

      bool matchesDay = false;
      if (ticketDate != null) {
        matchesDay = ticketDate.year == date.year &&
            ticketDate.month == date.month &&
            ticketDate.day == date.day;
      } else {
        matchesDay = (idx % 7) == (weekday - 1);
      }

      if (matchesDay) {
        final contractor = t['contractor']?.toString();
        final hasContractor = contractor != null && contractor.isNotEmpty;

        items.add({
          'type': 'maintenance',
          'title': t['title']?.toString() ?? 'Reported Issue',
          'subtitle': hasContractor
              ? 'Contractor: $contractor · $stageName'
              : 'Stage: $stageName · Report #MT-${t['id']}',
          'time': hasContractor ? '10:00 AM - 12:00 PM' : 'Ticket #MT-${t['id']}',
          'icon': icon,
          'color': pColor,
          'bg': pBg,
          'tag': priority.toUpperCase(),
          'ticket': t,
        });
      }
    }

    // 3. Building Announcements
    if (weekday == 5) {
      items.add({
        'type': 'announcement',
        'title': 'Mall Power Generator Annual Load Test',
        'subtitle': 'Building-wide brief switchover test (approx. 10 mins)',
        'time': '10:00 PM',
        'icon': Icons.bolt_rounded,
        'color': AppColors.accent,
        'bg': AppColors.accentSoft,
        'tag': 'Notice',
        'ticket': null,
      });
    }

    if (items.isEmpty) {
      items.add({
        'type': 'clear',
        'title': isToday ? 'All Clear for Today' : 'No Scheduled Activities',
        'subtitle': 'No pending rent dues, maintenance visits, or building notices.',
        'time': isToday ? 'Today' : 'Clear',
        'icon': Icons.check_circle_rounded,
        'color': AppColors.success,
        'bg': AppColors.successSoft,
        'tag': 'Good Standing',
        'ticket': null,
      });
    }

    return items;
  }

  bool _hasEventOnDate(DateTime d, List<dynamic> tickets) {
    final weekday = d.weekday;
    if (weekday == 1 || weekday == 5) return true;
    for (int idx = 0; idx < tickets.length; idx++) {
      final t = tickets[idx] as Map<String, dynamic>;
      DateTime? ticketDate;
      if (t['created_at'] != null) {
        ticketDate = DateTime.tryParse(t['created_at'].toString());
      }
      if (ticketDate != null) {
        if (ticketDate.year == d.year && ticketDate.month == d.month && ticketDate.day == d.day) {
          return true;
        }
      } else if ((idx % 7) == (weekday - 1)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final rent = (widget.lease['rent'] as num?)?.toDouble() ?? 0;
    final term = (widget.lease['term_months'] as num?)?.toInt() ?? 0;
    final openTickets = (widget.lease['open_tickets'] as num?)?.toInt() ?? 0;

    final weekDays = _getWeekDays();
    final selectedDate = weekDays[_selectedDayIndex];

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                children: [
                  // App Bar / Top Navigation
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset('img/Frame 2.png', fit: BoxFit.contain),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // TOP HERO SECTION (Full-Width Gradient Header with Watermark)
                  Stack(
                    children: [
                      Positioned(
                        right: -15,
                        top: -10,
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Active Lease Pill + Good Standing Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LeaseContractScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'ACTIVE LEASE',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                                      SizedBox(width: 6),
                                      Text(
                                        'Good Standing',
                                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    const SizedBox(height: 18),

                    // Property Name
                    Text(
                      widget.lease['property_name']?.toString() ?? 'pwestora',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Address / Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15, color: AppColors.tint),
                        const SizedBox(width: 4),
                        Text(
                          widget.lease['property_address']?.toString() ?? 'dss',
                          style: const TextStyle(
                            color: AppColors.tint,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Monthly Rent & Lessor Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MONTHLY RENT',
                              style: TextStyle(
                                color: AppColors.tint,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${_formatMoney(rent)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'LESSOR',
                              style: TextStyle(
                                color: AppColors.tint,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.lease['lessor_name']?.toString() ?? 'Secret',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

              // CURVED SHEET CONTAINER (Overlapping Card Area)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: FutureBuilder<List<dynamic>>(
                  future: _ticketsFuture,
                  builder: (context, snapshot) {
                    final tickets = snapshot.data ?? [];
                    final selectedItems = _getItemsForDay(selectedDate, tickets);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CALENDAR CARD (Matching User Drawing Exactly)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF102340).withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Month Header + Navigation Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_monthNames[selectedDate.month - 1]} ${selectedDate.year}',
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.ink900,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Reported Maintenance & Leases Dues',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      // Previous Week Button (<)
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          setState(() {
                                            _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
                                          });
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentSoft,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Next Week Button (>)
                                      InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          setState(() {
                                            _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
                                          });
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentSoft,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // 7-DAY CAPSULE CONTAINER (Matching mockup with soft light-blue background)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F0FA), // Soft light-blue background
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: List.generate(7, (i) {
                                    final d = weekDays[i];
                                    final isSelected = i == _selectedDayIndex;
                                    final hasEvent = _hasEventOnDate(d, tickets);

                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedDayIndex = i),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary : Colors.transparent,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.primary.withValues(alpha: 0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _shortDays[i],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                                  color: isSelected ? Colors.white : AppColors.ink700,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${d.day}',
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: isSelected ? Colors.white : AppColors.ink900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : (hasEvent ? AppColors.primary : Colors.transparent),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // SELECTED DAY EVENT CONTAINER (Grey placeholder box in user mockup)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F3F7),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_dayNames[_selectedDayIndex]} Schedule',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.ink900,
                                          ),
                                        ),
                                        Text(
                                          '${_monthNames[selectedDate.month - 1]} ${selectedDate.day}',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    ...selectedItems.map((item) {
                                      final isClear = item['type'] == 'clear';
                                      final ticketData = item['ticket'] as Map<String, dynamic>?;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          onTap: ticketData != null
                                              ? () => Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => TicketDetailScreen(ticket: ticketData),
                                                    ),
                                                  )
                                              : null,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: (item['color'] as Color).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(item['icon'] as IconData, size: 18, color: item['color'] as Color),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['title'] as String,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: item['color'] as Color,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item['subtitle'] as String,
                                                      style: const TextStyle(fontSize: 11, color: AppColors.ink700),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (!isClear)
                                                Text(
                                                  item['time'] as String,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: item['color'] as Color,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // TWO METRIC BOXES (Matching the 2 white cards at the bottom of user mockup)
                        Row(
                          children: [
                            // Card 1: Open Tickets
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TicketsListScreen()),
                                ),
                                child: Container(
                                  height: 130,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF102340).withValues(alpha: 0.04),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
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
                                            width: 38,
                                            height: 38,
                                            decoration: AppDecorations.squircle(color: AppColors.warningSoft),
                                            child: const Icon(Icons.build_outlined, size: 18, color: AppColors.warning),
                                          ),
                                          const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.ink300),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'OPEN TICKETS',
                                            style: TextStyle(fontSize: 10, color: AppColors.ink500, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$openTickets',
                                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink900),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Card 2: Lease Term Duration
                            Expanded(
                              child: Container(
                                height: 130,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF102340).withValues(alpha: 0.04),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: AppDecorations.squircle(color: AppColors.accentSoft),
                                      child: const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'LEASE TERM',
                                          style: TextStyle(fontSize: 10, color: AppColors.ink500, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$term Months',
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink900),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
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

  String _formatMoney(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}