import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/phosphor_icons.dart';
import '../models/maintenance_record.dart';
import '../theme/app_colors.dart';
import 'maintenance_ui.dart';
import 'ui.dart';

void showRecordDetailsModal(BuildContext context, MaintenanceRecord record) {
  final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal());
  final numberFormat = NumberFormat('#,##0');

  showAmSheet(
    context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: typeIcon(record.maintenanceType), size: 42, radius: 13, edge: AppColors.accentDeep),
              const SizedBox(width: 12),
              Expanded(child: Text(typeLabel(record.maintenanceType), style: AmText.h4)),
              AmIconButton(icon: PhosphorIconsRegular.x, size: 36, radius: 12, onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('EGP', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Text(record.cost.toStringAsFixed(2), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w500, letterSpacing: -1.4, color: AppColors.text, fontFeatures: tabular)),
            ],
          ),
          const SizedBox(height: 14),
          AmCard(
            color: AppColors.neutral900,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                _buildDetailRow(PhosphorIconsRegular.calendarBlank, 'Date', formattedDate),
                _buildDetailRow(PhosphorIconsRegular.gauge, 'Mileage', '${numberFormat.format(record.mileageAtService)} km'),
                _buildDetailRow(PhosphorIconsRegular.coins, 'Cost', 'EGP ${record.cost.toStringAsFixed(2)}'),
                _buildDetailRow(PhosphorIconsRegular.storefront, 'Service Center', record.serviceCenterId ?? 'Verified Workshop', last: true),
              ],
            ),
          ),
          if (record.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionLabel('Notes'),
            const SizedBox(height: 6),
            Text(record.description, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
        ],
      );
    },
  );
}

Widget _buildDetailRow(IconData icon, String label, String value, {bool last = false}) {
  return Column(
    children: [
      SizedBox(
        height: 48,
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text, fontSize: 14, fontFeatures: tabular)),
            ),
          ],
        ),
      ),
      if (!last) const FadingRule(),
    ],
  );
}

void showScheduledServiceModal(BuildContext context, String title, String dueInfo) {
  showAmSheet(
    context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle(title),
          const SizedBox(height: 16),
          const SectionLabel('Status'),
          const SizedBox(height: 6),
          Text(dueInfo, style: const TextStyle(fontSize: 14, color: AppColors.text)),
          const SizedBox(height: 16),
          const SectionLabel('Description'),
          const SizedBox(height: 6),
          const Text('A comprehensive check and replacement of critical engine components as per manufacturer specifications.', style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          AmButton(
            label: 'BOOK NOW',
            icon: PhosphorIconsRegular.calendarCheck,
            height: 50,
            fontSize: 15,
            glow: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}
