import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/ui.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Consumer<CarProvider>(
            builder: (context, provider, child) {
              final overdue = <_Notif>[];
              final due = <_Notif>[];

              for (var car in provider.cars) {
                final summary = provider.getSummary(car.id);
                if (summary == null) continue;

                for (var item in summary.overdue) {
                  if (item is Map) {
                    final raw = (item['maintenanceType'] ?? 'Service').toString();
                    final type = raw.replaceAll('_', ' ');
                    overdue.add(_Notif(
                      icon: typeIcon(raw),
                      status: MStatus.overdue,
                      title: 'Overdue: $type',
                      message: 'Your ${car.make} ${car.model} is overdue for $type.',
                      time: 'Action Required',
                    ));
                  }
                }

                for (var item in summary.due) {
                  if (item is Map) {
                    final raw = (item['maintenanceType'] ?? 'Service').toString();
                    final type = raw.replaceAll('_', ' ');
                    due.add(_Notif(
                      icon: typeIcon(raw),
                      status: MStatus.due,
                      title: 'Maintenance Due: $type',
                      message: 'Your ${car.make} ${car.model} is due for $type.',
                      time: 'Soon',
                    ));
                  }
                }
              }

              final groups = [
                if (overdue.isNotEmpty) ('Action required', overdue),
                if (due.isNotEmpty) ('Coming up', due),
              ];
              var index = 0;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                children: [
                  const ScreenHeader(title: 'Notifications', showBack: true),
                  const SizedBox(height: 12),
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Rise(
                        child: Column(
                          children: [
                            const IconTile(icon: PhosphorIconsRegular.bellSimple, size: 64, radius: 20, color: AppColors.textFaint, background: AppColors.surface, edge: AppColors.neutral800),
                            const SizedBox(height: 16),
                            const Text('No new notifications', style: TextStyle(color: AppColors.text, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("We'll let you know when something needs attention.", textAlign: TextAlign.center, style: AmText.sub),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final g in groups) ...[
                      Padding(padding: const EdgeInsets.only(top: 8, bottom: 12), child: SectionLabel(g.$1)),
                      for (final n in g.$2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Rise(delayMs: (index++).clamp(0, 8) * 50, child: _buildNotificationItem(n)),
                        ),
                    ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(_Notif n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neutral800),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon: n.icon, color: n.status.color, background: n.status.tint, edge: n.status.edge),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(n.title, style: const TextStyle(fontSize: 14.5, color: AppColors.text))),
                        const SizedBox(width: 8),
                        Text(n.time, style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(n.message, style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          // Unread dot
          PositionedDirectional(
            top: 4,
            start: -8,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle, boxShadow: AppColors.glow(0.9, 6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notif {
  final IconData icon;
  final MStatus status;
  final String title;
  final String message;
  final String time;
  _Notif({required this.icon, required this.status, required this.title, required this.message, required this.time});
}
