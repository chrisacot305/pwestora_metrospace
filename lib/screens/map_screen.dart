import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../services/api_service.dart';
import 'property_detail_screen.dart';
import 'apply_screen.dart';

class MapScreen extends StatefulWidget {
  final Future<void> Function()? onLeaseMayHaveChanged;

  const MapScreen({super.key, this.onLeaseMayHaveChanged});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  late Future<List<dynamic>> _propertiesFuture;
  Map<String, dynamic>? _selectedProperty;

  String _selectedCategory = 'All';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Strict Bacolod City Geographic Center & Camera Boundaries
  static const LatLng _bacolodCenter = LatLng(10.6765, 122.9510);
  
  // Bounding box strictly encompassing Bacolod City limits
  static final LatLngBounds _bacolodBounds = LatLngBounds(
    const LatLng(10.5700, 122.8600), // Southwest (Sum-ag / Pahanocoy / Handumanan)
    const LatLng(10.7400, 123.0300), // Northeast (Bata / Mandalagan / Estefania / Granada)
  );

  static const double _minAllowedZoom = 12.2;
  static const double _maxAllowedZoom = 18.5;
  double _currentZoom = 13.8;

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
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Extracts or generates realistic coordinates strictly clustered in Bacolod City commercial hubs
  LatLng _getPropertyLatLng(Map<String, dynamic> p) {
    if (p['latitude'] != null && p['longitude'] != null) {
      final lat = double.tryParse(p['latitude'].toString());
      final lng = double.tryParse(p['longitude'].toString());
      if (lat != null && lng != null) {
        final pt = LatLng(lat, lng);
        if (_bacolodBounds.contains(pt)) return pt;
      }
    }
    if (p['lat'] != null && p['lng'] != null) {
      final lat = double.tryParse(p['lat'].toString());
      final lng = double.tryParse(p['lng'].toString());
      if (lat != null && lng != null) {
        final pt = LatLng(lat, lng);
        if (_bacolodBounds.contains(pt)) return pt;
      }
    }

    // Realistic Bacolod City commercial districts & hubs
    final id = (p['id'] as num?)?.toInt() ?? 1;
    final bacolodCommercialHubs = [
      const LatLng(10.6765, 122.9530), // Lacson St / Tourism & Dining Strip
      const LatLng(10.6690, 122.9430), // SM City Bacolod / Reclamation Area
      const LatLng(10.6738, 122.9515), // Ayala Malls Capitol Central / Gatuslao
      const LatLng(10.6660, 122.9620), // Megaworld The Upper East Commercial Hub
      const LatLng(10.6705, 122.9480), // Bacolod Public Plaza & San Sebastian
      const LatLng(10.6730, 122.9650), // Burgos St / Villamonte Commercial Area
      const LatLng(10.6930, 122.9590), // Art District & Mandalagan Commercial
      const LatLng(10.6700, 122.9720), // Lopue's East Centre / Circumferential
      const LatLng(10.6620, 122.9540), // Libertad Commercial & Market District
      const LatLng(10.7020, 122.9620), // Robinsons Place Bacolod / Bata Highway
      const LatLng(10.6720, 122.9350), // BREDCO Commercial Complex
      const LatLng(10.6480, 122.9580), // Alijis Road Commercial Hub
    ];
    return bacolodCommercialHubs[(id - 1) % bacolodCommercialHubs.length];
  }

  /// Free Photon OSM Geocoding Search strictly constrained to Bacolod City
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final sanitizedQuery = query.toLowerCase().contains('bacolod') ? query : '$query Bacolod';
      final uri = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(sanitizedQuery)}&bbox=122.86,10.57,123.03,10.74&limit=6',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final features = data['features'] as List<dynamic>? ?? [];
        final results = <Map<String, dynamic>>[];

        for (final f in features) {
          final geometry = f['geometry'];
          final props = f['properties'] as Map<String, dynamic>? ?? {};
          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List<dynamic>;
            final lng = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            final pt = LatLng(lat, lng);

            // Ensure point is within Bacolod bounds
            if (_bacolodBounds.contains(pt)) {
              final name = props['name'] ?? props['street'] ?? props['city'] ?? query;
              final city = props['city'] ?? props['district'] ?? props['state'] ?? 'Bacolod City';
              results.add({
                'name': name,
                'subtitle': '$city, Negros Occidental',
                'lat': lat,
                'lng': lng,
              });
            }
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _moveToLocation(LatLng target, {double zoom = 15.0}) {
    // Keep target inside Bacolod bounds
    final clampedLat = target.latitude.clamp(_bacolodBounds.south, _bacolodBounds.north);
    final clampedLng = target.longitude.clamp(_bacolodBounds.west, _bacolodBounds.east);
    final safeTarget = LatLng(clampedLat, clampedLng);

    _mapController.move(safeTarget, zoom);
    setState(() {
      _currentZoom = zoom;
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();
  }

  List<dynamic> _filterProperties(List<dynamic> list) {
    return list.where((item) {
      final p = item as Map<String, dynamic>;
      if (_selectedCategory != 'All') {
        final type = (p['type'] ?? '').toString().toLowerCase();
        if (!type.contains(_selectedCategory.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _formatRent(dynamic rent) {
    if (rent == null) return '₱0';
    final val = num.tryParse(rent.toString()) ?? 0;
    if (val >= 1000) {
      return '₱${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}k';
    }
    return '₱$val';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // 1. FlutterMap with Strict Bacolod City Camera Constraints (Cannot zoom or pan out)
          FutureBuilder<List<dynamic>>(
            future: _propertiesFuture,
            builder: (context, snapshot) {
              final rawList = snapshot.data ?? [];
              final filtered = _filterProperties(rawList);

              final markers = filtered.map((item) {
                final p = item as Map<String, dynamic>;
                final coord = _getPropertyLatLng(p);
                final isSelected = _selectedProperty?['id'] == p['id'];
                final rentText = _formatRent(p['asking_rent'] ?? p['monthly_rent'] ?? p['rent']);

                return Marker(
                  point: coord,
                  width: isSelected ? 110 : 85,
                  height: 48,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedProperty = p);
                      _mapController.move(coord, _mapController.camera.zoom);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.ink900 : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.tint : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isSelected ? 0.25 : 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            size: 14,
                            color: isSelected ? AppColors.tint : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              rentText,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppColors.ink900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _bacolodCenter,
                  initialZoom: _currentZoom,
                  minZoom: _minAllowedZoom, // Cannot zoom out past Bacolod City
                  maxZoom: _maxAllowedZoom,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: _bacolodBounds, // Locked strictly inside Bacolod boundaries
                  ),
                  onTap: (tapPosition, point) {
                    if (_selectedProperty != null) {
                      setState(() => _selectedProperty = null);
                    }
                    if (_searchResults.isNotEmpty) {
                      setState(() => _searchResults = []);
                    }
                    FocusScope.of(context).unfocus();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pwestora.app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          // 2. Top Bar & Bacolod Photon Search Input
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    children: [
                      // Back to List Button
                      Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink900, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Search input
                      Expanded(
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.15),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _searchLocation,
                              decoration: InputDecoration(
                                hintText: 'Search Bacolod (e.g. Lacson, SM, Ayala, BGC)…',
                                hintStyle: const TextStyle(color: AppColors.ink300, fontSize: 12.5),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.ink500, size: 20),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: AppColors.ink500),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _searchResults = []);
                                        },
                                      )
                                    : (_isSearching
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                            ),
                                          )
                                        : null),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Results Dropdown (Bacolod Photon API results)
                if (_searchResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      elevation: 6,
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.surface,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, i) {
                            final item = _searchResults[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                              title: Text(
                                item['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink900),
                              ),
                              subtitle: item['subtitle'] != ''
                                  ? Text(
                                      item['subtitle'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppColors.ink500),
                                    )
                                  : null,
                              onTap: () {
                                final lat = item['lat'] as double;
                                final lng = item['lng'] as double;
                                _moveToLocation(LatLng(lat, lng));
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => setState(() => _selectedCategory = cat.$1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat.$2,
                                    size: 14,
                                    color: isSelected ? Colors.white : AppColors.ink700,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    cat.$1,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.ink900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 3. Map Controls (Zoom In, Zoom Out, Recenter to Bacolod City)
          Positioned(
            right: 16,
            bottom: _selectedProperty != null ? 240 : 28,
            child: Column(
              children: [
                _buildMapButton(
                  icon: Icons.add,
                  onTap: () {
                    final newZoom = (_mapController.camera.zoom + 1).clamp(_minAllowedZoom, _maxAllowedZoom);
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.remove,
                  onTap: () {
                    final newZoom = (_mapController.camera.zoom - 1).clamp(_minAllowedZoom, _maxAllowedZoom);
                    _mapController.move(_mapController.camera.center, newZoom);
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  onTap: () => _moveToLocation(_bacolodCenter, zoom: 13.8),
                ),
              ],
            ),
          ),

          // 4. Selected Property Bottom Sheet Preview Card
          if (_selectedProperty != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: _buildPropertyCard(_selectedProperty!),
            ),
        ],
      ),
    );
  }

  Widget _buildMapButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.ink900, size: 20),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final photos = (property['photos'] as List<dynamic>? ?? []).cast<String>();
    final coverPhoto = photos.isNotEmpty ? photos.first : null;
    final name = property['name'] ?? 'Commercial Space';
    final type = property['type'] ?? 'Retail';
    final rent = property['asking_rent'] ?? property['monthly_rent'] ?? property['rent'] ?? 0;
    final size = property['floor_area_sqm'] ?? property['size_sqm'] ?? '-';
    final address = property['address'] ?? property['location'] ?? 'Bacolod City, Negros Occidental';
    final propertyId = (property['id'] as num?)?.toInt() ?? 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 78,
                    height: 78,
                    color: AppColors.borderLight,
                    child: coverPhoto != null && coverPhoto.startsWith('http')
                        ? Image.network(
                            coverPhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.storefront, color: AppColors.ink300, size: 32),
                          )
                        : const Icon(Icons.storefront, color: AppColors.ink300, size: 32),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type.toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.ink500),
                            onPressed: () => setState(() => _selectedProperty = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.ink500),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              address.toString(),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.ink500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Price & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₱$rent / mo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '$size sqm available',
                      style: const TextStyle(fontSize: 11, color: AppColors.ink500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailScreen(propertyId: propertyId),
                          ),
                        );
                      },
                      child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApplyScreen(
                              propertyId: propertyId,
                              propertyName: name,
                            ),
                          ),
                        );
                      },
                      child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
