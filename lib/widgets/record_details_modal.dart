import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/maintenance_record.dart';
import '../theme/app_colors.dart';

void showRecordDetailsModal(BuildContext context, MaintenanceRecord record) {
  final formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(record.date).toLocal());
  final numberFormat = NumberFormat('#,##0');
  
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(record.maintenanceType.replaceAll('_', ' '), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.text)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Date', formattedDate),
            _buildDetailRow('Mileage', '${numberFormat.format(record.mileageAtService)} km'),
            _buildDetailRow('Cost', 'EGP ${record.cost.toStringAsFixed(2)}'),
            _buildDetailRow('Service Center', record.serviceCenterId ?? 'Verified Workshop'),
            if (record.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(record.description, style: const TextStyle(fontSize: 14, color: AppColors.text)),
            ],
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

void showScheduledServiceModal(BuildContext context, String title, String dueInfo) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.text)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(dueInfo, style: const TextStyle(fontSize: 14, color: AppColors.text)),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            const Text('A comprehensive check and replacement of critical engine components as per manufacturer specifications.', style: TextStyle(fontSize: 14, color: AppColors.text)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('BOOK NOW', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
