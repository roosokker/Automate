import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: Consumer<CarProvider>(
        builder: (context, provider, child) {
          final List<Widget> notifications = [];

          for (var car in provider.cars) {
            final summary = provider.getSummary(car.id);
            if (summary == null) continue;

            for (var item in summary.overdue) {
              if (item is Map) {
                final type = (item['maintenanceType'] ?? 'Service').toString().replaceAll('_', ' ');
                notifications.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNotificationItem(
                      icon: Icons.error_outline,
                      iconColor: AppColors.danger,
                      title: 'Overdue: $type',
                      message: 'Your ${car.make} ${car.model} is overdue for $type.',
                      time: 'Action Required',
                      isUnread: true,
                    ),
                  ),
                );
              }
            }

            for (var item in summary.due) {
              if (item is Map) {
                final type = (item['maintenanceType'] ?? 'Service').toString().replaceAll('_', ' ');
                notifications.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNotificationItem(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.warn,
                      title: 'Maintenance Due: $type',
                      message: 'Your ${car.make} ${car.model} is due for $type.',
                      time: 'Soon',
                      isUnread: true,
                    ),
                  ),
                );
              }
            }
          }

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.neutral600),
                  SizedBox(height: 16),
                  Text(
                    'No new notifications',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: notifications,
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.surfaceHigh : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUnread ? AppColors.line : AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text)),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textFaint)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (isUnread) ...[
            const SizedBox(width: 12),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}
