import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_colors.dart';

class NotificationBell extends StatelessWidget {
  final Color color;
  final double size;

  const NotificationBell({super.key, this.color = AppColors.text, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarProvider>(
      builder: (context, provider, child) {
        bool hasNotifications = false;

        for (var car in provider.cars) {
          final summary = provider.getSummary(car.id);
          if (summary != null) {
            if (summary.due.isNotEmpty || summary.overdue.isNotEmpty) {
              hasNotifications = true;
              break;
            }
          }
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.line),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(PhosphorIconsRegular.bell, size: 20, color: color),
                  if (hasNotifications)
                    PositionedDirectional(
                      top: 11,
                      end: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg, width: 2),
                          boxShadow: AppColors.glow(0.9, 8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
