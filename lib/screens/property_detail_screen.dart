import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'apply_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchPropertyDetail(widget.propertyId);
    _future.then((p) {
      final photos = (p['photos'] as List<dynamic>? ?? []).cast<String>();
      ApiService.addRecentlyViewed({
        'id': p['id'],
        'name': p['name'],
        'type': p['type'],
        'cover_photo': photos.isNotEmpty ? photos.first : null,
      });
    }).catchError((_) {
      // Detail failed to load — handled by FutureBuilder
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: AppDecorations.squircle(color: AppColors.errorSoft),
                        child: const Icon(Icons.error_outline, color: AppColors.error, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          }

          final p = snapshot.data!;
          final photos = (p['photos'] as List<dynamic>? ?? []).cast<String>();

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Full-bleed Image Gallery with Frosted Controls
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 320,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: photos.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                PageView.builder(
                                  itemCount: photos.length,
                                  onPageChanged: (i) => setState(() => _photoIndex = i),
                                  itemBuilder: (context, i) => Image.network(
                                    photos[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(color: AppColors.primaryLight),
                                  ),
                                ),
                                // Gradient shade on top and bottom
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.4),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.6),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),
                                // Indicator dots
                                if (photos.length > 1)
                                  Positioned(
                                    bottom: 16,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(photos.length, (i) {
                                        final active = i == _photoIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          width: active ? 22 : 7,
                                          height: 7,
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          decoration: BoxDecoration(
                                            color: active ? Colors.white : Colors.white54,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                              ],
                            )
                          : Container(
                              color: AppColors.primaryLight,
                              child: const Center(
                                child: Icon(Icons.apartment, size: 64, color: AppColors.tint),
                              ),
                            ),
                    ),
                  ),

                  // Detail Body
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type pill and Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: AppDecorations.badge(bg: AppColors.accentSoft),
                                child: Text(
                                  (p['type'] ?? 'COMMERCIAL').toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: AppDecorations.badge(bg: AppColors.successSoft),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified, size: 14, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified Space',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Property Name
                          Text(
                            p['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Address
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.location_on, size: 16, color: AppColors.accent),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  p['address'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.ink500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Lessor Profile Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppDecorations.card(radius: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: AppDecorations.squircle(color: AppColors.primary),
                                  child: const Icon(Icons.business, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'LISTED BY',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p['lessor_name'] ?? 'Pwestora Verified Partner',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Verified Landlord / Commercial Partner',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.ink500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Space Features / Guarantee Grid
                          const Text(
                            'Key Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _featureItem(
                                  icon: Icons.shield_outlined,
                                  title: 'Identity Verified',
                                  subtitle: 'Direct Lessor',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _featureItem(
                                  icon: Icons.description_outlined,
                                  title: 'Standard Terms',
                                  subtitle: 'Clear Agreements',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _featureItem(
                                  icon: Icons.support_agent_outlined,
                                  title: 'Maintenance',
                                  subtitle: 'Direct Reporting',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _featureItem(
                                  icon: Icons.access_time_outlined,
                                  title: 'Fast Review',
                                  subtitle: '1-2 Days Typical',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ApplyScreen(
                                  propertyId: p['id'] as int,
                                  propertyName: p['name'] ?? '',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Apply for this Space', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _featureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(radius: 14, shadow: false),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppDecorations.squircle(color: AppColors.accentSoft),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink900),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.ink500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}