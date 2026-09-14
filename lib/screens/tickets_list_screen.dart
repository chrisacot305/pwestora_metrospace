import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'ticket_detail_screen.dart';
import 'ticket_create_screen.dart';

const kTicketStages = [
  'Submitted',
  'Under Review',
  'Approved',
  'Contractor Assigned',
  'Scheduled',
  'In Progress',
  'Inspection',
  'Completed',
];

const kCategoryIcons = {
  'plumbing': Icons.water_drop_outlined,
  'electrical': Icons.bolt_outlined,
  'structural': Icons.construction_outlined,
  'internet': Icons.wifi,
  'hvac': Icons.ac_unit,
  'cleaning': Icons.auto_awesome_outlined,
  'security': Icons.shield_outlined,
  'lighting': Icons.lightbulb_outline,
};

const kPriorityColors = {
  'low': (AppColors.success, AppColors.successSoft),
  'medium': (AppColors.accent, AppColors.accentSoft),
  'high': (AppColors.warning, AppColors.warningSoft),
  'urgent': (AppColors.error, AppColors.errorSoft),
};

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  late Future<List<dynamic>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchTickets();
  }

  Future<void> _refresh() async {
    setState(() => _future = ApiService.fetchTickets());
    await _future;
  }

  void _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TicketCreateScreen()),
    );
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Maintenance & Reports'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Report',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: AppDecorations.squircle(color: AppColors.errorSoft),
                      child: const Icon(Icons.error_outline, size: 32, color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  ),
                ],
              );
            }

            final tickets = (snapshot.data ?? []).cast<Map<String, dynamic>>();
            final total = tickets.length;
            final inProgress = tickets.where((t) {
              final stage = (t['stage'] as num?)?.toInt() ?? 0;
              return stage < kTicketStages.length - 1;
            }).length;
            final resolved = tickets.where((t) {
              final stage = (t['stage'] as num?)?.toInt() ?? 0;
              return stage == kTicketStages.length - 1;
            }).length;

            final resolveRate = total > 0 ? ((resolved / total) * 100).toInt() : 100;

            final filteredTickets = tickets.where((t) {
              final stage = (t['stage'] as num?)?.toInt() ?? 0;
              final isDone = stage == kTicketStages.length - 1;
              if (_filter == 'active') return !isDone;
              if (_filter == 'completed') return isDone;
              return true;
            }).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
              children: [
                // Arto Plus Executive Report Analytics Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Radial Progress Ring (Arto Plus Style)
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: total > 0 ? (resolved / total) : 1.0,
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                            ),
                            Center(
                              child: Text(
                                '$resolveRate%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RESOLUTION SCORE',
                              style: TextStyle(
                                color: AppColors.tint,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Property Health Report',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$resolved of $total maintenance reports fully resolved',
                              style: const TextStyle(color: AppColors.tint, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Arto Plus Metric Summary Grid
                Row(
                  children: [
                    Expanded(
                      child: _ArtoStatCard(
                        title: 'Total Reports',
                        count: '$total',
                        icon: Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        trend: 'Active Log',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ArtoStatCard(
                        title: 'In Progress',
                        count: '$inProgress',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        trend: 'Action Required',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Arto Plus Assigned People / Technicians Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: AppDecorations.card(radius: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Building Support & Contractors',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink900),
                            ),
                            Text(
                              'Certified plumbers, electricians & HVAC on standby',
                              style: TextStyle(fontSize: 11, color: AppColors.ink500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: AppDecorations.badge(bg: AppColors.accentSoft),
                        child: const Text('24/7 Support', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Segmented Control (All / Active / Completed)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _SegmentTab(
                        title: 'All ($total)',
                        active: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      _SegmentTab(
                        title: 'Active ($inProgress)',
                        active: _filter == 'active',
                        onTap: () => setState(() => _filter = 'active'),
                      ),
                      _SegmentTab(
                        title: 'Resolved ($resolved)',
                        active: _filter == 'completed',
                        onTap: () => setState(() => _filter = 'completed'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (filteredTickets.isEmpty) ...[
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: AppDecorations.squircle(color: AppColors.accentSoft),
                      child: const Icon(Icons.build_outlined, size: 32, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'No reports in this category',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink900),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Tap "New Report" below to log an issue.',
                      style: TextStyle(color: AppColors.ink500, fontSize: 13),
                    ),
                  ),
                ] else ...[
                  ...filteredTickets.map((t) => _ArtoReportCard(ticket: t)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArtoStatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final String trend;

  const _ArtoStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: AppDecorations.squircle(color: color.withValues(alpha: 0.12)),
                child: Icon(icon, size: 20, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: AppDecorations.badge(bg: AppColors.bg),
                child: Text(
                  trend,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.ink500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink500),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? Colors.white : AppColors.ink700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Arto Plus Report Card
class _ArtoReportCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _ArtoReportCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final stage = (ticket['stage'] as num?)?.toInt() ?? 0;
    final priority = (ticket['priority'] as String?) ?? 'medium';
    final (pColor, pBg) = kPriorityColors[priority] ?? kPriorityColors['medium']!;
    final icon = kCategoryIcons[ticket['category']] ?? Icons.build_outlined;
    final progress = kTicketStages.length > 1 ? stage / (kTicketStages.length - 1) : 0.0;
    final stageName = stage < kTicketStages.length ? kTicketStages[stage] : 'Stage $stage';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppDecorations.card(radius: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: AppDecorations.squircle(color: AppColors.accentSoft),
                      child: Icon(icon, size: 22, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket['title']?.toString() ?? 'Maintenance Issue',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Report #MT-${ticket['id']} · ${ticket['category']?.toString().toUpperCase() ?? 'GENERAL'}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.ink500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: AppDecorations.badge(bg: pBg),
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stage: $stageName',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                    Text(
                      '${(progress * 100).toInt()}% Done',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1.0 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
