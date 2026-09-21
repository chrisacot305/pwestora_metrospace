import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'lease_contract_screen.dart';

class ApplyScreen extends StatefulWidget {
  final int propertyId;
  final String propertyName;
  const ApplyScreen({super.key, required this.propertyId, required this.propertyName});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessCtrl = TextEditingController();
  final _termCtrl = TextEditingController(text: '12');
  final _rentCtrl = TextEditingController();
  int _currentStep = 0; // 0: Proposal Info, 1: Interactive Contract Negotiation Checklist

  bool _loading = false;
  String? _error;
  bool _submitted = false;

  // Standard Commercial Lease Clauses
  final List<Map<String, dynamic>> _checklistClauses = [
    {
      'key': 'security_deposit',
      'label': 'Security Deposit (2 Months)',
      'standard': "Equivalent to two (2) months' rent, held securely and refundable within 30 days of lease expiration less valid deductions.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting 1-month deposit instead of 2 months',
    },
    {
      'key': 'rent_escalation',
      'label': 'Annual Rent Escalation (5%)',
      'standard': "Monthly rent may increase by up to 5% upon annual lease renewal consistent with Philippine commercial lease standards.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting fixed rent with no escalation for 2 years',
    },
    {
      'key': 'lease_term',
      'label': 'Proposed Lease Duration',
      'standard': "Full commercial occupancy term as requested in the proposal with option to renew upon mutual agreement.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting 6 months trial period instead of 1 year',
    },
    {
      'key': 'use_of_premises',
      'label': 'Permitted Commercial Use',
      'standard': "Premises will be used solely for the registered business concept stated in this lease application.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting inclusion of outdoor pop-up kiosk events',
    },
    {
      'key': 'maintenance',
      'label': 'Structural & Day-to-Day Maintenance',
      'standard': "Lessor covers structural, roof, and main pipes. Tenant maintains internal fixtures, daily upkeep, and tenant installations.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting lessor to cover AC motor replacement if defective',
    },
    {
      'key': 'subleasing',
      'label': 'Subleasing & Space Assignment',
      'standard': "No subleasing or assigning space to a third party without express prior written consent from the lessor.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting permission to sublet corner booth to partner',
    },
    {
      'key': 'termination_notice',
      'label': 'Early Termination Notice (30 Days)',
      'standard': "At least thirty (30) days advance formal written notice required before early termination or vacating.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting 60 days notice period for both parties',
    },
    {
      'key': 'insurance_compliance',
      'label': 'Insurance & Business Compliance',
      'standard': "Lessee is responsible for insuring merchandise/equipment and maintaining valid municipal business permits and fire clearances.",
      'agreed': true,
      'controller': TextEditingController(),
      'defaultCounterPlaceholder': 'e.g. Requesting 30-day grace period to process city business permit',
    },
  ];

  @override
  void dispose() {
    _businessCtrl.dispose();
    _termCtrl.dispose();
    _rentCtrl.dispose();
    for (final c in _checklistClauses) {
      (c['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _proceedToChecklist() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _currentStep = 1);
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Build structured checklist negotiation payload
      final Map<String, dynamic> negotiationPayload = {};
      for (final clause in _checklistClauses) {
        final key = clause['key'] as String;
        final agreed = clause['agreed'] as bool;
        final note = (clause['controller'] as TextEditingController).text.trim();
        negotiationPayload[key] = {
          'agreed': agreed,
          'rebuttal_note': agreed ? null : note,
        };
      }

      await ApiService.submitApplication(
        propertyId: widget.propertyId,
        businessName: _businessCtrl.text.trim(),
        termMonths: int.parse(_termCtrl.text.trim()),
        rent: double.parse(_rentCtrl.text.trim()),
        checklistNegotiation: negotiationPayload,
      );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _submitted = true);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Lease Proposal' : 'Negotiate Contract Terms'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: _currentStep == 0 ? _buildStepOneForm() : _buildStepTwoChecklist(),
        ),
      ),
    );
  }

  Widget _buildStepOneForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Progress Indicator
          _buildStepHeader(step: 1, title: 'Commercial Proposal', subtitle: 'Step 1 of 2: Concept & Base Rates'),
          const SizedBox(height: 16),

          // Property Summary Pill Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecorations.card(radius: 18, shadow: true),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.apartment, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APPLYING FOR SPACE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.ink500, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.propertyName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_error != null) ...[
            _buildErrorBox(_error!),
            const SizedBox(height: 18),
          ],

          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppDecorations.card(radius: 20, shadow: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Concept / Brand Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _businessCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Artisanal Cafe & Specialty Bakery',
                    prefixIcon: Icon(Icons.store_mall_directory_outlined, color: AppColors.ink500, size: 20),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter your business name' : null,
                ),
                const SizedBox(height: 18),

                const Text(
                  'Proposed Lease Term (months)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _termCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 12, 24, 36',
                    prefixIcon: Icon(Icons.date_range_outlined, color: AppColors.ink500, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a lease term';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a valid number of months';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                const Text(
                  'Proposed Monthly Rent (₱ PHP)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _rentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 35000',
                    prefixIcon: Icon(Icons.payments_outlined, color: AppColors.ink500, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a proposed rent amount';
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToChecklist,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue to Contract Checklist', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwoChecklist() {
    final agreedCount = _checklistClauses.where((c) => c['agreed'] == true).length;
    final rebuttalCount = _checklistClauses.length - agreedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step Progress Indicator
        _buildStepHeader(step: 2, title: 'Contract Negotiation Checklist', subtitle: 'Step 2 of 2: Agree to standard clauses or propose counter-offers'),
        const SizedBox(height: 16),

        // Interactive Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.handshake_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Interactive Contract Negotiation',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Check each clause to accept standard commercial lease terms. If you disagree with any item, uncheck it and input your counter-offer note directly.',
                style: TextStyle(fontSize: 12, color: AppColors.ink500, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(8)),
                    child: Text('$agreedCount Standard Agreed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ),
                  const SizedBox(width: 8),
                  if (rebuttalCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                      child: Text('$rebuttalCount Counter-Offer(s)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_error != null) ...[
          _buildErrorBox(_error!),
          const SizedBox(height: 18),
        ],

        // List of Interactive Clauses
        ...List.generate(_checklistClauses.length, (index) {
          final clause = _checklistClauses[index];
          final isAgreed = clause['agreed'] as bool;
          final ctrl = clause['controller'] as TextEditingController;

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
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          clause['agreed'] = !isAgreed;
                        });
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isAgreed ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAgreed ? AppColors.primary : AppColors.steel,
                            width: 1.8,
                          ),
                        ),
                        child: isAgreed
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clause['label'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            clause['standard'] as String,
                            style: const TextStyle(fontSize: 12, color: AppColors.ink700, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Expanded Counter-Offer Rebuttal Box when unchecked
                if (!isAgreed) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFB45309)),
                            SizedBox(width: 6),
                            Text(
                              'Counter-Offer / Custom Proposal Note',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: ctrl,
                          minLines: 2,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 13, color: AppColors.ink900),
                          decoration: InputDecoration(
                            hintText: clause['defaultCounterPlaceholder'] as String,
                            hintStyle: TextStyle(fontSize: 12, color: AppColors.ink500.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFDE68A))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFDE68A))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD97706), width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 10),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Submit Proposal & Negotiated Terms', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Icon(Icons.send_rounded, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStepHeader({required int step, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink900)),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.ink500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Proposal Sent'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: AppDecorations.squircle(color: AppColors.successSoft, radius: 24),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Application & Checklist Sent!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink900, letterSpacing: -0.4),
            ),
            const SizedBox(height: 10),
            Text(
              'Your commercial lease proposal and negotiated checklist terms for ${widget.propertyName} have been submitted to the lessor.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink500, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confidentiality Lock is active on the auto-generated contract until initial deposit is finalized.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.ink700, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => LeaseContractScreen(
                        applicationData: {
                          'property_name': widget.propertyName,
                          'rent': double.tryParse(_rentCtrl.text.trim()) ?? 0,
                          'term_months': int.tryParse(_termCtrl.text.trim()) ?? 12,
                          'business_name': _businessCtrl.text.trim(),
                        },
                        forceInitialLock: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.checklist_rtl_rounded, size: 20),
                label: const Text('View Negotiation & Contract Status', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context)..pop()..pop(),
                child: const Text('Back to Browse Spaces', style: TextStyle(fontSize: 14, color: AppColors.ink500, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
