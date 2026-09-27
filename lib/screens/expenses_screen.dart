import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../providers/car_provider.dart';
import '../widgets/record_details_modal.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/ui.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _selBar = 5;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00');

    return AmBackground(
      child: SafeArea(
        bottom: false,
        child: Consumer<CarProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.cars.isEmpty) {
              return const Center(child: AmSpinner(size: 28));
            }

            final allExpenses = provider.allExpenses;
            final totalExpenses = allExpenses.fold<double>(0, (sum, record) => sum + record.cost);
            final now = DateTime.now();
            final months = List.generate(6, (i) => DateTime(now.year, now.month - 5 + i));
            final monthTotals = months.map((m) => _monthTotal(allExpenses, m)).toList();

            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await provider.fetchCars();
                await provider.fetchAllRecords();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                children: [
                  ScreenHeader(
                    title: 'Spending',
                    subtitle: 'All vehicles · ${DateFormat('MMMM yyyy').format(now)}',
                    actions: [
                      AmButton(
                        label: 'Add',
                        icon: PhosphorIconsRegular.plus,
                        expand: false,
                        height: 44,
                        fontSize: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        onPressed: () {
                          final car = resolveActiveCar(provider.cars);
                          if (car == null) {
                            Navigator.pushNamed(context, '/add-vehicle');
                          } else {
                            Navigator.pushNamed(context, '/add-record', arguments: car.id);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Rise(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total spent', style: AmText.sub),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('EGP', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: CountUp(
                                  value: totalExpenses,
                                  format: (v) => numberFormat.format(v),
                                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w500, letterSpacing: -1.9, height: 1.05, color: AppColors.text),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _deltaTag(monthTotals[5], monthTotals[4]),
                      ],
                    ),
                  ),
                  if (allExpenses.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Rise(delayMs: 60, child: _DonutCard(records: allExpenses)),
                    const SizedBox(height: 14),
                    Rise(delayMs: 120, child: _trendCard(months, monthTotals)),
                    const SizedBox(height: 14),
                    Rise(
                      delayMs: 180,
                      child: Row(
                        children: [
                          Expanded(
                            child: _miniStat(
                              PhosphorIconsRegular.receipt,
                              'Records',
                              '${allExpenses.length}',
                              '',
                              '${provider.cars.length} ${provider.cars.length == 1 ? 'vehicle' : 'vehicles'}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _miniStat(
                              PhosphorIconsRegular.coins,
                              'Avg. per record',
                              moneyFormat.format(totalExpenses / allExpenses.length),
                              'EGP',
                              'Across all services',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const SectionLabel('Expense History'),
                  const SizedBox(height: 4),
                  if (allExpenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No expenses recorded yet across your fleet.',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...allExpenses.asMap().entries.map((entry) {
                      final record = entry.value;
                      final car = record.carId != null ? provider.getCar(record.carId!) : null;
                      final carName = car != null ? '${car.make} ${car.model}' : 'Unknown Vehicle';
                      final date = DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal());

                      return Rise(
                        delayMs: math.min(entry.key, 8) * 40,
                        durationMs: 400,
                        child: _TxnRow(
                          icon: typeIcon(record.maintenanceType),
                          title: typeLabel(record.maintenanceType),
                          subtitle: '$carName · $date',
                          amount: 'EGP ${numberFormat.format(record.cost)}',
                          onTap: () => showRecordDetailsModal(context, record),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _monthTotal(List<MaintenanceRecord> records, DateTime m) {
    return records.where((r) {
      final d = DateTime.tryParse(r.date)?.toLocal();
      return d != null && d.year == m.year && d.month == m.month;
    }).fold(0.0, (s, r) => s + r.cost);
  }

  Widget _deltaTag(double thisMonth, double lastMonth) {
    if (lastMonth <= 0) {
      return AmTag('EGP ${moneyFormat.format(thisMonth)} this month', icon: PhosphorIconsRegular.calendarBlank);
    }
    final p = ((thisMonth - lastMonth) / lastMonth * 100).round();
    return AmTag(
      '${p.abs()}% vs last month',
      icon: p <= 0 ? PhosphorIconsRegular.trendDown : PhosphorIconsRegular.trendUp,
    );
  }

  Widget _trendCard(List<DateTime> months, List<double> totals) {
    final maxV = totals.fold<double>(0, math.max);
    final sel = _selBar.clamp(0, 5);
    return AmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('Monthly trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.text)),
              Text(
                '${DateFormat('MMM').format(months[sel])} · EGP ${moneyFormat.format(totals[sel])}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFeatures: tabular),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (i) {
                final selected = i == sel;
                final h = maxV <= 0 ? 6.0 : math.max(6.0, totals[i] / maxV * 96);
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selBar = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: h),
                            duration: Duration(milliseconds: 1000 + i * 60),
                            curve: const Cubic(0.2, 0.8, 0.2, 1),
                            builder: (context, v, _) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: v,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                color: selected ? AppColors.accent : AppColors.neutral800,
                                boxShadow: selected ? AppColors.glow(0.7, 14) : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('MMM').format(months[i]),
                            style: TextStyle(fontSize: 10.5, color: selected ? AppColors.accent300 : AppColors.textFaint),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value, String unit, String footer) {
    return AmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.accent),
              const SizedBox(width: 5),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted))),
            ],
          ),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: value),
              if (unit.isNotEmpty) TextSpan(text: ' $unit', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, letterSpacing: 0)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, letterSpacing: -0.5, color: AppColors.text, fontFeatures: tabular),
          ),
          const SizedBox(height: 3),
          Text(footer, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.accent300)),
        ],
      ),
    );
  }
}

/// Spending by maintenance type as a donut with a legend.
class _DonutCard extends StatelessWidget {
  final List<MaintenanceRecord> records;
  const _DonutCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final byType = <String, double>{};
    for (final r in records) {
      byType[r.maintenanceType] = (byType[r.maintenanceType] ?? 0) + r.cost;
    }
    final entries = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final slices = <(String, double)>[];
    for (var i = 0; i < entries.length; i++) {
      if (i < 5) {
        slices.add((typeLabel(entries[i].key), entries[i].value));
      } else if (slices.length == 5) {
        slices.add(('Other', entries[i].value));
      } else {
        slices[5] = ('Other', slices[5].$2 + entries[i].value);
      }
    }
    final total = slices.fold<double>(0, (s, e) => s + e.$2);

    return AmCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1200),
                  curve: const Cubic(0.2, 0.8, 0.2, 1),
                  builder: (context, t, _) => CustomPaint(
                    size: const Size(132, 132),
                    painter: _DonutPainter(values: slices.map((s) => total == 0 ? 0.0 : s.$2 / total).toList(), progress: t),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Categories', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Text('${byType.length}', style: const TextStyle(fontSize: 18, color: AppColors.text, fontFeatures: tabular)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < slices.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: categoryColors[i], borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(slices[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
                        Text(
                          '${total == 0 ? 0 : (slices[i].$2 / total * 100).round()}%',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.text, fontFeatures: tabular),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final double progress;
  _DonutPainter({required this.values, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: 54);
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
      ..color = AppColors.neutral800
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] * progress;
      if (sweep <= 0) continue;
      canvas.drawArc(rect, start, math.max(0, sweep - 0.03), false, Paint()
        ..color = categoryColors[i % categoryColors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress || old.values != values;
}

/// Expense list row with a fading bottom rule.
class _TxnRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onTap;
  const _TxnRow({required this.icon, required this.title, required this.subtitle, required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                IconTile(icon: icon, size: 40, color: AppColors.accent300, background: AppColors.surface, edge: AppColors.neutral800),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColors.text)),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AmText.sub),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(amount, style: const TextStyle(fontSize: 14, color: AppColors.text, fontFeatures: tabular)),
              ],
            ),
          ),
          const FadingRule(),
        ],
      ),
    );
  }
}
