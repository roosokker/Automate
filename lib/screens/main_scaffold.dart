import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../providers/specialist_provider.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'my_garage_screen.dart';
import 'specialists_list_screen.dart';
import 'expenses_screen.dart';
import 'profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
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
    const DashboardScreen(), // Services (Fleet Dashboard)
    const MyGarageScreen(),  // Garage
    const SpecialistsListScreen(), // Records / Specialists placeholder
    const ExpensesScreen(), // Expenses
    const ProfileScreen(), // Profile
  ];

  static const _items = [
    (Icons.home_repair_service_outlined, Icons.home_repair_service, 'Services'),
    (Icons.directions_car_outlined, Icons.directions_car, 'Garage'),
    (Icons.store_outlined, Icons.store, 'Workshops'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Expenses'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
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
        child: KeyedSubtree(key: ValueKey(_currentIndex), child: _pages[_currentIndex]),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(color: AppColors.bg.withValues(alpha: 0.82)),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 1, decoration: const BoxDecoration(gradient: AppColors.fadingRule)),
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: List.generate(_items.length, (index) {
                        final item = _items[index];
                        final selected = index == _currentIndex;
                        return Expanded(
                          child: InkResponse(
                            onTap: () => setState(() => _currentIndex = index),
                            radius: 36,
                            highlightColor: Colors.transparent,
                            splashColor: AppColors.accent.withValues(alpha: 0.12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Accent mark — a short solid line with glow.
                                Positioned(
                                  top: 0,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutCubic,
                                    width: selected ? 20 : 0,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: selected ? AppColors.glow(0.8, 10) : null,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedScale(
                                      scale: selected ? 1.08 : 1,
                                      duration: const Duration(milliseconds: 220),
                                      child: Icon(
                                        selected ? item.$2 : item.$1,
                                        size: 24,
                                        color: selected ? AppColors.accent : AppColors.textFaint,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 220),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                                        color: selected ? AppColors.accent : AppColors.textFaint,
                                      ),
                                      child: Text(item.$3),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
