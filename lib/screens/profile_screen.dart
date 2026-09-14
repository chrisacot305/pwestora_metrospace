import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'tickets_list_screen.dart';
import 'coming_soon_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _name;

  @override
  void initState() {
    super.initState();
    ApiService.getUserName().then((v) => setState(() => _name = v));
  }

  Future<void> _logout() async {
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Account & Services'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppDecorations.card(radius: 20, shadow: true),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: AppDecorations.squircle(
                    color: AppColors.primary,
                    radius: 18,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name ?? 'Tenant User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: AppDecorations.badge(
                          bg: AppColors.accentSoft,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified Tenant',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Tenant Hub & Tools',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink900,
            ),
          ),
          const SizedBox(height: 12),

          _hubItem(
            icon: Icons.build_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.accentSoft,
            label: 'Maintenance Reports',
            note: 'Submit issues and track real-time resolution',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TicketsListScreen()),
            ),
          ),
          _hubItem(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.accentSoft,
            label: 'Installment Requests',
            note: 'Request a customized payment schedule',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ComingSoonScreen(
                  title: 'Installment Requests',
                  icon: Icons.receipt_long_outlined,
                  message:
                      "Requesting a payment plan from the app is in progress and coming soon.",
                ),
              ),
            ),
          ),
          _hubItem(
            icon: Icons.warning_amber_outlined,
            iconColor: AppColors.warning,
            iconBg: AppColors.warningSoft,
            label: 'Violations & Notices',
            note: 'View lease compliance or property notices',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ComingSoonScreen(
                  title: 'Violations',
                  icon: Icons.warning_amber_outlined,
                  message:
                      "Viewing violation logs from the app is coming soon.",
                ),
              ),
            ),
          ),
          _hubItem(
            icon: Icons.description_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.accentSoft,
            label: 'Lease Contract & Files',
            note: 'Access digitally signed agreement documents',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ComingSoonScreen(
                  title: 'Documents',
                  icon: Icons.description_outlined,
                  message:
                      "Document downloads and digital files are coming soon.",
                ),
              ),
            ),
          ),
          _hubItem(
            icon: Icons.payments_outlined,
            iconColor: AppColors.success,
            iconBg: AppColors.successSoft,
            label: 'Payment History',
            note: 'Review transaction records and receipts',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ComingSoonScreen(
                  title: 'Payment History',
                  icon: Icons.payments_outlined,
                  message:
                      "Payment history and receipt exports are coming soon.",
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
              label: const Text(
                'Log Out of Account',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('img/Frame 2.png', width: 18, height: 18),
                const SizedBox(width: 8),
                const Text(
                  'Pwestora Commercial · v0.1.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ink500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hubItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String note,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.card(radius: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: AppDecorations.squircle(
                    color: iconBg,
                    radius: 12,
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.ink300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
