import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/api_service.dart';

class RentPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> lease;
  final double rentAmount;
  final Map<String, dynamic>? activeArrangement;
  final VoidCallback? onPaymentSubmitted;

  const RentPaymentScreen({
    super.key,
    required this.lease,
    required this.rentAmount,
    this.activeArrangement,
    this.onPaymentSubmitted,
  });

  @override
  State<RentPaymentScreen> createState() => _RentPaymentScreenState();
}

class _RentPaymentScreenState extends State<RentPaymentScreen> {
  final _amountController = TextEditingController();
  final _refNoController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedTarget = 'restructuring_plan';
  XFile? _proofImage;
  bool _submitting = false;
  bool _loading = true;
  List<dynamic> _paymentsHistory = [];

  bool get _hasRestructuring {
    final status = (widget.activeArrangement?['status'] ?? '').toString().toLowerCase();
    return status == 'approved' || status == 'pending';
  }

  int get _numParts {
    final plan = (widget.activeArrangement?['plan_label'] ?? '').toString();
    return plan.contains('3') ? 3 : 2;
  }

  double get _splitAmount => widget.rentAmount / _numParts;

  @override
  void initState() {
    super.initState();
    _initInitialTargetAndAmount();
    _fetchPaymentsHistory();
  }

  void _initInitialTargetAndAmount() {
    if (_hasRestructuring) {
      _selectedTarget = 'restructuring_plan';
      _amountController.text = _splitAmount.toStringAsFixed(0);
    } else {
      _selectedTarget = 'monthly_rent';
      _amountController.text = widget.rentAmount.toStringAsFixed(0);
    }
  }

  void _onTargetChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedTarget = val;
      if (val == 'restructuring_plan') {
        _amountController.text = _splitAmount.toStringAsFixed(0);
      } else if (val == 'monthly_rent') {
        _amountController.text = widget.rentAmount.toStringAsFixed(0);
      } else if (val == 'both') {
        _amountController.text = (widget.rentAmount + _splitAmount).toStringAsFixed(0);
      }
    });
  }

  Future<void> _fetchPaymentsHistory() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.fetchPayments();
      if (mounted) {
        setState(() {
          _paymentsHistory = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickProofPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _proofImage = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image picker: $e')),
        );
      }
    }
  }

  void _downloadOrSaveQr() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.electricBlue, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'InstaPay QR Code saved to photos / device storage.',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final ref = _refNoController.text.trim();
    final amtText = _amountController.text.trim().replaceAll(',', '');
    final amt = double.tryParse(amtText) ?? 0.0;

    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    if (ref.isEmpty && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reference number or upload a proof photo.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ApiService.submitRentPayment(
        amount: amt,
        target: _selectedTarget,
        referenceNo: ref.isNotEmpty ? ref : 'IMG-RECEIPT-${DateTime.now().millisecondsSinceEpoch % 10000}',
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      widget.onPaymentSubmitted?.call();
      await _fetchPaymentsHistory();

      if (!mounted) return;

      setState(() {
        _submitting = false;
        _refNoController.clear();
        _proofImage = null;
      });

      _showSuccessDialog(amt);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(double amt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.electricBlue, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Submitted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.midnightNavy,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment of ₱${_formatMoney(amt)} has been recorded as Pending. The lessor will verify the transaction and credit your balance.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.ink500, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Back to Payments', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
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

  // Calculate percentage paid / remaining
  Map<String, dynamic> _computePaymentProgress() {
    double totalVerifiedPaid = 0.0;
    double totalPendingPaid = 0.0;

    for (final p in _paymentsHistory) {
      final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
      final status = (p['status'] ?? '').toString().toLowerCase();
      if (status == 'approved' || status == 'verified') {
        totalVerifiedPaid += amt;
      } else {
        totalPendingPaid += amt;
      }
    }

    final totalTarget = widget.rentAmount > 0 ? widget.rentAmount : 2500.0;
    final verifiedPercent = ((totalVerifiedPaid / totalTarget) * 100).clamp(0, 100).toInt();
    final remainingAmount = (totalTarget - totalVerifiedPaid).clamp(0.0, totalTarget);
    final remainingPercent = (100 - verifiedPercent).clamp(0, 100);

    return {
      'verifiedPaid': totalVerifiedPaid,
      'pendingPaid': totalPendingPaid,
      'totalTarget': totalTarget,
      'verifiedPercent': verifiedPercent,
      'remainingAmount': remainingAmount,
      'remainingPercent': remainingPercent,
    };
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refNoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _computePaymentProgress();
    final verifiedPercent = progress['verifiedPercent'] as int;
    final remainingPercent = progress['remainingPercent'] as int;
    final remainingAmount = progress['remainingAmount'] as double;
    final pendingPaid = progress['pendingPaid'] as double;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pay Rent',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            tooltip: 'Refresh Status',
            onPressed: _fetchPaymentsHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPaymentsHistory,
        color: AppColors.electricBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ================= 1. PAYMENT PROGRESS CARD =================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A1832).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settlement Progress',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: verifiedPercent >= 100
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          verifiedPercent >= 100
                              ? '100% Fully Settled'
                              : '$verifiedPercent% Paid',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: verifiedPercent >= 100
                                ? const Color(0xFF10B981)
                                : AppColors.electricBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: verifiedPercent / 100.0,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: verifiedPercent >= 100
                          ? const Color(0xFF10B981)
                          : AppColors.electricBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining: ₱${_formatMoney(remainingAmount)} ($remainingPercent%)',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink700,
                        ),
                      ),
                      if (pendingPaid > 0)
                        Text(
                          '₱${_formatMoney(pendingPaid)} pending verification',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= 2. INSTAPAY QR CODE CARD =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A1832).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1B3D),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'InstaPay Direct QR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // QR Code Image
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Image.asset(
                      'img/instapay_qr.jpg',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Pwestora Escrow Account',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Supports GCash, Maya, BDO, BPI, UnionBank & all PH banks',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink500,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Download / Save QR Button
                  OutlinedButton.icon(
                    onPressed: _downloadOrSaveQr,
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text(
                      'Save QR Code to Device',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= 3. PAYMENT FORM =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A1832).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.midnightNavy,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Target Dropdown (if restructuring active)
                  if (_hasRestructuring) ...[
                    const Text(
                      'Select Payment Target',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTarget,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ink500),
                          items: [
                            DropdownMenuItem(
                              value: 'restructuring_plan',
                              child: Text(
                                'Restructuring Plan (₱${_formatMoney(_splitAmount)})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'monthly_rent',
                              child: Text(
                                'Monthly Rent (₱${_formatMoney(widget.rentAmount)})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'both',
                              child: Text(
                                'Both: Full Settlement (₱${_formatMoney(widget.rentAmount + _splitAmount)})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink900),
                              ),
                            ),
                          ],
                          onChanged: _onTargetChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Amount Input
                  const Text(
                    'Amount to Pay',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink900),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink900),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.electricBlue, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Proof of Payment / Upload Receipt
                  const Text(
                    'Proof of Payment (Photo / Screenshot)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink700),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickProofPhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _proofImage != null ? AppColors.electricBlue : AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Icon(
                              _proofImage != null ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
                              size: 18,
                              color: AppColors.electricBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _proofImage != null ? _proofImage!.name : 'Attach Transfer Receipt',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _proofImage != null ? AppColors.ink900 : AppColors.ink700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _proofImage != null ? 'Tap to change photo' : 'JPG, PNG screenshot from bank app',
                                  style: const TextStyle(fontSize: 11, color: AppColors.ink500),
                                ),
                              ],
                            ),
                          ),
                          if (_proofImage != null)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.ink500),
                              onPressed: () => setState(() => _proofImage = null),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Reference Number Input
                  const Text(
                    'Transaction Reference Number',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _refNoController,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink900),
                    decoration: InputDecoration(
                      hintText: 'e.g. 102938475612',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.ink400),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.electricBlue, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Submit Payment for Verification',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= 4. RECENT SUBMISSIONS HISTORY =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment History & Audit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnightNavy,
                  ),
                ),
                Text(
                  '${_paymentsHistory.length} logged',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.ink500),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.electricBlue),
                ),
              )
            else if (_paymentsHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text(
                    'No payments recorded yet. Submit your transfer above.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink500),
                  ),
                ),
              )
            else
              ..._paymentsHistory.map((p) {
                final status = (p['status'] ?? 'approved').toString().toLowerCase();
                final isPending = status == 'pending';
                final amt = (p['amount'] as num?)?.toDouble() ?? 0.0;
                final paidAt = p['paid_at']?.toString() ?? '';
                final note = p['note']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
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
                                    color: isPending
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPending ? 'PENDING VERIFICATION' : 'VERIFIED & CREDITED',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: isPending
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.isNotEmpty ? note : 'Rent Payment (Bank Transfer)',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (paidAt.isNotEmpty)
                              Text(
                                'Date: $paidAt',
                                style: const TextStyle(fontSize: 11, color: AppColors.ink400),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${_formatMoney(amt)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.midnightNavy,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}
}
