import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'tickets_list_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final Map<String, dynamic>? lease;
  const ScheduleScreen({super.key, this.lease});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _currentMonth;
  late int _selectedDay;
  bool _showAll = true; // Controls "View all" vs "View less"
  bool _loading = true;

  List<Map<String, dynamic>> _events = [];
  List<dynamic> _apiTickets = [];
  List<dynamic> _apiPayments = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDay = now.day;
    _fetchScheduleData();
  }

  Future<void> _fetchScheduleData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.fetchTickets(),
        ApiService.fetchPayments(),
      ]);
      if (mounted) {
        setState(() {
          _apiTickets = results[0];
          _apiPayments = results[1];
          _buildEventsForCurrentMonth();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _buildEventsForCurrentMonth();
          _loading = false;
        });
      }
    }
  }

  String _getShortMonth(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[(month - 1).clamp(0, 11)];
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('elect') || cat.contains('light') || cat.contains('power')) {
      return Icons.bolt_rounded;
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

  void _buildEventsForCurrentMonth() {
    final list = <Map<String, dynamic>>[];
    final unit = widget.lease?['unit_label'] ?? 'Unit';
    final rentNum = (widget.lease?['rent'] as num?)?.toDouble() ?? 12000.0;

    // 1. Live Maintenance Tickets from API
    for (final t in _apiTickets) {
      final createdAtStr = t['created_at']?.toString() ?? '';
      DateTime? dt = DateTime.tryParse(createdAtStr);
      dt ??= DateTime.now();

      if (dt.year == _currentMonth.year && dt.month == _currentMonth.month) {
        final categoryStr = t['category']?.toString() ?? 'Maintenance';
        final stage = (t['stage'] as num?)?.toInt() ?? 0;
        final stageLabel = stage < kTicketStages.length ? kTicketStages[stage] : 'In Progress';
        final contractor = t['contractor']?.toString();
        final subtitle = (contractor != null && contractor.isNotEmpty)
            ? 'Contractor: $contractor • $stageLabel'
            : '$unit • $stageLabel';

        list.add({
          'id': 'ticket_${t['id']}',
          'title': t['title']?.toString() ?? 'Maintenance Request',
          'subtitle': subtitle,
          'day': dt.day,
          'month': _getShortMonth(dt.month),
          'category': 'maintenance',
          'categoryLabel': 'Maintenance',
          'color': AppColors.tagMaintenance,
          'icon': _getCategoryIcon(categoryStr),
        });
      }
    }

    // 2. Live Payments from API
    for (final p in _apiPayments) {
      final paidAtStr = p['paid_at']?.toString() ?? '';
      DateTime? dt = DateTime.tryParse(paidAtStr);
      if (dt != null && dt.year == _currentMonth.year && dt.month == _currentMonth.month) {
        final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        final method = p['method']?.toString() ?? 'Payment';
        final note = p['note']?.toString();
        final title = (note != null && note.isNotEmpty) ? note : 'Rent Payment';

        list.add({
          'id': 'pay_${p['id']}',
          'title': title,
          'subtitle': '₱${_formatMoney(amount)} • $method',
          'day': dt.day,
          'month': _getShortMonth(dt.month),
          'category': 'rent',
          'categoryLabel': 'Rent',
          'color': AppColors.tagRent,
          'icon': Icons.account_balance_wallet_rounded,
        });
      }
    }

    // 3. Rent Due date from active lease
    if (widget.lease != null) {
      final lastDayOfMonth = _daysInMonth(_currentMonth);
      list.add({
        'id': 'rent_due_${_currentMonth.year}_${_currentMonth.month}',
        'title': 'Rent Due',
        'subtitle': '₱${_formatMoney(rentNum)} • Monthly Rent',
        'day': lastDayOfMonth,
        'month': _getShortMonth(_currentMonth.month),
        'category': 'rent',
        'categoryLabel': 'Rent',
        'color': AppColors.tagRent,
        'icon': Icons.account_balance_wallet_rounded,
      });
    }

    // Sort by day
    list.sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
    _events = list;
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      _buildEventsForCurrentMonth();
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstWeekdayOffset(DateTime date) {
    // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _showAll
        ? _events
        : _events.where((e) => e['day'] == _selectedDay).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header: Title and Subtitle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1B3D),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'See what\'s happening and when.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= FULL CALENDAR (NO CARD BACKGROUND, NO EXTRA PADDING) =================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Month Navigation Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF0B1B3D), size: 26),
                          onPressed: () => _changeMonth(-1),
                        ),
                        Text(
                          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B1B3D),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF0B1B3D), size: 26),
                          onPressed: () => _changeMonth(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Days of Week (Sun - Sat) full width
                    Row(
                      children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          .map((d) => Expanded(
                                child: Text(
                                  d,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 6),

                    // Full-width Day Grid
                    _buildLargeCalendarGrid(),

                    const SizedBox(height: 14),

                    // Category Legend Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem('Rent', AppColors.tagRent),
                        _buildLegendItem('Maintenance', AppColors.tagMaintenance),
                        _buildLegendItem('Building', AppColors.tagBuilding),
                        _buildLegendItem('Other', AppColors.tagOther),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Section Header: Upcoming Events & View all/less toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Events',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1B3D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAll = !_showAll;
                        });
                      },
                      child: Text(
                        _showAll ? 'View less' : 'View all',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E6BFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Events List
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.electricBlue),
                  ),
                ),
              )
            else if (filteredEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 38, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 10),
                        Text(
                          'No events on Day $_selectedDay',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap "View all" to see all scheduled events for this month.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = filteredEvents[index];
                      return _buildEventCard(event);
                    },
                    childCount: filteredEvents.length,
                  ),
                ),
              ),

            // Bottom space for floating dock
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeCalendarGrid() {
    final totalDays = _daysInMonth(_currentMonth);
    final offset = _firstWeekdayOffset(_currentMonth);
    final totalCells = offset + totalDays;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.05,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < offset) {
          return const SizedBox.shrink();
        }

        final day = index - offset + 1;
        final isSelected = day == _selectedDay;
        final dayEvents = _events.where((e) => e['day'] == day).toList();

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
              _showAll = false;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0B1B3D) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF0B1B3D),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              if (dayEvents.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dayEvents.take(3).map((e) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 4.5,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: e['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                )
              else
                const SizedBox(height: 4.5),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final color = event['color'] as Color;
    final icon = event['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  event['month'],
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${event['day']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1B3D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Icon squircle
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1B3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event['subtitle'],
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
