import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_colors.dart';

class NotificationBell extends StatelessWidget {
  final Color color;

  const NotificationBell({super.key, this.color = AppColors.text});

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

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: color),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            if (hasNotifications)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
