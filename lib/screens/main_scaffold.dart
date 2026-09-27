import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../providers/specialist_provider.dart';
import 'dashboard_screen.dart';
import 'my_garage_screen.dart';
import 'specialists_list_screen.dart';
import 'expenses_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/odometer_sheet.dart';
import '../widgets/ui.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  @override
  void initState() {
    super.initState();
    mainTab.value = 0;
    // Fetch user's cars on login / app launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final carProvider = Provider.of<CarProvider>(context, listen: false);
      carProvider.fetchCars().then((_) {
        carProvider.fetchAllRecords();
      });
      Provider.of<SpecialistProvider>(context, listen: false).fetchServiceCenters();
    });
  }

  final List<Widget> _pages = [
    const DashboardScreen(), // Home
    const MyGarageScreen(), // Garage
    const SpecialistsListScreen(), // Service centers
    const ExpensesScreen(), // Spending
  ];

  static const _tabs = [
    (PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Home'),
    (PhosphorIconsRegular.garage, PhosphorIconsFill.garage, 'Garage'),
    null, // quick-add button
    (PhosphorIconsRegular.mapPin, PhosphorIconsFill.mapPin, 'Centers'),
    (PhosphorIconsRegular.wallet, PhosphorIconsFill.wallet, 'Spending'),
  ];

  void _openQuickAdd() {
    final provider = Provider.of<CarProvider>(context, listen: false);
    final car = resolveActiveCar(provider.cars);
    final items = [
      (PhosphorIconsRegular.receipt, 'Add expense', 'Service, parts, repairs…', () {
        Navigator.pop(context);
        if (car == null) {
          Navigator.pushNamed(context, '/add-vehicle');
        } else {
          Navigator.pushNamed(context, '/add-record', arguments: car.id);
        }
      }),
      (PhosphorIconsRegular.gauge, 'Update km', 'Keep reminders accurate', () {
        Navigator.pop(context);
        if (car == null) {
          Navigator.pushNamed(context, '/add-vehicle');
        } else {
          showOdometerSheet(context, car);
        }
      }),
      (PhosphorIconsRegular.mapPin, 'Centers', 'Find a service center', () {
        Navigator.pop(context);
        mainTab.value = 2;
      }),
      (PhosphorIconsRegular.carProfile, 'Add a vehicle', 'Track another car', () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/add-vehicle');
      }),
    ];
    showAmSheet(
      context,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Quick add', style: AmText.h4),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              for (var i = 0; i < items.length; i++)
                Rise(
                  delayMs: i * 50,
                  durationMs: 400,
                  child: Pressable(
                    scale: 0.96,
                    onTap: items[i].$4,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.neutral900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutral800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconTile(icon: items[i].$1, size: 42, radius: 13, edge: AppColors.accentDeep),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(items[i].$2, style: const TextStyle(fontSize: 14.5, color: AppColors.text)),
                              Text(items[i].$3, style: AmText.sub, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: mainTab,
      builder: (context, current, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(current), child: _pages[current]),
          ),
          bottomNavigationBar: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.bg.withValues(alpha: 0.78)),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FadingRule(),
                          SizedBox(
                            height: 66,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: List.generate(_tabs.length, (i) {
                                final tab = _tabs[i];
                                if (tab == null) return const SizedBox(width: 58);
                                final page = i > 2 ? i - 1 : i;
                                return _TabItem(
                                  icon: tab.$1,
                                  activeIcon: tab.$2,
                                  label: tab.$3,
                                  selected: page == current,
                                  onTap: () => mainTab.value = page,
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Raised quick-add button, drawn outside the blurred bar so it isn't clipped.
              Positioned(
                top: -10,
                left: 0,
                right: 0,
                child: Center(child: _QuickAddButton(onTap: _openQuickAdd)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textFaint;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      highlightColor: Colors.transparent,
      splashColor: AppColors.accent.withValues(alpha: 0.12),
      child: SizedBox(
        width: 62,
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Accent mark — a short solid line with glow.
            Positioned(
              top: 0,
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: AppColors.glow(0.9, 10),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: selected ? 1.06 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(selected ? activeIcon : icon, size: 23, color: color),
                ),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 10.5, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _QuickAddButton({required this.onTap});

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: RepaintBoundary(
        child: AnimatedRotation(
          turns: _down ? 0.25 : 0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedScale(
            scale: _down ? 0.9 : 1,
            duration: const Duration(milliseconds: 200),
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
          ),
        ),
      ),
    );
  }
}
