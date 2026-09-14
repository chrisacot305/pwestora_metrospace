import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'property_detail_screen.dart';
import 'map_screen.dart';

class BrowseScreen extends StatefulWidget {
  final Future<void> Function()? onLeaseMayHaveChanged;
  const BrowseScreen({super.key, this.onLeaseMayHaveChanged});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late Future<List<dynamic>> _propertiesFuture;
  late Future<List<Map<String, dynamic>>> _recentFuture;
  String _query = '';
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();
  final Set<int> _savedPropertyIds = {};

  final _categories = const [
    ('All', Icons.grid_view_rounded),
    ('Retail', Icons.storefront_rounded),
    ('Office', Icons.business_rounded),
    ('Food & Dining', Icons.restaurant_rounded),
    ('Storage', Icons.inventory_2_rounded),
    ('Kiosk / Booth', Icons.store_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _propertiesFuture = ApiService.fetchProperties();
    _recentFuture = ApiService.getRecentlyViewed();
  }

  Future<void> _refresh() async {
    setState(() {
      _propertiesFuture = ApiService.fetchProperties();
      _recentFuture = ApiService.getRecentlyViewed();
    });
    await _propertiesFuture;
    if (widget.onLeaseMayHaveChanged != null) await widget.onLeaseMayHaveChanged!();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Top Bar: Location & Header (Dripzy Style)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Bacolod City · Negros Occidental',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink500,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.ink500),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Explore Spaces',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Image.asset('img/Frame 2.png', fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: AppColors.ink900, size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar & Filter Button (Dripzy Style)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: 'Search Bacolod malls, stalls, booths…',
                              hintStyle: const TextStyle(color: AppColors.ink300, fontSize: 13.5),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.ink500, size: 22),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: AppColors.ink500),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MapScreen(
                                  onLeaseMayHaveChanged: widget.onLeaseMayHaveChanged,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.map_outlined, color: AppColors.ink900, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Promotion Banner (Dripzy Promo Carousel Style)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 140,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'FEATURED SPACES',
                                  style: TextStyle(
                                    color: AppColors.tint,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Direct Commercial Leases',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Zero middleman markup · 100% verified lessors',
                                style: TextStyle(color: AppColors.tint, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Category Pills (Dripzy Style)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final (name, icon) = _categories[i];
                      final active = _selectedCategory == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setState(() => _selectedCategory = name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: active ? AppColors.primary : AppColors.border,
                                width: 1,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  size: 15,
                                  color: active ? Colors.white : AppColors.ink500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                    color: active ? Colors.white : AppColors.ink700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Recently Viewed Carousel (Dripzy Stories / Recent Look)
              SliverToBoxAdapter(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _recentFuture,
                  builder: (context, snapshot) {
                    final recent = snapshot.data ?? [];
                    if (recent.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              'Recently Viewed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              itemCount: recent.length,
                              itemBuilder: (context, i) {
                                final p = recent[i];
                                return GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PropertyDetailScreen(propertyId: p['id'] as int),
                                    ),
                                  ),
                                  child: Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(6),
                                    decoration: AppDecorations.card(radius: 12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: p['cover_photo'] != null
                                                ? Image.network(
                                                    p['cover_photo'],
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) => Container(color: AppColors.bg),
                                                  )
                                                : Container(color: AppColors.bg),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                p['name'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink900,
                                                ),
                                              ),
                                              Text(
                                                p['type'] ?? '',
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 9.5,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == 'All' ? 'Popular Spaces' : '$_selectedCategory Spaces',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Text(
                        'View all',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ),

              // 2-COLUMN GRID OF PROPERTY CARDS (Exact Dripzy Picture Placement)
              FutureBuilder<List<dynamic>>(
                future: _propertiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.wifi_off, size: 40, color: AppColors.ink300),
                            const SizedBox(height: 12),
                            Text(snapshot.error.toString(), textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _refresh, child: const Text('Try again')),
                          ],
                        ),
                      ),
                    );
                  }

                  var properties = snapshot.data ?? [];

                  if (_selectedCategory != 'All') {
                    properties = properties.where((p) {
                      final type = (p['type'] ?? '').toString().toLowerCase();
                      final filter = _selectedCategory.toLowerCase();
                      return type.contains(filter) || filter.contains(type);
                    }).toList();
                  }

                  if (_query.isNotEmpty) {
                    properties = properties.where((p) {
                      final name = (p['name'] ?? '').toString().toLowerCase();
                      final address = (p['address'] ?? '').toString().toLowerCase();
                      final type = (p['type'] ?? '').toString().toLowerCase();
                      return name.contains(_query) || address.contains(_query) || type.contains(_query);
                    }).toList();
                  }

                  if (properties.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: AppDecorations.squircle(color: AppColors.accentSoft),
                              child: const Icon(Icons.search_off, size: 32, color: AppColors.accent),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _query.isNotEmpty
                                  ? 'No spaces found for "$_query"'
                                  : 'No available spaces in "$_selectedCategory"',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink900),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try selecting another category or clearing your search.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.ink500, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 2-Column Staggered Grid Representation (Dripzy Marketplace)
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.64,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final prop = properties[i] as Map<String, dynamic>;
                          final id = prop['id'] as int? ?? 0;
                          final isSaved = _savedPropertyIds.contains(id);

                          return _DripzyGridCard(
                            property: prop,
                            isSaved: isSaved,
                            onSaveToggle: () {
                              setState(() {
                                if (isSaved) {
                                  _savedPropertyIds.remove(id);
                                } else {
                                  _savedPropertyIds.add(id);
                                }
                              });
                            },
                          );
                        },
                        childCount: properties.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exact Dripzy 2-Column Grid Card Design
class _DripzyGridCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const _DripzyGridCard({
    required this.property,
    required this.isSaved,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final coverPhoto = property['cover_photo'] as String?;
    final type = (property['type'] ?? 'RETAIL').toString().toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102340).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(propertyId: property['id'] as int),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Picture Container with Floating Action & Badges (Dripzy Picture Placement)
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: coverPhoto != null
                            ? Image.network(
                                coverPhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: AppColors.bg,
                                  child: const Icon(Icons.apartment, size: 36, color: AppColors.ink300),
                                ),
                              )
                            : Container(
                                color: AppColors.bg,
                                child: const Icon(Icons.apartment, size: 36, color: AppColors.ink300),
                              ),
                      ),
                      // Floating Type Badge (Top Left)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      // Floating Bookmark / Heart Button (Top Right, Dripzy style)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onSaveToggle,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              size: 16,
                              color: isSaved ? AppColors.primary : AppColors.ink500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property['name'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.ink500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  property['address'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.ink500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              property['lessor_name'] ?? 'Verified',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_forward, size: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
