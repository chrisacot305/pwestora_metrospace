import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/api_service.dart';

class LeaseContractScreen extends StatefulWidget {
  final Map<String, dynamic>? applicationData;
  final bool forceInitialLock;

  const LeaseContractScreen({
    super.key,
    this.applicationData,
    this.forceInitialLock = false,
  });

  @override
  State<LeaseContractScreen> createState() => _LeaseContractScreenState();
}

class _LeaseContractScreenState extends State<LeaseContractScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic>? _contract;
  bool _isPaymentComplete = false;
  bool _isSimulatingPayment = false;

  // Standard Clauses with default descriptions
  final List<Map<String, dynamic>> _defaultClauses = [
    {
      'key': 'security_deposit',
      'label': 'Security Deposit',
      'standard': "A security deposit equivalent to two (2) months' rent will be collected and held. Refundable within 30 days of lease-end less deductions for damages.",
      'agreed': true,
      'note': '',
    },
    {
      'key': 'rent_escalation',
      'label': 'Rent Escalation Rate',
      'standard': "Monthly rent may increase by up to five percent (5%) upon each annual renewal, consistent with Philippine commercial leasing standard.",
      'agreed': true,
      'note': '',
    },
    {
      'key': 'lease_term',
      'label': 'Lease Term Duration',
      'standard': "Standard commercial occupancy period as agreed upon in the application proposal with mutual option to renew 60 days before expiration.",
      'agreed': true,
      'note': '',
    },
    {
      'key': 'use_of_premises',
      'label': 'Permitted Use of Premises',
      'standard': "The leased commercial space will be utilized solely for the registered business concept stated in the approved lease proposal.",
      'agreed': true,
      'note': '',
    },
    {
      'key': 'maintenance_responsibility',
      'label': 'Maintenance & Structural Upkeep',
      'standard': "Lessor maintains outer structural integrity, roof, and central utilities. Lessee handles internal fit-outs, day-to-day fixtures, and interior repairs.",
      'agreed': true,
      'note': '',
    },
    {
      'key': 'no_sublease',
      'label': 'Assignment & Subleasing Policy',
      'standard': "The tenant shall not sublease, assign, transfer, or encumber the leasehold without prior express written authorization from the lessor.",
      'agreed': false,
      'note': 'Requesting permission to allow booth and kiosk consignment partner.',
    },
    {
      'key': 'termination_notice',
      'label': 'Termination & Notice Period',
      'standard': "At least thirty (30) days formal written advance notice is required prior to vacating premises or early lease determination.",
      'agreed': true,
      'note': '',
    },
    {
      'key': 'compliance',
      'label': 'Legal Compliance & Business Permits',
      'standard': "The tenant agrees to maintain all necessary local LGU permits, BIR registration, and fire safety compliance certificates throughout occupancy.",
      'agreed': true,
      'note': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContract();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContract() async {
    setState(() {
      _loading = true;
    });

    try {
      final res = await ApiService.fetchContractView();
      if (!mounted) return;

      final hasLease = res['has_lease'] == true;
      final contractData = res['contract'] as Map<String, dynamic>?;

      setState(() {
        _contract = contractData;
        _isPaymentComplete = hasLease && !widget.forceInitialLock;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPaymentComplete = !widget.forceInitialLock;
        _loading = false;
      });
    }
  }

  void _simulateCompletePayment() {
    HapticFeedback.heavyImpact();
    setState(() => _isSimulatingPayment = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isSimulatingPayment = false;
        _isPaymentComplete = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initial payment verified! Legal contract confidentiality lock unlocked.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.applicationData;
    final propertyName = _contract?['property_name'] ?? app?['property_name'] ?? 'Commercial Property';
    final lessorName = _contract?['lessor_name'] ?? app?['lessor_name'] ?? 'Property Lessor';
    final rent = (_contract?['rent'] ?? app?['rent'] ?? 0).toDouble();
    final term = (_contract?['term_months'] ?? app?['term_months'] ?? 12).toInt();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Lease Agreement & Terms'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.ink500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.checklist_rounded, size: 20), text: 'Negotiated Checklist'),
            Tab(icon: Icon(Icons.gavel_rounded, size: 20), text: 'Legal Contract Document'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNegotiatedChecklistTab(propertyName, lessorName, rent, term),
                _buildLegalContractTab(propertyName, lessorName, rent, term),
              ],
            ),
    );
  }

  // ---------------- TAB 1: INTERACTIVE NEGOTIATED CHECKLIST ----------------

  Widget _buildNegotiatedChecklistTab(String propertyName, String lessorName, double rent, int term) {
    final agreedCount = _defaultClauses.where((c) => c['agreed'] == true).length;
    final rebuttalCount = _defaultClauses.length - agreedCount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Overview
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.handshake_outlined, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'INTERACTIVE NEGOTIATION',
                            style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Terms Aligned',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  propertyName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                ),
                const SizedBox(height: 3),
                Text(
                  'Lessor: $lessorName · ₱${_formatMoney(rent)}/mo ($term Months)',
                  style: const TextStyle(color: AppColors.tint, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$agreedCount Standard Clauses',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    if (rebuttalCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded, color: Color(0xFFFDE68A), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$rebuttalCount Counter-Offer Note',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if ((widget.applicationData?['negotiation_messages'] as List<dynamic>?)?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCCE3FF), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Negotiation Conversation',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B57D0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...((widget.applicationData!['negotiation_messages'] as List<dynamic>).map((m) {
                    final isMe = (m['sender'] ?? '') == 'lessee';
                    final senderLabel = isMe ? 'You (Applicant)' : '$lessorName (Lessor)';
                    final text = (m['message'] ?? '').toString();
                    final timeRaw = m['sent_at']?.toString() ?? '';
                    final timeStr = timeRaw.isNotEmpty ? timeRaw.split('T').first : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white : const Color(0xFFE8F1FE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMe ? AppColors.border : const Color(0xFFBDD7FE),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                senderLabel,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isMe ? AppColors.ink900 : const Color(0xFF0B57D0),
                                ),
                              ),
                              if (timeStr.isNotEmpty)
                                Text(
                                  timeStr,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.ink500),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.ink700, height: 1.35),
                          ),
                        ],
                      ),
                    );
                  })),
                ],
              ),
            ),
          ] else if ((widget.applicationData?['lessor_rebuttal'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCCE3FF), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lessor Counter-Proposal / Rebuttal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0B57D0),
                        ),
                      ),
                      if ((widget.applicationData?['rebuttal_at'] ?? '').toString().isNotEmpty)
                        Text(
                          (widget.applicationData!['rebuttal_at'] as String).split('T').first,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.ink500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (widget.applicationData!['lessor_rebuttal'] ?? '').toString().trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A3C6D),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Informative Section Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clause-by-Clause Negotiation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink900, letterSpacing: -0.2),
              ),
              Text(
                '${_defaultClauses.length} Clauses',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List of Clauses with interactive notes
          ...List.generate(_defaultClauses.length, (index) {
            final clause = _defaultClauses[index];
            final isAgreed = clause['agreed'] == true;
            final note = clause['note']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isAgreed ? AppColors.border : const Color(0xFFF59E0B).withValues(alpha: 0.6),
                  width: isAgreed ? 1 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isAgreed ? AppColors.successSoft : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isAgreed ? Icons.check_rounded : Icons.edit_note_rounded,
                          size: 16,
                          color: isAgreed ? AppColors.success : const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clause['label'] ?? '',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAgreed ? 'Standard Philippine Commercial Practice' : 'Digital Rebuttal & Custom Term Attached',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isAgreed ? AppColors.ink500 : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAgreed ? AppColors.successSoft : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAgreed ? 'AGREED' : 'COUNTER-OFFER',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: isAgreed ? AppColors.success : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    clause['standard'] ?? '',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.ink700, height: 1.4),
                  ),

                  // Counter-offer / Rebuttal Note Box (if unchecked)
                  if (!isAgreed && note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.speaker_notes_outlined, size: 13, color: Color(0xFFB45309)),
                              SizedBox(width: 5),
                              Text(
                                'Lessee Counter-Offer Rebuttal:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"$note"',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text(
                                'Reviewed & pre-accepted by Lessor during approval',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------- TAB 2: LEGAL CONTRACT & CONFIDENTIALITY LOCK ----------------

  Widget _buildLegalContractTab(String propertyName, String lessorName, double rent, int term) {
    if (!_isPaymentComplete) {
      return _buildConfidentialityLockedView(propertyName, lessorName, rent);
    }

    return _buildUnlockedContractDocument(propertyName, lessorName, rent, term);
  }

  Widget _buildConfidentialityLockedView(String propertyName, String lessorName, double rent) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Security Lock Badge Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_person_rounded, size: 36, color: Color(0xFFD97706)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Confidentiality Lock Active',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The legally binding execution contract has been auto-generated based on your agreed checklist. Under platform security policy, full legal contract download is protected until initial security deposit / first month payment clearance is finalized.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // Deposit Amount Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('INITIAL TRANSACTION REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink500)),
                          SizedBox(height: 2),
                          Text('Security Deposit & 1st Mo. Rent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink900)),
                        ],
                      ),
                      Text(
                        '₱${_formatMoney(rent * 2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Unlock / Pay Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSimulatingPayment ? null : _simulateCompletePayment,
                    icon: _isSimulatingPayment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user_rounded, size: 20),
                    label: Text(
                      _isSimulatingPayment ? 'Verifying Transaction…' : 'Complete Initial Payment & Unlock',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF102340),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Blurred Document Teaser Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 18, color: AppColors.ink500),
                    const SizedBox(width: 8),
                    const Text(
                      'Auto-Generated Contract Preview',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink900),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LOCKED',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildBlurredPlaceholderLine(widthFraction: 0.9),
                _buildBlurredPlaceholderLine(widthFraction: 0.75),
                _buildBlurredPlaceholderLine(widthFraction: 0.85),
                _buildBlurredPlaceholderLine(widthFraction: 0.6),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '🔒 Negotiated terms will generate here automatically upon payment',
                    style: TextStyle(fontSize: 11.5, color: AppColors.ink500, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredPlaceholderLine({required double widthFraction}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 12,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.tint.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildUnlockedContractDocument(String propertyName, String lessorName, double rent, int term) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Contract Unlocked Top Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_open_rounded, color: AppColors.success, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Contract Unlocked & Active',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                      Text(
                        'Verified deposit logged. Official contract binding under Philippine Commercial Law.',
                        style: TextStyle(fontSize: 11, color: AppColors.ink700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Formal Document Paper View
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset('img/Frame 2.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'CONTRACT OF LEASE',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: AppColors.ink900),
                      ),
                      const Text(
                        'Commercial Property Lease Agreement',
                        style: TextStyle(fontSize: 12, color: AppColors.ink500, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 14),

                const Text(
                  'KNOW ALL MEN BY THESE PRESENTS:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink700),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12.5, color: AppColors.ink900, height: 1.5, fontFamily: 'Roboto'),
                    children: [
                      const TextSpan(text: 'This Contract of Lease is entered into by and between the Lessor, '),
                      TextSpan(text: lessorName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(text: ', and the Lessee, for the commercial lease of premises situated at '),
                      TextSpan(text: propertyName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: ' for a monthly consideration of ₱${_formatMoney(rent)} for a period of $term Months.'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  'TERMS & SPECIAL NEGOTIATED COVENANTS:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink700),
                ),
                const SizedBox(height: 8),

                ...List.generate(_defaultClauses.length, (i) {
                  final c = _defaultClauses[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: AppColors.ink700, height: 1.4, fontFamily: 'Roboto'),
                              children: [
                                TextSpan(text: '${c['label']}: ', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink900)),
                                TextSpan(text: c['agreed'] == true ? c['standard'] : '${c['standard']} (Custom Term: ${c['note']})'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 16),

                // Digital Signatures
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
                          child: const Text('DIGITALLY SIGNED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                        const SizedBox(height: 6),
                        Text(lessorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        const Text('Lessor / Property Owner', style: TextStyle(fontSize: 11, color: AppColors.ink500)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(6)),
                          child: const Text('DIGITALLY SIGNED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.success)),
                        ),
                        const SizedBox(height: 6),
                        const Text('Lessee Account Holder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        const Text('Tenant / Commercial Lessee', style: TextStyle(fontSize: 11, color: AppColors.ink500)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
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
