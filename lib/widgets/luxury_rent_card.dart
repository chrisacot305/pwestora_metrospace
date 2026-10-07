import 'package:flutter/material.dart';

/// A precision custom clipper for the front card.
/// Curves the bottom-right corner inward with a tight, Apple-grade S-curve fillet.
class InspoCardClipper extends CustomClipper<Path> {
  final double radius;
  final double notchWidth;
  final double notchHeight;
  final double filletRadius;

  const InspoCardClipper({
    this.radius = 24.0,
    this.notchWidth = 126.0,
    this.notchHeight = 48.0,
    this.filletRadius = 14.0,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final r = radius;
    final nw = notchWidth;
    final nh = notchHeight;
    final fr = filletRadius;
    final p = Path();

    // 1. Top-left corner
    p.moveTo(r, 0);

    // 2. Top edge
    p.lineTo(w - r, 0);
    p.quadraticBezierTo(w, 0, w, r);

    // 3. Right edge down to notch
    p.lineTo(w, h - nh - fr);

    // 4. Outside corner turning left into horizontal shelf
    p.quadraticBezierTo(w, h - nh, w - fr, h - nh);

    // 5. Horizontal shelf going left
    p.lineTo(w - nw + fr, h - nh);

    // 6. Inside corner turning down
    p.quadraticBezierTo(w - nw, h - nh, w - nw, h - nh + fr);

    // 7. Vertical wall going down
    p.lineTo(w - nw, h - fr);

    // 8. Corner turning left into bottom edge
    p.quadraticBezierTo(w - nw, h, w - nw - fr, h);

    // 9. Bottom edge going left to bottom-left corner
    p.lineTo(r, h);
    p.quadraticBezierTo(0, h, 0, h - r);

    // 10. Left edge going up
    p.lineTo(0, r);
    p.quadraticBezierTo(0, 0, r, 0);

    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant InspoCardClipper oldClipper) =>
      oldClipper.radius != radius ||
      oldClipper.notchWidth != notchWidth ||
      oldClipper.notchHeight != notchHeight ||
      oldClipper.filletRadius != filletRadius;
}

/// The exact Stacked Luxury Card matching the inspo reference:
/// - Warm gold/sand card peeking out strictly at the top (~26px)
/// - Deep luxury navy front card with official Pwestora building logo
/// - Scooped bottom-right corner revealing clean app background
/// - Solid black '+ Pay Rent' pill nestled seamlessly in the corner cutaway
class LuxuryRentCard extends StatelessWidget {
  final double rentAmount;
  final String dueDate;
  final String tenantName;
  final VoidCallback onPayRent;
  final Map<String, dynamic>? activeArrangement;
  final VoidCallback? onArrangementTap;

  const LuxuryRentCard({
    super.key,
    required this.rentAmount,
    required this.dueDate,
    required this.tenantName,
    required this.onPayRent,
    this.activeArrangement,
    this.onArrangementTap,
  });

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
    const totalHeight = 224.0;
    const frontCardTop = 26.0;
    const notchWidth = 126.0;
    const notchHeight = 48.0;

    final status = (activeArrangement?['status'] ?? '').toString().toLowerCase();
    final planLabel = (activeArrangement?['plan_label'] ?? '').toString();
    final isApproved = status == 'approved';
    final isPending = status == 'pending';
    final hasRestructuring = isApproved || isPending;

    final numParts = planLabel.contains('3') ? 3 : 2;
    final splitAmount = rentAmount / numParts;
    final currentPart = (activeArrangement?['current_part'] as int?) ?? 1;
    final dueMonth = (activeArrangement?['due_month'] as String?) ?? 'October';
    final isPart1 = hasRestructuring && isApproved && currentPart == 1;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ================= 1. BACK CARD: ROYAL SLATE & ELECTRIC ACCENT =================
          Positioned(
            top: 0,
            left: 10,
            right: 10,
            height: 100,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF21447D),
                    Color(0xFF142C56),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF1E6BFF).withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E6BFF).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 14,
                    child: Stack(
                      children: [
                        Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E6BFF).withValues(alpha: 0.5),
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

          // ================= 2. FRONT CARD: DEEP LUXURY NAVY =================
          Positioned(
            top: frontCardTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: const InspoCardClipper(
                radius: 24,
                notchWidth: notchWidth,
                notchHeight: notchHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F2044),
                      Color(0xFF09142B),
                      Color(0xFF040A18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF040A18).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Pwestora Logo + Brand Name (and small, subtle Due Date when restructuring)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'img/Frame 2.png',
                              width: 20,
                              height: 20,
                              color: Colors.white,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pwestora',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),

                        // When in Restructuring Plan: small, subtle Due Date at top-right (no oval background, not full-looking)
                        if (hasRestructuring)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.60),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dueDate,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.90),
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Metrics Row: Left is Monthly Rent, Beside it (Right) is Restructuring Plan (or Due Date if no plan)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side: Monthly Rent
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly Rent',
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                color: isPart1
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${_formatMoney(rentAmount)}',
                              style: TextStyle(
                                fontSize: hasRestructuring ? 26 : 32,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: isPart1
                                    ? Colors.white.withValues(alpha: 0.32)
                                    : Colors.white,
                                letterSpacing: hasRestructuring ? -0.6 : -1.0,
                              ),
                            ),
                            if (hasRestructuring) ...[
                              const SizedBox(height: 4),
                              Text(
                                isPart1 ? 'Deferred (Part 1)' : 'Active Due',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  color: isPart1
                                      ? Colors.white.withValues(alpha: 0.30)
                                      : Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Right Side: Beside Monthly Rent is Restructuring Plan (or Due Date if no plan)
                        if (hasRestructuring)
                          InkWell(
                            onTap: onArrangementTap,
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Restructuring Plan',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.2,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₱${_formatMoney(splitAmount)}',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isApproved
                                      ? (isPart1 ? 'Next due — $dueMonth' : 'Final installment')
                                      : 'Next due — $dueMonth (Pending)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    height: 1.2,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Due Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dueDate,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bottom Row: Tenant Name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tenant',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tenantName.isNotEmpty ? tenantName : 'Jake Peralta',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ================= 3. INSET FLOATING '+ PAY RENT' BUTTON =================
          // Nestles right inside the bottom-right corner negative space
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPayRent,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E14),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Pay Rent',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
