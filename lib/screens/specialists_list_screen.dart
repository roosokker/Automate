import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../providers/specialist_provider.dart';
import '../models/service_center.dart';
import 'service_center_details_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

/// Service centers — full-bleed dark map with a glass search bar, filter chips
/// and swipeable center cards.
class SpecialistsListScreen extends StatefulWidget {
  /// True when opened as its own page (e.g. from vehicle details) rather than as a tab.
  final bool showBack;
  const SpecialistsListScreen({super.key, this.showBack = false});

  @override
  State<SpecialistsListScreen> createState() => _SpecialistsListScreenState();
}

class _SpecialistsListScreenState extends State<SpecialistsListScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final _pageController = PageController(viewportFraction: 0.8);
  GoogleMapController? _map;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _fetchData() {
    Provider.of<SpecialistProvider>(context, listen: false)
        .fetchServiceCenters(
      search: _searchController.text,
      type: _selectedFilter == 'All' ? null : _selectedFilter.toUpperCase().replaceAll(' ', '_'),
    );
  }

  void _openDetails(ServiceCenter center) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceCenterDetailsScreen(serviceCenter: center)),
    );
  }

  void _select(List<ServiceCenter> centers, int i, {bool scrollCards = true}) {
    if (i < 0 || i >= centers.length) return;
    setState(() => _selected = i);
    final c = centers[i];
    if (c.latitude != null && c.longitude != null) {
      _map?.animateCamera(CameraUpdate.newLatLng(LatLng(c.latitude!, c.longitude!)));
    }
    if (scrollCards && _pageController.hasClients) {
      _pageController.animateToPage(i, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpecialistProvider>(
      builder: (context, provider, child) {
        final centers = provider.serviceCenters;
        if (_selected >= centers.length) _selected = 0;
        final markers = <Marker>{};
        for (var i = 0; i < centers.length; i++) {
          final c = centers[i];
          if (c.latitude == null || c.longitude == null) continue;
          markers.add(Marker(
            markerId: MarkerId(c.id),
            position: LatLng(c.latitude!, c.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(i == _selected ? 262 : 235),
            alpha: i == _selected ? 1 : 0.75,
            zIndexInt: i == _selected ? 2 : 1,
            onTap: () => _select(centers, i),
          ));
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.bg,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(30.0444, 31.2357), // Default Cairo
                    zoom: 11.0,
                  ),
                  style: _darkMapStyle,
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (c) => _map = c,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                  },
                ),
              ),
            ),
            // Fade the map into the ground at the top and bottom.
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.bg, Color(0x00161826), Color(0x00161826), AppColors.bg],
                      stops: [0.02, 0.24, 0.55, 0.86],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Rise(
                      offset: 0,
                      durationMs: 400,
                      child: Row(
                        children: [
                          if (widget.showBack) ...[const AmBackButton(), const SizedBox(width: 10)],
                          Expanded(child: _searchBar()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        children: [
                          _buildFilterChip('All', PhosphorIconsRegular.squaresFour),
                          const SizedBox(width: 8),
                          _buildFilterChip('Authorized', PhosphorIconsRegular.sealCheck),
                          const SizedBox(width: 8),
                          _buildFilterChip('Non Authorized', PhosphorIconsRegular.wrench),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(PhosphorIconsRegular.navigationArrow, size: 14, color: AppColors.accent300),
                        const SizedBox(width: 6),
                        Text(
                          provider.isLoading ? 'Searching…' : '${centers.length} specialists near you',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: SafeArea(top: false, child: _cards(provider, centers)),
            ),
          ],
          ),
        );
      },
    );
  }

  Widget _searchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neutral700),
            boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.magnifyingGlass, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchData(),
                  onChanged: (_) => _fetchData(),
                  cursorColor: AppColors.accent,
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                  decoration: const InputDecoration(
                    hintText: 'Search workshops or services...',
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                onPressed: _fetchData,
                icon: const Icon(PhosphorIconsRegular.slidersHorizontal, size: 18, color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return AmChoice(
      label: label,
      icon: icon,
      selected: isSelected,
      height: 36,
      radius: 18,
      fontSize: 13,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _fetchData();
      },
    );
  }

  Widget _cards(SpecialistProvider provider, List<ServiceCenter> centers) {
    if (provider.isLoading) {
      return const SizedBox(height: 150, child: Center(child: AmSpinner(size: 28)));
    }
    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AmCard(
          radius: 14,
          edge: AppColors.dangerLine,
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.warningCircle, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(provider.error!, style: const TextStyle(color: AppColors.danger))),
            ],
          ),
        ),
      );
    }
    if (centers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: AmCard(
          radius: 14,
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.mapTrifold, color: AppColors.textMuted),
              SizedBox(width: 10),
              Text('No service centers found.', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 168,
      child: PageView.builder(
        controller: _pageController,
        padEnds: false,
        itemCount: centers.length,
        onPageChanged: (i) => _select(centers, i, scrollCards: false),
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6),
          child: Rise(delayMs: i < 3 ? i * 60 : 0, child: _centerCard(centers[i], i == _selected)),
        ),
      ),
    );
  }

  Widget _centerCard(ServiceCenter center, bool selected) {
    final isVerified = center.type == 'AUTHORIZED';
    return GestureDetector(
      onTap: () => _openDetails(center),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? AppColors.accent : AppColors.neutral700),
              boxShadow: selected ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 24)] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AmTag(
                      isVerified ? 'Verified specialist' : center.type.replaceAll('_', ' ').toLowerCase().replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase()),
                      icon: isVerified ? PhosphorIconsFill.sealCheck : PhosphorIconsRegular.wrench,
                      background: isVerified ? AppColors.accentDeep : AppColors.neutral800,
                      foreground: isVerified ? AppColors.accent100 : AppColors.neutral200,
                    ),
                    const Spacer(),
                    const Icon(PhosphorIconsFill.star, size: 13, color: AppColors.warn),
                    const SizedBox(width: 3),
                    const Text('4.8 (120)', style: TextStyle(fontSize: 12.5, color: AppColors.text)), // Static for now
                  ],
                ),
                const SizedBox(height: 10),
                Text(center.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, height: 1.25, color: AppColors.text)),
                const SizedBox(height: 2),
                Text('${center.address}, ${center.city}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AmText.sub),
                const Spacer(),
                Row(
                  children: [
                    AmIconButton(icon: PhosphorIconsRegular.phone, size: 40, radius: 8, onPressed: () {}),
                    const SizedBox(width: 8),
                    Expanded(child: AmButton.secondary(label: 'Route', icon: PhosphorIconsRegular.navigationArrow, height: 40, radius: 8, onPressed: () {})),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AmButton(
                        label: 'Details',
                        icon: PhosphorIconsRegular.storefront,
                        height: 40,
                        radius: 8,
                        fontSize: 14,
                        onPressed: () => _openDetails(center),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Google Maps style matching the Nocturne ground.
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#161826"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#75798c"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#161826"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#3f424d"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#1c1e2c"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1f2230"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#292b31"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#161826"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3f424d"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#9397ab"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1c1e2c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#262a60"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4c5397"}]}
]
''';
