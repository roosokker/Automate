import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/car_provider.dart';
import '../models/car.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_summary.dart';
import '../widgets/record_details_modal.dart';
import 'notifications_screen.dart';
import '../widgets/notification_bell.dart';
import 'profile_screen.dart';
import 'specialists_list_screen.dart';
import '../theme/app_colors.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  String? _carId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _carId = ModalRoute.of(context)?.settings.arguments as String?;
      if (_carId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final provider = Provider.of<CarProvider>(context, listen: false);
          provider.fetchRecords(_carId!);
          provider.fetchReminders(_carId!);
        });
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carId == null) {
      return const Scaffold(body: Center(child: Text('Error: No car selected')));
    }

    return Consumer<CarProvider>(
      builder: (context, provider, child) {
        final car = provider.getCar(_carId!);
        if (car == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'AutoMate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          actions: [
            const NotificationBell(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.text),
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.pushNamed(context, '/add-vehicle', arguments: _carId);
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Vehicle'),
                      content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('DELETE', style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && mounted) {
                    final provider = Provider.of<CarProvider>(context, listen: false);
                    final success = await provider.deleteCar(_carId!);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle deleted')));
                      Navigator.pop(context); // Go back to dashboard
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete vehicle')));
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Vehicle'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Vehicle', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: const CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
              ),
            )
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildHeader(context, car),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    isScrollable: true,
                    labelColor: AppColors.text,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.accent,
                    labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1),
                    tabs: [
                      Tab(text: 'OVERVIEW'),
                      Tab(text: 'SERVICES'),
                      Tab(text: 'EXPENSES'),
                      Tab(text: 'REMINDERS'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _OverviewTab(carId: _carId!),
              _ServicesTab(carId: _carId!),
              _ExpensesTab(carId: _carId!),
              _RemindersTab(carId: _carId!),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add-record', arguments: _carId!);
          },
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add, color: AppColors.text),
        ),
      ),
    );
  });
}

  void _showUpdateMileageModal(BuildContext context, Car car) {
    final TextEditingController mileageController = TextEditingController(text: car.currentMileage.toString());
    bool isLoading = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Update Mileage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Current mileage: ${car.currentMileage} km', style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: mileageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'New Mileage (km)',
                      prefixIcon: const Icon(Icons.speed),
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final input = int.tryParse(mileageController.text.trim());
                            if (input == null) {
                              setState(() => errorText = 'Please enter a valid number');
                              return;
                            }
                            if (input <= car.currentMileage) {
                              setState(() => errorText = 'New mileage must be greater than current');
                              return;
                            }

                            setState(() {
                              isLoading = true;
                              errorText = null;
                            });

                            final provider = Provider.of<CarProvider>(context, listen: false);
                            final success = await provider.logMileage(car.id, input);

                            if (!context.mounted) return;

                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mileage updated successfully!'), backgroundColor: AppColors.accentDeep),
                              );
                            } else {
                              setState(() {
                                isLoading = false;
                                errorText = 'Failed to update mileage. Please try again.';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentDeep,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.text, strokeWidth: 2))
                        : const Text('Save Odometer Reading', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Car car) {
    final numberFormat = NumberFormat('#,##0');
    final formattedMileage = '${numberFormat.format(car.currentMileage)} km';
    
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image Container
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?q=80&w=2070&auto=format&fit=crop'), // Placeholder Mercedes image
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: AppColors.text, size: 8),
                        SizedBox(width: 6),
                        Text('Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${car.year}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(car.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text('Plate: Not Assigned', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text.withValues(alpha: 0.8))),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/add-vehicle', arguments: car.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lineStrong),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, size: 20, color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showUpdateMileageModal(context, car),
                    child: _buildInfoCard(Icons.speed, 'Odometer', formattedMileage, showEdit: true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoCard(Icons.settings_suggest, 'Engine', 'Varies'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, {bool showEdit = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ],
              ),
              if (showEdit)
                const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String carId;
  const _OverviewTab({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(
      builder: (context, provider, child) {
        final summary = provider.getSummary(carId);
        final reminders = provider.getReminders(carId);
        final records = provider.getRecords(carId);
        
        // Calculate health values based on arrays
        final oilStatus = summary?.getStatusFor('ENGINE_OIL') ?? 'Good';
        final tireStatus = summary?.getStatusFor('TIRE_REPLACEMENT') ?? 'Good';
        final batteryStatus = summary?.getStatusFor('BATTERY') ?? 'Good';
        
        return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vehicle Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildHealthCard(Icons.oil_barrel_outlined, 'Oil Life', oilStatus, oilStatus == 'Overdue' || oilStatus == 'Due'),
              _buildHealthCard(Icons.tire_repair_outlined, 'Tires', tireStatus, tireStatus == 'Overdue' || tireStatus == 'Due'),
              _buildHealthCard(Icons.battery_charging_full_outlined, 'Battery', batteryStatus, batteryStatus == 'Overdue' || batteryStatus == 'Due'),
              _buildHealthCard(Icons.local_gas_station_outlined, 'Fuel Level', 'N/A', false),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Reminders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () => DefaultTabController.of(context).animateTo(3),
                child: Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text.withValues(alpha: 0.8))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (reminders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming reminders', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ...reminders.map((reminder) {
              final isUrgent = reminder.status == 'OVERDUE' || reminder.status == 'DUE';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildReminderCard(
                  Icons.warning_amber_rounded, 
                  reminder.maintenanceType, 
                  'Status: ${reminder.status}', 
                  'View', 
                  isUrgent,
                  onPressed: () {
                    Navigator.pushNamed(context, '/reminder-details', arguments: {
                      'reminder': reminder,
                      'carId': carId,
                    });
                  },
                ),
              );
            }),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storefront, size: 20, color: AppColors.text),
                  SizedBox(width: 8),
                  Text('Nearby Specialists', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpecialistsListScreen()),
                  );
                },
                child: Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text.withValues(alpha: 0.8))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSpecialistCard('Elite German Auto', 'Mercedes Specialist', '2.4 km away', '4.8 (124)'),
                const SizedBox(width: 12),
                _buildSpecialistCard('Tire Hub Cairo', 'Tire Center', '1.1 km away', '4.5 (89)'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Service Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No service history available', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ...records.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final numberFormat = NumberFormat('#,##0');
              final formattedMileage = '${numberFormat.format(record.mileageAtService)} km';
              final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal());
              return _buildTimelineItem(
                '$formattedDate • $formattedMileage', 
                record.maintenanceType, 
                record.description, 
                isFirst: index == 0,
                isLast: index == 2 || index == records.length - 1,
                onTap: () => showRecordDetailsModal(context, record),
              );
            }),
          
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => DefaultTabController.of(context).animateTo(2),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View Full History', style: TextStyle(color: AppColors.textMuted)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
              ],
            ),
          )
        ],
      ),
    );
    });
  }

  Widget _buildHealthCard(IconData icon, String title, String value, bool isAlert) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.dangerTint : AppColors.surface,
        border: Border.all(color: isAlert ? AppColors.dangerLine : AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isAlert ? AppColors.danger : AppColors.text),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 10, color: isAlert ? AppColors.danger : AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isAlert ? AppColors.danger : AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildReminderCard(IconData icon, String title, String subtitle, String action, bool isUrgent, {VoidCallback? onPressed}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? AppColors.dangerTint : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isUrgent ? AppColors.danger : AppColors.textMuted, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPressed ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isUrgent ? AppColors.accentDeep : AppColors.surface,
              foregroundColor: isUrgent ? AppColors.text : AppColors.text,
              side: isUrgent ? BorderSide.none : const BorderSide(color: AppColors.lineStrong),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
            ),
            child: Text(action, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(String title, String subtitle, String distance, String rating) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.accentTint,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.image, color: AppColors.textMuted)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 10),
                        const SizedBox(width: 2),
                        Text(rating, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceHigh,
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: AppColors.text),
                            SizedBox(width: 4),
                            Text('Call', style: TextStyle(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentDeep,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions, size: 14, color: AppColors.text),
                            SizedBox(width: 4),
                            Text('Route', style: TextStyle(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String date, String title, String description, {bool isFirst = false, bool isLast = false, VoidCallback? onTap}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: isFirst ? Colors.transparent : AppColors.surfaceHigh,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isFirst ? AppColors.accent : AppColors.lineStrong, width: 2),
                  ),
                  child: isFirst ? Center(child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle))) : null,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.surfaceHigh,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.text),
                            const SizedBox(width: 8),
                            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  final String carId;
  const _ServicesTab({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(
      builder: (context, provider, child) {
        final records = provider.getRecords(carId);
        final numberFormat = NumberFormat('#,##0');
        
        return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Scheduled Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Icon(Icons.calendar_month, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => showScheduledServiceModal(context, 'Major Engine Service', 'Due in 1,240 km • Oct 24, 2024'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_suggest, color: AppColors.text),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Major Engine Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Due in 1,240 km • Oct 24, 2024', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentDeep,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('BOOK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => DefaultTabController.of(context).animateTo(2),
                child: Row(
                  children: [
                    const Text('VIEW ALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No service history available', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ...records.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final formattedMileage = '${numberFormat.format(record.mileageAtService)} km';
              final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal());
              return _buildHistoryItem(
                formattedDate, 
                'EGP ${record.cost.toStringAsFixed(2)}', 
                record.maintenanceType, 
                formattedMileage, 
                record.serviceCenterId ?? 'Verified Workshop', 
                isFirst: index == 0, 
                isLast: index == records.length - 1,
                onTap: () => showRecordDetailsModal(context, record),
              );
            }),
        ],
      ),
    );
    });
  }

  Widget _buildHistoryItem(String date, String price, String title, String mileage, String footerTag, {bool isFirst = false, bool isLast = false, VoidCallback? onTap}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 1,
                  height: 16,
                  color: isFirst ? Colors.transparent : AppColors.surfaceHigh,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: isFirst ? AppColors.accent : AppColors.lineStrong, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: isLast ? Colors.transparent : AppColors.surfaceHigh,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(date, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.text)),
                        Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(title, style: const TextStyle(fontSize: 16, color: AppColors.text)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(mileage, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 16),
                        const Icon(Icons.verified_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(child: Text(footerTag, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
                      ],
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _ExpensesTab extends StatelessWidget {
  final String carId;

  const _ExpensesTab({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(builder: (context, provider, child) {
      final records = provider.getRecords(carId);
      final totalExpenses = records.fold<double>(0.0, (sum, record) => sum + record.cost);
      final numberFormat = NumberFormat('#,##0.00');

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentDeep,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: AppColors.text, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Maintenance Expenses', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('EGP ${numberFormat.format(totalExpenses)}', style: const TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Expense History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (records.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No expenses recorded yet', style: TextStyle(color: AppColors.textMuted)),
              ))
            else
              ...records.map((record) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showRecordDetailsModal(context, record),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.maintenanceType.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal()), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('EGP ${numberFormat.format(record.cost)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text)),
                  ],
                ),
                ),
              )),
          ],
        ),
      );
    });
  }
}

class _RemindersTab extends StatelessWidget {
  final String carId;

  const _RemindersTab({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(builder: (context, provider, child) {
      final reminders = provider.getReminders(carId);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maintenance Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (reminders.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No active reminders', style: TextStyle(color: AppColors.textMuted)),
              ))
            else
              ...reminders.map((reminder) {
                Color statusColor;
                IconData statusIcon;
                switch (reminder.status) {
                  case 'OVERDUE':
                    statusColor = AppColors.danger;
                    statusIcon = Icons.error_outline;
                    break;
                  case 'DUE':
                    statusColor = AppColors.warn;
                    statusIcon = Icons.warning_amber_rounded;
                    break;
                  case 'UPCOMING':
                    statusColor = AppColors.accent;
                    statusIcon = Icons.info_outline;
                    break;
                  default:
                    statusColor = AppColors.accent;
                    statusIcon = Icons.check_circle_outline;
                }

                final numberFormat = NumberFormat('#,##0');
                final dueText = reminder.dueMileage != null ? '${numberFormat.format(reminder.dueMileage)} km' : (reminder.dueDate ?? 'N/A');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(statusIcon, color: statusColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reminder.maintenanceType.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Due at: $dueText', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(reminder.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      );
    });
  }
}
