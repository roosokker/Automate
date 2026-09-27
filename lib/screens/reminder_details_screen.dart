import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/phosphor_icons.dart';
import '../models/reminder.dart';
import '../providers/car_provider.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/ui.dart';

class ReminderDetailsScreen extends StatelessWidget {
  const ReminderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final reminder = args['reminder'] as Reminder;
    final carId = args['carId'] as String;
    final car = Provider.of<CarProvider>(context, listen: false).getCar(carId);

    final numberFormat = NumberFormat('#,##0');
    final view = ReminderView(reminder, car);
    final status = view.status;

    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
              const ScreenHeader(title: 'Reminder Details', showBack: true),
              const SizedBox(height: 16),
              Rise(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [status.tint, AppColors.surface], stops: const [0, 0.7]),
                    border: Border.all(color: status.edge),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconTile(icon: view.icon, size: 52, radius: 16, color: status.color, background: status.tint),
                          const Spacer(),
                          AmTag(reminder.status, background: status.tint, foreground: status.color),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(view.name, style: AmText.h3),
                      const SizedBox(height: 4),
                      Text(
                        view.kmLeft != null ? (view.kmLeft! < 0 ? view.leftLabel : '${view.leftLabel} left') : view.dueAt,
                        style: TextStyle(fontSize: 14, color: status.color, fontFeatures: tabular),
                      ),
                      const SizedBox(height: 14),
                      GlowBar(value: view.progress, color: status.color),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SectionLabel('Details'),
              const SizedBox(height: 10),
              Rise(
                delayMs: 80,
                child: AmCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        icon: PhosphorIconsRegular.carProfile,
                        label: 'Vehicle',
                        value: car != null ? '${car.make} ${car.model}' : 'Unknown',
                        last: reminder.dueMileage == null && reminder.dueDate == null,
                      ),
                      if (reminder.dueMileage != null)
                        _buildDetailRow(
                          icon: PhosphorIconsRegular.gauge,
                          label: 'Due Mileage',
                          value: '${numberFormat.format(reminder.dueMileage)} km',
                          last: reminder.dueDate == null,
                        ),
                      if (reminder.dueDate != null)
                        _buildDetailRow(
                          icon: PhosphorIconsRegular.calendarBlank,
                          label: 'Due Date',
                          value: reminder.dueDate!,
                          last: true,
                        ),
                      if (reminder.dueMileage == null && reminder.dueDate == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('No specific due date or mileage recorded.', style: TextStyle(color: AppColors.textMuted)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Rise(
                delayMs: 160,
                child: Column(
                  children: [
                    AmButton(
                      label: 'Log Maintenance',
                      icon: PhosphorIconsRegular.check,
                      glow: true,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/add-record',
                          arguments: carId, // Pre-select the car
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    AmButton.secondary(
                      label: 'Remind Me Later',
                      icon: PhosphorIconsRegular.clockCounterClockwise,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value, bool last = false}) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 18),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
              const Spacer(),
              Text(value, style: const TextStyle(color: AppColors.text, fontSize: 14, fontFeatures: tabular)),
            ],
          ),
        ),
        if (!last) const FadingRule(),
      ],
    );
  }
}
