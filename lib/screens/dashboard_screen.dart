import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/car_provider.dart';
import '../providers/specialist_provider.dart';
import '../models/service_center.dart';
import 'profile_screen.dart';
import 'add_vehicle_screen.dart';
import 'my_garage_screen.dart';
import 'notifications_screen.dart';
import '../widgets/notification_bell.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AutoMate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Fleet Health Header
              Consumer<CarProvider>(
                builder: (context, provider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Vehicles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      Text('${provider.cars.length} ACTIVE UNITS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted.withValues(alpha: 0.8), letterSpacing: 0.5)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              
              // Vehicle Cards
              Consumer<CarProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  }
                  
                  if (provider.cars.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          const Text('No vehicles added yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
                          const SizedBox(height: 8),
                          const Text('Add your first car to start tracking maintenance and expenses.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/add-vehicle'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text('Add a Vehicle'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Column(
                    children: provider.cars.map((car) {
                      final summary = provider.getSummary(car.id);
                      final isGood = summary?.isGood ?? true;
                      final subtitle = summary != null ? summary.statusText : 'Calculating...';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildVehicleCard(context, car.id, car.displayName, subtitle, isGood),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Map Widget
              Consumer<SpecialistProvider>(
                builder: (context, provider, child) {
                  Set<Marker> markers = provider.serviceCenters
                      .where((s) => s.latitude != null && s.longitude != null)
                      .map((center) {
                    return Marker(
                      markerId: MarkerId(center.id),
                      position: LatLng(center.latitude!, center.longitude!),
                      onTap: () {
                        _showSpecialistDetails(context, center);
                      },
                    );
                  }).toSet();
                  
                  return Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11), // Inner radius
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(30.0444, 31.2357), // Default Cairo
                          zoom: 11.0,
                        ),
                        markers: markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        gestureRecognizers: {
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Service Centers Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Service Centers Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const Text('View All', style: TextStyle(fontSize: 14, color: AppColors.text)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Service Center Cards
              Consumer<SpecialistProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                  }
                  
                  final centers = provider.serviceCenters.take(3).toList();
                  if (centers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No service centers found nearby.', style: TextStyle(color: AppColors.textFaint)),
                    );
                  }

                  return Column(
                    children: centers.map((center) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildServiceCenterCard(
                        title: center.name,
                        rating: '4.8',
                        reviews: '120 reviews',
                        distance: '${(center.latitude ?? 1.2)} km',
                        tags: [center.type.replaceAll('_', ' ')],
                      ),
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-vehicle');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: AppColors.text, size: 28),
      ),
    );
  }

  void _showSpecialistDetails(BuildContext context, ServiceCenter center) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      center.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.text),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      center.type.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${center.address}, ${center.city}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (center.phone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      center.phone!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(BuildContext context, String carId, String title, String subtitle, bool isGood) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/vehicle-details', arguments: carId);
      },
      child: Card(
        elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_car, color: AppColors.textMuted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isGood ? AppColors.okTint : AppColors.warnTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGood ? AppColors.ok : AppColors.warn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isGood ? 'GOOD' : 'WARNING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isGood ? AppColors.ok : AppColors.warn,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildServiceCenterCard({
    required String title,
    required String rating,
    required String reviews,
    required String distance,
    required List<String> tags,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint, // surface-container-high
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('OPEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_border, size: 14, color: AppColors.warn),
                const SizedBox(width: 4),
                Text(rating, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                Text('($reviews) • $distance', style: const TextStyle(fontSize: 14, color: AppColors.textFaint)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
