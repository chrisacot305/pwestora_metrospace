import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class PaymentArrangementScreen extends StatefulWidget {
  final Map<String, dynamic> lease;
  final VoidCallback? onArrangementSubmitted;

  const PaymentArrangementScreen({
    super.key,
    required this.lease,
    this.onArrangementSubmitted,
  });

  @override
  State<PaymentArrangementScreen> createState() => _PaymentArrangementScreenState();
}

class _PaymentArrangementScreenState extends State<PaymentArrangementScreen> {
  String _selectedPlan = '2 payments';
  String _selectedReason = 'Cash flow delay this month';
  bool _submitting = false;
  bool _loading = true;
  List<dynamic> _existingRequests = [];

  final List<String> _reasons = [
    'Cash flow delay this month',
    'Seasonal slowdown in business',
    'Unexpected business expense',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _loading = true);
    try {
      final reqs = await ApiService.fetchInstallmentRequests();
      if (mounted) {
        setState(() {
          _existingRequests = reqs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _submitting = true);
    try {
      await ApiService.createInstallmentRequest(
        reason: _selectedReason,
        planLabel: _selectedPlan,
      );

      if (mounted) {
        setState(() => _submitting = false);
        widget.onArrangementSubmitted?.call();
        _showSuccessModal();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Restructuring Request Submitted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B1B3D),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your lessor has been notified via the Pwestora Portal. A formal audit entry has been recorded to preserve your security deposit escrow.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetchRequests();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1B3D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Back to Schedule & Requests', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDepositEscrowDetails(double depositAmount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF1E6BFF), size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Deposit Escrow',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0B1B3D)),
                    ),
                    Text(
                      'Governed by Lease Contract Sec. 4.2',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildEscrowDetailRow('Total Deposit Held', '₱${_formatMoney(depositAmount)} (2 Months)'),
            _buildEscrowDetailRow('Escrow Status', '100% Intact & Locked'),
            _buildEscrowDetailRow('Replenishment Policy', 'Immediate top-up upon emergency use'),
            _buildEscrowDetailRow('Permitted Usage', 'Structural damage / Final vacancy repair only'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1B3D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 12.5, color: Color(0xFF0B1B3D), fontWeight: FontWeight.w800)),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final rent = (widget.lease['rent'] as num?)?.toDouble() ?? 12000.0;
    final deposit = rent * 2; // Standard 2-month security deposit

    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final endOfMonthDay = DateTime(now.year, now.month + 1, 0).day;
    final dueMonthShort = months[(now.month - 1).clamp(0, 11)];
    
    final nextMonthDate = DateTime(now.year, now.month + 1, 15);
    final nextMonthShort = months[(nextMonthDate.month - 1).clamp(0, 11)];

    // Dates for 3 payments
    final p2d2 = DateTime(now.year, now.month, endOfMonthDay).add(const Duration(days: 10));
    final p2d2Short = months[(p2d2.month - 1).clamp(0, 11)];
    final p2d3 = DateTime(now.year, now.month, endOfMonthDay).add(const Duration(days: 20));
    final p2d3Short = months[(p2d3.month - 1).clamp(0, 11)];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ================= ARTISTIC MIDNIGHT CURVED HERO APPBAR =================
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: const Color(0xFF071739),
            elevation: 0,
            leading: const AppBackButton(isDark: true),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                    // Decorative glow circle
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.handshake_outlined, size: 13, color: Color(0xFF00E5FF)),
                                SizedBox(width: 5),
                                Text(
                                  'Formal Concession Protocol',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Payment Restructuring',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Structured split installments to protect cashflow & preserve security deposit.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= MAIN BODY CONTENT =================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SECURITY DEPOSIT SHIELD CARD
                  _buildSecurityDepositShieldCard(deposit),

                  const SizedBox(height: 16),

                  // 2. MUTUAL BENEFIT BAR
                  _buildMutualBenefitBar(),

                  const SizedBox(height: 24),

                  // 3. ACTIVE / EXISTING REQUESTS (If any)
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E6BFF)),
                        ),
                      ),
                    )
                  else if (_existingRequests.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Restructuring History',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B1B3D),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_existingRequests.length} filed',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E6BFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._existingRequests.map((req) => _buildRequestHistoryCard(req)),
                    const SizedBox(height: 24),
                  ],

                  // 4. PLAN SELECTION SECTION
                  const Text(
                    'Select Installment Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1B3D),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pre-calculated structured milestones for your upcoming rent.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Option A: 2 Payments
                  _buildPlanCard(
                    planKey: '2 payments',
                    title: '2-Part Split Plan (Bi-Weekly)',
                    badge: 'Recommended',
                    badgeColor: const Color(0xFF10B981),
                    installments: [
                      {
                        'label': 'Payment 1 (50%)',
                        'amount': rent / 2,
                        'timing': 'Due $dueMonthShort $endOfMonthDay, ${now.year}',
                      },
                      {
                        'label': 'Payment 2 (50%)',
                        'amount': rent / 2,
                        'timing': 'Due $nextMonthShort 15, ${nextMonthDate.year}',
                      },
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Option B: 3 Payments
                  _buildPlanCard(
                    planKey: '3 payments',
                    title: '3-Part Split Plan (Decennial)',
                    badge: 'Extended',
                    badgeColor: const Color(0xFF8B5CF6),
                    installments: [
                      {
                        'label': 'Payment 1 (33%)',
                        'amount': rent / 3,
                        'timing': 'Due $dueMonthShort $endOfMonthDay, ${now.year}',
                      },
                      {
                        'label': 'Payment 2 (33%)',
                        'amount': rent / 3,
                        'timing': 'Due $p2d2Short ${p2d2.day}, ${p2d2.year}',
                      },
                      {
                        'label': 'Payment 3 (33%)',
                        'amount': rent / 3,
                        'timing': 'Due $p2d3Short ${p2d3.day}, ${p2d3.year}',
                      },
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 5. STRUCTURED REASON SELECTOR
                  const Text(
                    'Formal Restructuring Reason',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B1B3D),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Required for landlord audit & formal record keeping.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reasons.map((r) {
                      final isSelected = _selectedReason == r;
                      return ChoiceChip(
                        label: Text(r),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedReason = r);
                        },
                        selectedColor: const Color(0xFF0B1B3D),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF0B1B3D) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 6. LEGAL & LEASE CLAUSE DISCLAIMER
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.gavel_rounded, size: 18, color: Color(0xFFD97706)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Submitting this request creates an official audit log in the Lessor Pwestora Portal. It replaces informal verbal agreements and safeguards your security deposit escrow.',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 7. SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: AppDecorations.glowButton(radius: 18),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _submitting ? null : _submitRequest,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Submit Restructuring Plan',
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualBenefitBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1832).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBenefitItem(Icons.verified_rounded, 'Zero Late Fines', const Color(0xFF10B981)),
          Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
          _buildBenefitItem(Icons.lock_rounded, 'Deposit Shielded', const Color(0xFF1E6BFF)),
          Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
          _buildBenefitItem(Icons.history_edu_rounded, 'Audited Trail', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityDepositShieldCard(double depositAmount) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showDepositEscrowDetails(depositAmount),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1832).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.shield_outlined, color: Color(0xFF1E6BFF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Security Deposit Escrow',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0B1B3D),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LOCKED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${_formatMoney(depositAmount)} Protected Reserve',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E6BFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Tap to view lease Article 4 escrow policy.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF64748B)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planKey,
    required String title,
    required String badge,
    required Color badgeColor,
    required List<Map<String, dynamic>> installments,
  }) {
    final isSelected = _selectedPlan == planKey;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedPlan = planKey),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E6BFF) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF1E6BFF).withValues(alpha: 0.08)
                  : const Color(0xFF0A1832).withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1E6BFF) : const Color(0xFFCBD5E1),
                          width: isSelected ? 6 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B1B3D),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Installment Breakdown Timeline
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEF2F6)),
              ),
              child: Column(
                children: installments.map((inst) {
                  final amount = (inst['amount'] as num).toDouble();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF1E6BFF)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inst['label'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  inst['timing'],
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '₱${_formatMoney(amount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B1B3D),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestHistoryCard(dynamic req) {
    final status = (req['status'] ?? 'pending').toString().toLowerCase();
    final reason = req['reason'] ?? 'Restructuring';
    final plan = req['plan_label'] ?? '2 payments';
    final amount = (req['amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = req['created_at']?.toString() ?? '';

    Color statusBg = const Color(0xFFFEF3C7);
    Color statusColor = const Color(0xFFD97706);
    String statusLabel = 'PENDING LESSOR REVIEW';

    if (status == 'approved') {
      statusBg = const Color(0xFFECFDF5);
      statusColor = const Color(0xFF10B981);
      statusLabel = 'APPROVED & ACTIVE';
    } else if (status == 'rejected') {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'DECLINED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      plan,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B1B3D),
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    'Submitted: $createdAt',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '₱${_formatMoney(amount)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0B1B3D),
            ),
          ),
        ],
      ),
    );
  }
}
