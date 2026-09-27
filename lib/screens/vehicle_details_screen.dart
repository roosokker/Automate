import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/car_provider.dart';
import '../providers/specialist_provider.dart';
import '../models/car.dart';
import '../models/maintenance_record.dart';
import '../widgets/record_details_modal.dart';
import '../widgets/notification_bell.dart';
import '../widgets/odometer_sheet.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/ui.dart';
import 'service_center_details_screen.dart';
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

  Future<void> _onMenu(String value) async {
    if (value == 'edit') {
      Navigator.pushNamed(context, '/add-vehicle', arguments: _carId);
    } else if (value == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Vehicle', style: AmText.h4),
          content: const Text('Are you sure you want to delete this vehicle? This action cannot be undone.', style: AmText.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
            ),
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
          showAmToast(context, 'Vehicle deleted');
          Navigator.pop(context); // Go back to dashboard
        } else if (mounted) {
          showAmToast(context, 'Failed to delete vehicle', error: true);
        }
      }
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
        if (car == null) {
          return const Scaffold(
            body: AmBackground(child: Center(child: AmSpinner(size: 28))),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            body: AmBackground(
              child: SafeArea(
                bottom: false,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(child: _buildHeader(context, car, provider)),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            isScrollable: false,
                            dividerColor: Colors.transparent,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: AppColors.accentTint,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: AppColors.accent700),
                            ),
                            labelColor: AppColors.accent200,
                            unselectedLabelColor: AppColors.textMuted,
                            labelPadding: EdgeInsets.zero,
                            overlayColor: WidgetStatePropertyAll(AppColors.accent.withValues(alpha: 0.06)),
                            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                            unselectedLabelStyle: const TextStyle(fontSize: 12.5),
                            tabs: const [
                              Tab(height: 34, text: 'Overview'),
                              Tab(height: 34, text: 'Services'),
                              Tab(height: 34, text: 'Expenses'),
                              Tab(height: 34, text: 'Reminders'),
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
              ),
            ),
            floatingActionButton: _Fab(
              onPressed: () {
                Navigator.pushNamed(context, '/add-record', arguments: _carId!);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Car car, CarProvider provider) {
    final summary = provider.getSummary(car.id);
    final status = summaryStatus(summary);
    final health = healthScore(summary);
    final glow = status == MStatus.ok || status == MStatus.soon ? AppColors.accent : status.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Rise(
            offset: 0,
            durationMs: 400,
            child: Row(
              children: [
                const AmBackButton(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${car.make} ${car.model}', overflow: TextOverflow.ellipsis, style: AmText.h3),
                      Text('${car.year} · Plate: Not Assigned', style: AmText.sub),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const NotificationBell(size: 44),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: _onMenu,
                  color: AppColors.surfaceHigh,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(PhosphorIconsRegular.pencilSimple, size: 18), SizedBox(width: 10), Text('Edit Vehicle')]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.trash, size: 18, color: AppColors.danger),
                          SizedBox(width: 10),
                          Text('Delete Vehicle', style: TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                  child: const AmIconButton(icon: PhosphorIconsRegular.dotsThreeVertical),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Hero
          Rise(
            child: Container(
              height: 150,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral800),
                gradient: RadialGradient(center: const Alignment(0, 1.25), radius: 0.95, colors: [glow.withValues(alpha: 0.42), AppColors.surface.withValues(alpha: 0)], stops: const [0, 0.7]),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      PhosphorIconsRegular.carProfile,
                      size: 100,
                      color: AppColors.textSecondary,
                      shadows: [Shadow(color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 8))],
                    ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: AmTag(
                      summary == null ? 'Active' : healthLabel(summary),
                      icon: PhosphorIconsFill.circle,
                      fontSize: 11,
                      background: status == MStatus.ok ? AppColors.accentDeep : status.tint,
                      foreground: status == MStatus.ok ? AppColors.accent100 : status.color,
                    ),
                  ),
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: AmIconButton(
                      icon: PhosphorIconsRegular.pencilSimple,
                      size: 38,
                      radius: 12,
                      onPressed: () => Navigator.pushNamed(context, '/add-vehicle', arguments: car.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Rise(
            delayMs: 80,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: AmCard(
                      onTap: () => showOdometerSheet(context, car),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ODOMETER', style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.textMuted)),
                              Icon(PhosphorIconsRegular.pencilSimple, size: 15, color: AppColors.accent),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: kmFormat.format(car.currentMileage)),
                                const TextSpan(
                                  text: ' km',
                                  style: TextStyle(fontSize: 13, color: AppColors.textMuted, letterSpacing: 0),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: -0.4, color: AppColors.text, fontFeatures: tabular),
                          ),
                          const Text('Tap to update', style: AmText.sub),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AmCard(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: health / 100),
                                  duration: const Duration(milliseconds: 1300),
                                  curve: const Cubic(0.2, 0.8, 0.2, 1),
                                  builder: (context, v, _) => CustomPaint(
                                    size: const Size(46, 46),
                                    painter: RingPainter(progress: v, color: AppColors.accent, stroke: 5, glow: false),
                                  ),
                                ),
                                Text(
                                  '$health',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text, fontFeatures: tabular),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('HEALTH', style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.textMuted)),
                                Text(
                                  summary?.statusText ?? 'Calculating...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, color: status == MStatus.ok ? AppColors.text : status.color),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  final VoidCallback onPressed;
  const _Fab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.92,
      onTap: onPressed,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment(-0.4, -1), end: Alignment(0.4, 1), colors: [AppColors.accentDeep, AppColors.neutral900]),
          border: Border.all(color: AppColors.accent),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.45), blurRadius: 26),
            const BoxShadow(color: Color(0x80000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: const Icon(PhosphorIconsRegular.plus, size: 24, color: AppColors.accent200),
      ),
    );
  }
}

MStatus _statusFromText(String s) {
  switch (s) {
    case 'Overdue':
      return MStatus.overdue;
    case 'Due':
      return MStatus.due;
    case 'Upcoming':
      return MStatus.soon;
    default:
      return MStatus.ok;
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
        final car = provider.getCar(carId);
        final reminders = sortedReminders(provider.getReminders(carId), car);
        final records = provider.getRecords(carId);

        // Calculate health values based on arrays
        final oilStatus = summary?.getStatusFor('ENGINE_OIL') ?? 'Good';
        final tireStatus = summary?.getStatusFor('TIRE_REPLACEMENT') ?? 'Good';
        final batteryStatus = summary?.getStatusFor('BATTERY') ?? 'Good';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Vehicle Health'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.3,
                children: [
                  _buildHealthCard(PhosphorIconsRegular.drop, 'Oil Life', oilStatus, 0),
                  _buildHealthCard(PhosphorIconsRegular.arrowsClockwise, 'Tires', tireStatus, 1),
                  _buildHealthCard(PhosphorIconsRegular.carBattery, 'Battery', batteryStatus, 2),
                  _buildHealthCard(PhosphorIconsRegular.gasPump, 'Fuel Level', 'N/A', 3),
                ],
              ),
              const SizedBox(height: 24),

              SectionLabel('Upcoming Reminders', trailing: AmLink('View All', fontSize: 12.5, onTap: () => DefaultTabController.of(context).animateTo(3))),
              const SizedBox(height: 10),
              if (reminders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No upcoming reminders', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                ...reminders.asMap().entries.map((entry) {
                  final view = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Rise(
                      delayMs: math.min(entry.key, 6) * 50,
                      child: _ReminderCard(
                        view: view,
                        onTap: () {
                          Navigator.pushNamed(context, '/reminder-details', arguments: {'reminder': view.reminder, 'carId': carId});
                        },
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 14),

              SectionLabel(
                'Nearby Specialists',
                trailing: AmLink(
                  'View All',
                  fontSize: 12.5,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SpecialistsListScreen(showBack: true)));
                  },
                ),
              ),
              const SizedBox(height: 10),
              Consumer<SpecialistProvider>(
                builder: (context, sp, _) {
                  final centers = sp.serviceCenters.take(4).toList();
                  if (centers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No service centers found nearby.', style: TextStyle(color: AppColors.textMuted)),
                    );
                  }
                  return SizedBox(
                    height: 142,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: centers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final c = centers[i];
                        final authorized = c.type == 'AUTHORIZED';
                        return SizedBox(
                          width: 240,
                          child: AmCard(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceCenterDetailsScreen(serviceCenter: c))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AmTag(
                                  authorized ? 'Verified specialist' : c.type.replaceAll('_', ' '),
                                  icon: authorized ? PhosphorIconsFill.sealCheck : PhosphorIconsRegular.wrench,
                                  background: authorized ? AppColors.accentDeep : AppColors.neutral800,
                                  foreground: authorized ? AppColors.accent100 : AppColors.neutral200,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.text),
                                ),
                                Text(c.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: AmText.sub),
                                const Spacer(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AmButton.secondary(label: 'Call', icon: PhosphorIconsRegular.phone, height: 34, radius: 8, fontSize: 12.5, onPressed: () {}),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: AmButton(label: 'Route', icon: PhosphorIconsRegular.navigationArrow, height: 34, radius: 8, fontSize: 12.5, onPressed: () {}),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              const SectionLabel('Service Timeline'),
              const SizedBox(height: 14),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No service history available', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                _Timeline(records: records.take(3).toList(), onTap: (record) => showRecordDetailsModal(context, record)),

              const SizedBox(height: 4),
              AmLink('View Full History', icon: PhosphorIconsRegular.arrowRight, onTap: () => DefaultTabController.of(context).animateTo(2)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthCard(IconData icon, String title, String value, int i) {
    final st = value == 'N/A' ? MStatus.ok : _statusFromText(value);
    final alert = st == MStatus.overdue || st == MStatus.due;
    return Rise(
      delayMs: i * 50,
      child: AmCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: alert ? null : AppColors.surface,
        gradient: alert ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [st.tint, AppColors.surface]) : null,
        edge: alert ? st.edge : AppColors.neutral800,
        child: Row(
          children: [
            IconTile(icon: icon, size: 36, radius: 11, color: alert ? st.color : AppColors.accent300, background: alert ? st.tint : AppColors.accentTint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Text(value, style: TextStyle(fontSize: 14, color: alert ? st.color : (st == MStatus.soon ? st.color : AppColors.text))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maintenance item card: tinted icon, name, due point, km left and a progress bar.
class _ReminderCard extends StatelessWidget {
  final ReminderView view;
  final VoidCallback? onTap;
  const _ReminderCard({required this.view, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = view.status.color;
    final urgent = view.status == MStatus.overdue || view.status == MStatus.due;
    return AmCard(
      onTap: onTap,
      edge: urgent ? view.status.edge : AppColors.neutral800,
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: view.icon, color: color, background: view.status.tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.name, style: const TextStyle(fontSize: 15, color: AppColors.text)),
                    Text(view.dueAt, style: AmText.sub),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    view.leftLabel,
                    style: TextStyle(fontSize: 14, color: color, fontFeatures: tabular),
                  ),
                  Text(view.status.label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          GlowBar(value: view.progress, color: color, glow: urgent),
        ],
      ),
    );
  }
}

/// Vertical timeline with a fading accent spine.
class _Timeline extends StatelessWidget {
  final List<MaintenanceRecord> records;
  final void Function(MaintenanceRecord) onTap;
  final bool showPrice;
  const _Timeline({required this.records, required this.onTap, this.showPrice = false});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0');
    return Stack(
      children: [
        PositionedDirectional(
          start: 9,
          top: 8,
          bottom: 26,
          child: Container(
            width: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.accent, AppColors.neutral800, Color(0x003F424D)], stops: [0, 0.45, 1]),
            ),
          ),
        ),
        Column(
          children: records.asMap().entries.map((entry) {
            final i = entry.key;
            final record = entry.value;
            final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal());
            final dotColor = i == 0 ? AppColors.accent : AppColors.neutral700;
            return Rise(
              delayMs: math.min(i, 6) * 60,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(record),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 3, top: 3),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.bg,
                            border: Border.all(color: dotColor, width: 2),
                            boxShadow: i == 0 ? AppColors.glow(0.8, 8) : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: AmCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(typeIcon(record.maintenanceType), size: 16, color: AppColors.accent300),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(typeLabel(record.maintenanceType), style: const TextStyle(fontSize: 14.5, color: AppColors.text)),
                                  ),
                                  if (showPrice)
                                    Text(
                                      'EGP ${record.cost.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13.5, color: AppColors.text, fontFeatures: tabular),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('$formattedDate · ${numberFormat.format(record.mileageAtService)} km', style: AmText.sub),
                              if (showPrice) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(PhosphorIconsRegular.sealCheck, size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(record.serviceCenterId ?? 'Verified Workshop', maxLines: 1, overflow: TextOverflow.ellipsis, style: AmText.sub),
                                    ),
                                  ],
                                ),
                              ] else if (record.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(record.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Scheduled Services', trailing: Icon(PhosphorIconsRegular.calendarBlank, size: 18, color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Rise(
                child: AmCard(
                  radius: 16,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accentTint, AppColors.surface], stops: [0, 0.7]),
                  edge: AppColors.accentDeep,
                  onTap: () => showScheduledServiceModal(context, 'Major Engine Service', 'Due in 1,240 km • Oct 24, 2024'),
                  child: Row(
                    children: [
                      const IconTile(icon: PhosphorIconsRegular.gearSix, size: 44, radius: 13, edge: AppColors.accentDeep),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Major Engine Service', style: TextStyle(fontSize: 14.5, color: AppColors.text)),
                            SizedBox(height: 2),
                            Text('Due in 1,240 km • Oct 24, 2024', style: AmText.sub),
                          ],
                        ),
                      ),
                      AmButton(label: 'BOOK', height: 36, fontSize: 12.5, radius: 10, expand: false, padding: const EdgeInsets.symmetric(horizontal: 14), onPressed: () {}),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),

              SectionLabel('Service History', trailing: AmLink('View All', fontSize: 12.5, onTap: () => DefaultTabController.of(context).animateTo(2))),
              const SizedBox(height: 14),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No service history available', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                _Timeline(records: records, showPrice: true, onTap: (record) => showRecordDetailsModal(context, record)),
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bg.withValues(alpha: overlapsContent || shrinkOffset > 0 ? 0.96 : 0),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral800),
        ),
        child: _tabBar,
      ),
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
    return Consumer<CarProvider>(
      builder: (context, provider, child) {
        final records = provider.getRecords(carId);
        final totalExpenses = records.fold<double>(0.0, (sum, record) => sum + record.cost);
        final numberFormat = NumberFormat('#,##0.00');

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Rise(
                child: AmCard(
                  radius: 16,
                  padding: const EdgeInsets.all(16),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.section, AppColors.accentTint], stops: [0, 0.75]),
                  edge: AppColors.sectionGhost,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Maintenance Expenses', style: TextStyle(color: AppColors.accent200, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('EGP', style: TextStyle(fontSize: 14, color: AppColors.accent200)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: CountUp(
                                value: totalExpenses,
                                format: (v) => numberFormat.format(v),
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w500, letterSpacing: -1.2, color: AppColors.text),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text('${records.length} records', style: const TextStyle(fontSize: 12, color: AppColors.accent200)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SectionLabel('Expense History'),
              const SizedBox(height: 4),
              if (records.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No expenses recorded yet', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ...records.asMap().entries.map((entry) {
                  final record = entry.value;
                  return Rise(
                    delayMs: math.min(entry.key, 8) * 40,
                    durationMs: 400,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showRecordDetailsModal(context, record),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                IconTile(icon: typeIcon(record.maintenanceType), background: AppColors.surface, edge: AppColors.neutral800),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(typeLabel(record.maintenanceType), style: const TextStyle(fontSize: 14, color: AppColors.text)),
                                      Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal()), style: AmText.sub),
                                    ],
                                  ),
                                ),
                                Text(
                                  'EGP ${numberFormat.format(record.cost)}',
                                  style: const TextStyle(fontSize: 14, color: AppColors.text, fontFeatures: tabular),
                                ),
                              ],
                            ),
                          ),
                          const FadingRule(),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _RemindersTab extends StatelessWidget {
  final String carId;

  const _RemindersTab({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(
      builder: (context, provider, child) {
        final car = provider.getCar(carId);
        final reminders = sortedReminders(provider.getReminders(carId), car);
        final counts = {for (final s in MStatus.values) s: reminders.where((r) => r.status == s).length};

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Rise(
                child: Row(
                  children: MStatus.values.map((s) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: s == MStatus.overdue ? 0 : 8),
                        child: AmCard(
                          radius: 12,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${counts[s]}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: s.color, fontFeatures: tabular),
                              ),
                              Text(s.label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Maintenance Reminders'),
              const SizedBox(height: 10),
              if (reminders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No active reminders', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ...reminders.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Rise(
                      delayMs: math.min(entry.key, 6) * 50,
                      child: _ReminderCard(view: entry.value),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
