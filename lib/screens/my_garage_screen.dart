import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/ui.dart';

class MyGarageScreen extends StatelessWidget {
  const MyGarageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AmBackground(
      child: SafeArea(
        bottom: false,
        child: Consumer<CarProvider>(
          builder: (context, provider, child) {
            final cars = provider.cars;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              children: [
                ScreenHeader(
                  title: 'Garage',
                  subtitle: cars.isEmpty ? 'Manage your registered vehicles' : '${cars.length} ${cars.length == 1 ? 'vehicle' : 'vehicles'} · tap to open',
                  actions: [
                    AmIconButton(
                      icon: PhosphorIconsRegular.plus,
                      primary: true,
                      onPressed: () => Navigator.pushNamed(context, '/add-vehicle'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (provider.isLoading && cars.isEmpty)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: AmSpinner(size: 28)))
                else if (cars.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No vehicles in your garage yet.', style: TextStyle(color: AppColors.textFaint))),
                  )
                else
                  ValueListenableBuilder<String?>(
                    valueListenable: activeCarId,
                    builder: (context, _, _) {
                      final activeId = resolveActiveCar(cars)?.id;
                      return Column(
                        children: [
                          for (var i = 0; i < cars.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Rise(
                                delayMs: i * 80,
                                child: _GarageCard(car: cars[i], provider: provider, isActive: cars[i].id == activeId),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                DashedAddTile(
                  icon: PhosphorIconsRegular.plusCircle,
                  title: cars.isEmpty ? 'Add your first vehicle' : 'Add another vehicle',
                  subtitle: 'Expenses and reminders for every car',
                  onTap: () => Navigator.pushNamed(context, '/add-vehicle'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GarageCard extends StatelessWidget {
  final Car car;
  final CarProvider provider;
  final bool isActive;
  const _GarageCard({required this.car, required this.provider, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final summary = provider.getSummary(car.id);
    final status = summaryStatus(summary);
    final health = healthScore(summary);
    final reminders = sortedReminders(provider.getReminders(car.id), car);
    final next = reminders.isNotEmpty ? reminders.first : null;
    final glow = status == MStatus.ok || status == MStatus.soon ? AppColors.accent : status.color;
    final tagText = summary == null ? 'Calculating…' : (summary.isGood ? 'Active' : 'Service Due');

    return Pressable(
      onTap: () {
        activeCarId.value = car.id;
        Navigator.pushNamed(context, '/vehicle-details', arguments: car.id);
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.accent700 : AppColors.neutral800),
          boxShadow: isActive ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.14), blurRadius: 30)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 1.2),
                  radius: 0.9,
                  colors: [glow.withValues(alpha: 0.42), glow.withValues(alpha: 0)],
                  stops: const [0, 0.7],
                ),
              ),
              foregroundDecoration: const BoxDecoration(),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99292B31), Color(0x00232532)]),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(PhosphorIconsRegular.carProfile, size: 84, color: AppColors.textSecondary, shadows: [Shadow(color: Color(0x80000000), blurRadius: 16, offset: Offset(0, 8))]),
                  ),
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: AmTag(tagText, background: status == MStatus.ok ? AppColors.accentDeep : status.tint, foreground: status == MStatus.ok ? AppColors.accent100 : status.color),
                  ),
                  if (isActive)
                    const PositionedDirectional(
                      top: 12,
                      end: 12,
                      child: Row(
                        children: [
                          Icon(PhosphorIconsFill.checkCircle, size: 15, color: AppColors.accent),
                          SizedBox(width: 4),
                          Text('Selected', style: TextStyle(fontSize: 11, color: AppColors.accent300)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${car.make} ${car.model}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.text)),
                  Text('${car.year} · Plate: Not Assigned', style: AmText.sub),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _stat('Odometer', Text('${kmFormat.format(car.currentMileage)} km'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _stat(
                          'Health',
                          Row(
                            children: [
                              Text('$health'),
                              const SizedBox(width: 6),
                              Expanded(child: GlowBar(value: health / 100, height: 4, glow: false)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _stat(
                          'Next service',
                          Text(next?.leftLabel ?? (summary?.statusText ?? '—'), style: TextStyle(color: next?.status.color ?? status.color)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        DefaultTextStyle.merge(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.text, fontFeatures: tabular),
          child: value,
        ),
      ],
    );
  }
}
