import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'lease_contract_screen.dart';
import 'violation_notice_sheet.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? lease;
  final Function(int)? onNavigateTab;
  final Future<void> Function()? onLeaseMayHaveChanged;

  const ProfileScreen({
    super.key,
    this.lease,
    this.onNavigateTab,
    this.onLeaseMayHaveChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Juan Dela Cruz';
  Map<String, dynamic>? _leaseData;
  int _demoStrike = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lease != widget.lease) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final name = await ApiService.getUserName();
    final strike = await ApiService.getDemoStrikeLevel();
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _name = name;
        _demoStrike = strike;
      });
    }
    if (widget.lease != null) {
      setState(() => _leaseData = widget.lease);
    } else {
      final l = await ApiService.fetchLeaseStatus();
      if (mounted) setState(() => _leaseData = l);
    }
  }

  Future<void> _logout() async {
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openLeaseStanding() async {
    final violations = await ApiService.fetchViolations();
    if (!mounted) return;
    if (violations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: const [
              Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Account Status: Good Standing. Zero infractions on record.',
                  style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      await ViolationNoticeSheet.show(
        context,
        violation: violations.first,
        isGated: false,
      );
      _loadProfile();
    }
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title is available in this section.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLease = _leaseData != null;
    final unit = hasLease
        ? (_leaseData?['unit_label'] ?? 'Unit 302 • 3rd Floor')
        : 'Applicant / Prospective Tenant';
    final leaseNumber = 'Lease #LS-2026-${(_leaseData?['tenant_id'] ?? '032').toString().padLeft(3, '0')}';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Top Profile Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name & Unit / Applicant Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: hasLease ? 0 : 8,
                              vertical: hasLease ? 0 : 2,
                            ),
                            decoration: hasLease
                                ? null
                                : BoxDecoration(
                                    color: AppColors.accentSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                            child: Text(
                              unit,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: hasLease ? AppColors.ink500 : AppColors.accent,
                                fontWeight: hasLease ? FontWeight.w500 : FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lease Information or Applicant Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: hasLease
                    ? InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LeaseContractScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.card(radius: 18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lease Information',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$leaseNumber\nEnds Dec 31, 2027',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.ink500,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.ink400),
                            ],
                          ),
                        ),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(1); // Applications tab in applicant mode
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accentSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Application Status',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink900,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'View negotiations, checklist & contract progress',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.ink500,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Section 1: Account
            _buildSectionHeader('Account'),
            _buildSectionGroup([
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Personal Information',
                onTap: () => _showComingSoon('Personal Information'),
              ),
              _buildMenuItem(
                icon: Icons.contact_mail_outlined,
                title: 'Contact Information',
                onTap: () => _showComingSoon('Contact Information'),
              ),
            ]),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Section 2: Payments
            _buildSectionHeader('Payments'),
            _buildSectionGroup([
              _buildMenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Payment History',
                onTap: () => _showComingSoon('Payment History'),
              ),
              _buildMenuItem(
                icon: Icons.description_outlined,
                title: 'Receipts',
                onTap: () => _showComingSoon('Receipts'),
              ),
            ]),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Section 3: Documents & Compliance
            _buildSectionHeader('Documents & Compliance'),
            _buildSectionGroup([
              _buildStandingMenuItem(),
              _buildMenuItem(
                icon: Icons.assignment_outlined,
                title: 'Lease Agreement',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LeaseContractScreen()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.gavel_outlined,
                title: 'Contract Guidelines',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LeaseContractScreen()),
                  );
                },
              ),
            ]),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Section 4: Conflict Resolution Demo Switcher (Section C)
            _buildSectionHeader('Demo Mode: Conflict Resolution (Section C)'),
            _buildDemoSection(),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Section 5: Settings
            _buildSectionHeader('Settings'),
            _buildSectionGroup([
              _buildMenuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () => _showComingSoon('Notifications'),
              ),
              _buildMenuItem(
                icon: Icons.shield_outlined,
                title: 'Security',
                onTap: () => _showComingSoon('Security Settings'),
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                onTap: () => _showComingSoon('Help & Support'),
              ),
            ]),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Logout Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextButton.icon(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.ink400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionGroup(List<Widget> items) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: AppDecorations.card(radius: 18),
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    const Divider(color: AppColors.border, height: 1, indent: 52),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.ink700),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink900,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }

  Widget _buildStandingMenuItem() {
    String badgeText = 'Good Standing';
    Color badgeColor = AppColors.success;
    Color badgeSoft = const Color(0xFFECFDF5);
    IconData badgeIcon = Icons.check_circle_rounded;

    if (_demoStrike == 1) {
      badgeText = '1 Warning';
      badgeColor = const Color(0xFF0284C7);
      badgeSoft = const Color(0xFFEFF6FF);
      badgeIcon = Icons.info_outline_rounded;
    } else if (_demoStrike == 2) {
      badgeText = '₱500 Fine';
      badgeColor = const Color(0xFF1E6BFF);
      badgeSoft = const Color(0xFFDBEAFE);
      badgeIcon = Icons.receipt_long_rounded;
    } else if (_demoStrike >= 3) {
      badgeText = 'Critical Breach';
      badgeColor = AppColors.error;
      badgeSoft = const Color(0xFFFEE2E2);
      badgeIcon = Icons.gavel_rounded;
    }

    return InkWell(
      onTap: _openLeaseStanding,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: badgeSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.verified_user_outlined, size: 18, color: badgeColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Account & Lease Standing',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink900,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Compliance records & citations',
                    style: TextStyle(fontSize: 11.5, color: AppColors.ink500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: badgeSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 12, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.ink400),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.electricBlue),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Live Presentation Scenario Switcher',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a strike stage below, then navigate to Home to experience the live escalation gate.',
                style: TextStyle(fontSize: 11.5, color: AppColors.ink500, height: 1.35),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildScenarioChip(
                    level: 0,
                    label: '0: Clean Tenant',
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  _buildScenarioChip(
                    level: 1,
                    label: 'Strike 1: Warning',
                    color: const Color(0xFF0284C7),
                    icon: Icons.info_outline_rounded,
                  ),
                  _buildScenarioChip(
                    level: 2,
                    label: 'Strike 2: Fined (₱500)',
                    color: const Color(0xFF1E6BFF),
                    icon: Icons.receipt_long_rounded,
                  ),
                  _buildScenarioChip(
                    level: 3,
                    label: 'Strike 3: Eviction',
                    color: AppColors.error,
                    icon: Icons.gavel_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioChip({
    required int level,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _demoStrike == level;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await ApiService.setDemoStrikeLevel(level);
        setState(() => _demoStrike = level);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Switched to Scenario: $label. Switch to Home tab to test!',
                    style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
