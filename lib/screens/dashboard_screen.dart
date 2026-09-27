import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../models/maintenance_record.dart';
import '../models/service_center.dart';
import '../providers/car_provider.dart';
import '../providers/specialist_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/notification_bell.dart';
import '../widgets/odometer_sheet.dart';
import '../widgets/ui.dart';
import 'profile_screen.dart';
import 'service_center_details_screen.dart';

/// Home — the health-ring dashboard for the selected car.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static String? _cachedName;
  final Set<String> _remindersRequested = {};

  @override
  void initState() {
    super.initState();
    if (_cachedName == null) {
      AuthService().fetchProfile().then((user) {
        final name = user?['fullName'] as String?;
        if (name != null && mounted) setState(() => _cachedName = name);
      });
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    final part = h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
    final first = _cachedName?.trim().split(RegExp(r'\s+')).first;
    return first == null || first.isEmpty ? part : '$part, $first';
  }

  void _ensureReminders(CarProvider provider, Car car) {
    if (_remindersRequested.add(car.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => provider.fetchReminders(car.id));
    }
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AmBackground(
      child: SafeArea(
        bottom: false,
        child: Consumer<CarProvider>(
          builder: (context, provider, child) {
            return ValueListenableBuilder<String?>(
              valueListenable: activeCarId,
              builder: (context, _, _) {
                final car = resolveActiveCar(provider.cars);
                if (car != null) _ensureReminders(provider, car);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 28),
                  children: [
                    _header(car),
                    const SizedBox(height: 20),
                    if (provider.isLoading && provider.cars.isEmpty)
                      const Padding(padding: EdgeInsets.all(60), child: Center(child: AmSpinner(size: 28)))
                    else if (car == null)
                      _emptyState()
                    else
                      ..._carContent(provider, car),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(Car? car) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Rise(
        offset: 0,
        durationMs: 400,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => mainTab.value = 1,
                child: Row(
                  children: [
                    const CarBadge(),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting, style: AmText.sub, overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  car != null ? '${car.make} ${car.model}' : 'AutoMate',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.3, color: AppColors.text),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(PhosphorIconsRegular.caretDown, size: 13, color: AppColors.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(onTap: _openProfile, child: InitialsAvatar(initials: initialsOf(_cachedName ?? ''), size: 42)),
            const SizedBox(width: 10),
            const NotificationBell(),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Rise(
        child: AmCard(
          radius: 16,
          padding: const EdgeInsets.all(24),
          edge: AppColors.accent700,
          shadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 40)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CarBadge(size: 64),
              const SizedBox(height: 20),
              const Text('No vehicles added yet', style: AmText.h3),
              const SizedBox(height: 8),
              const Text('Add your first car to start tracking maintenance and expenses.', style: AmText.body),
              const SizedBox(height: 22),
              AmButton(
                label: 'Add a Vehicle',
                trailingIcon: PhosphorIconsRegular.arrowRight,
                glow: true,
                onPressed: () => Navigator.pushNamed(context, '/add-vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _carContent(CarProvider provider, Car car) {
    final summary = provider.getSummary(car.id);
    final reminders = sortedReminders(provider.getReminders(car.id), car);
    final top = reminders.isNotEmpty ? reminders.first : null;
    final health = healthScore(summary);
    final records = provider.getRecords(car.id);

    return [
      if (provider.cars.length > 1) ...[
        _carChips(provider),
        const SizedBox(height: 14),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _HealthRing(key: ValueKey('ring-${car.id}'), health: health, label: healthLabel(summary)),
            const SizedBox(height: 12),
            Rise(
              delayMs: 100,
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      kicker: 'Odometer',
                      trailing: const Icon(PhosphorIconsRegular.pencilSimple, size: 15, color: AppColors.accent),
                      value: Text.rich(TextSpan(children: [
                        TextSpan(text: kmFormat.format(car.currentMileage)),
                        const TextSpan(text: ' km', style: TextStyle(fontSize: 13, color: AppColors.textMuted, letterSpacing: 0)),
                      ])),
                      footer: 'Tap to update',
                      onTap: () => showOdometerSheet(context, car),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      kicker: 'Next service',
                      trailing: const Icon(PhosphorIconsRegular.arrowRight, size: 15, color: AppColors.textFaint),
                      value: Text(top?.leftLabel ?? 'All good', style: TextStyle(color: top?.status.color ?? AppColors.text)),
                      footer: top?.name ?? summary?.statusText ?? 'Nothing scheduled',
                      onTap: () => Navigator.pushNamed(context, '/vehicle-details', arguments: car.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (top != null && (top.status == MStatus.overdue || top.status == MStatus.due)) ...[
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _AttentionCard(car: car, item: top)),
      ],
      const SizedBox(height: 20),
      _quickActions(car),
      const SizedBox(height: 20),
      _centersStrip(),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _SpendMini(records: records)),
    ];
  }

  Widget _carChips(CarProvider provider) {
    final activeId = resolveActiveCar(provider.cars)?.id;
    return Rise(
      offset: 0,
      delayMs: 50,
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: provider.cars.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final c = provider.cars[i];
            final st = summaryStatus(provider.getSummary(c.id));
            final dot = st == MStatus.ok ? AppColors.accent : st.color;
            return AmChoice(
              label: '${c.make} ${c.model}',
              selected: c.id == activeId,
              height: 34,
              radius: 17,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              leading: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot, boxShadow: [BoxShadow(color: dot, blurRadius: 6)]),
              ),
              onTap: () => activeCarId.value = c.id,
            );
          },
        ),
      ),
    );
  }

  Widget _quickActions(Car car) {
    final actions = [
      (PhosphorIconsRegular.receipt, 'Add expense', () => Navigator.pushNamed(context, '/add-record', arguments: car.id)),
      (PhosphorIconsRegular.gauge, 'Update km', () => showOdometerSheet(context, car)),
      (PhosphorIconsRegular.mapPin, 'Centers', () => mainTab.value = 2),
      (PhosphorIconsRegular.listChecks, 'Service plan', () => Navigator.pushNamed(context, '/vehicle-details', arguments: car.id)),
    ];
    return Rise(
      delayMs: 160,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: actions
              .map((a) => Expanded(
                    child: Pressable(
                      scale: 0.92,
                      onTap: a.$3,
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              gradient: const LinearGradient(begin: Alignment(-0.3, -1), end: Alignment(0.3, 1), colors: [AppColors.surface, AppColors.neutral900]),
                              border: Border.all(color: AppColors.neutral800),
                            ),
                            child: Icon(a.$1, size: 24, color: AppColors.accent300),
                          ),
                          const SizedBox(height: 8),
                          Text(a.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, height: 1.2, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _centersStrip() {
    return Consumer<SpecialistProvider>(
      builder: (context, sp, _) {
        final centers = sp.serviceCenters.take(6).toList();
        return Rise(
          delayMs: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionLabel('Service centers near you', trailing: AmLink('See all', fontSize: 12.5, onTap: () => mainTab.value = 2)),
              ),
              const SizedBox(height: 10),
              if (sp.isLoading && centers.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Center(child: AmSpinner()))
              else if (centers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('No service centers found nearby.', style: TextStyle(color: AppColors.textFaint, fontSize: 13)),
                )
              else
                SizedBox(
                  height: 66,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: centers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _CenterMini(center: centers[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HealthRing extends StatelessWidget {
  final int health;
  final String label;
  const _HealthRing({super.key, required this.health, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _Breathing(
            child: SizedBox(
              width: 230,
              height: 230,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x429184D9), Color(0x009184D9)], stops: [0, 0.66]),
                ),
              ),
            ),
          ),
          SizedBox(width: 244, height: 244, child: CustomPaint(painter: _DottedCirclePainter())),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: health / 100),
            duration: const Duration(milliseconds: 1500),
            curve: const Cubic(0.2, 0.8, 0.2, 1),
            builder: (context, v, _) => SizedBox(
              width: 214,
              height: 214,
              child: CustomPaint(painter: RingPainter(progress: v, color: AppColors.accent)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionLabel('Health'),
              const SizedBox(height: 4),
              CountUp(
                value: health,
                durationMs: 1500,
                format: (v) => v.round().toString(),
                style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w500, letterSpacing: -3.5, height: 1, color: AppColors.text),
              ),
              const SizedBox(height: 6),
              AmTag(label),
            ],
          ),
        ],
      ),
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 114.0;
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const circumference = 2 * math.pi * r;
    const steps = circumference / 9;
    for (var i = 0; i < steps; i++) {
      final a = i * 9 / r;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, 2 / r, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slow opacity pulse (amGlow).
class _Breathing extends StatefulWidget {
  final Widget child;
  const _Breathing({required this.child});

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1750))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: Tween(begin: 0.55, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)), child: widget.child);
  }
}

class _StatCard extends StatelessWidget {
  final String kicker;
  final Widget trailing;
  final Widget value;
  final String footer;
  final VoidCallback onTap;
  const _StatCard({required this.kicker, required this.trailing, required this.value, required this.footer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AmCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(kicker.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.textMuted)),
              trailing,
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: DefaultTextStyle.merge(
              maxLines: 1,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.4, color: AppColors.text, fontFeatures: tabular),
              child: value,
            ),
          ),
          const SizedBox(height: 3),
          Text(footer, maxLines: 1, overflow: TextOverflow.ellipsis, style: AmText.sub),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final Car car;
  final ReminderView item;
  const _AttentionCard({required this.car, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.status.color;
    return Rise(
      delayMs: 120,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [item.status.tint, AppColors.surface], stops: const [0, 0.7]),
          border: Border.all(color: item.status.edge),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: item.status.tint, borderRadius: BorderRadius.circular(13)),
                  child: _RingingBell(color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 15, color: AppColors.text)),
                      Text('${item.leftLabel} · ${item.dueAt}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                AmTag(item.status.label, background: item.status.tint, foreground: color),
              ],
            ),
            const SizedBox(height: 12),
            GlowBar(value: item.progress, color: color),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AmButton.secondary(
                    label: 'Mark done',
                    height: 40,
                    icon: PhosphorIconsRegular.check,
                    onPressed: () => Navigator.pushNamed(context, '/add-record', arguments: car.id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AmButton(
                    label: 'Find center',
                    icon: PhosphorIconsRegular.mapPin,
                    height: 40,
                    fontSize: 14,
                    radius: 8,
                    onPressed: () => mainTab.value = 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingingBell extends StatefulWidget {
  final Color color;
  const _RingingBell({required this.color});

  @override
  State<_RingingBell> createState() => _RingingBellState();
}

class _RingingBellState extends State<_RingingBell> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // Shake for the first 60% of the cycle, rest after.
        final angle = t < 0.6 ? math.sin(t / 0.6 * math.pi * 5) * 0.24 * (1 - t / 0.6) : 0.0;
        return Transform.rotate(angle: angle, alignment: const Alignment(0, -0.8), child: child);
      },
      child: Icon(PhosphorIconsFill.bellRinging, size: 20, color: widget.color),
    );
  }
}

class _CenterMini extends StatelessWidget {
  final ServiceCenter center;
  const _CenterMini({required this.center});

  @override
  Widget build(BuildContext context) {
    final authorized = center.type == 'AUTHORIZED';
    return AmCard(
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceCenterDetailsScreen(serviceCenter: center))),
      child: SizedBox(
        width: 180,
        child: Row(
          children: [
            IconTile(
              icon: authorized ? PhosphorIconsFill.sealCheck : PhosphorIconsRegular.wrench,
              size: 40,
              color: authorized ? AppColors.accent : AppColors.neutral200,
              background: authorized ? AppColors.accentTint : AppColors.neutral900,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(center.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.text)),
                  Text(center.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.accent300)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "This month" spend card with the last six months as bars.
class _SpendMini extends StatelessWidget {
  final List<MaintenanceRecord> records;
  const _SpendMini({required this.records});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
    double totalFor(DateTime m) => records.where((r) {
          final d = DateTime.tryParse(r.date)?.toLocal();
          return d != null && d.year == m.year && d.month == m.month;
        }).fold(0.0, (s, r) => s + r.cost);
    final totals = months.map(totalFor).toList();
    final thisMonth = totals.last;
    final lastMonth = totals[4];
    final maxV = totals.fold<double>(0, math.max);
    String delta;
    IconData deltaIcon;
    if (lastMonth > 0) {
      final p = ((thisMonth - lastMonth) / lastMonth * 100).round();
      delta = '${p.abs()}% vs last month';
      deltaIcon = p <= 0 ? PhosphorIconsRegular.trendDown : PhosphorIconsRegular.trendUp;
    } else {
      delta = '${records.length} records logged';
      deltaIcon = PhosphorIconsRegular.receipt;
    }

    return Rise(
      delayMs: 220,
      child: AmCard(
        padding: const EdgeInsets.all(16),
        onTap: () => mainTab.value = 3,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('THIS MONTH', style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.accent)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('EGP', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(width: 6),
                      CountUp(
                        value: thisMonth,
                        format: (v) => moneyFormat.format(v),
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.75, color: AppColors.text),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(deltaIcon, size: 13, color: AppColors.accent300),
                      const SizedBox(width: 5),
                      Flexible(child: Text(delta, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.accent300))),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 60,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (i) {
                  final isLast = i == 5;
                  final h = maxV <= 0 ? 6.0 : math.max(6.0, totals[i] / maxV * 60);
                  return Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: h),
                      duration: Duration(milliseconds: 900 + i * 60),
                      curve: const Cubic(0.2, 0.8, 0.2, 1),
                      builder: (context, v, _) => Container(
                        width: 10,
                        height: v,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isLast ? AppColors.accent : AppColors.neutral800,
                          boxShadow: isLast ? AppColors.glow(0.8, 10) : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
