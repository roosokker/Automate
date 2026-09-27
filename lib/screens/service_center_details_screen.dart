import 'package:flutter/material.dart';
import '../models/service_center.dart';
import '../theme/app_colors.dart';

class ServiceCenterDetailsScreen extends StatelessWidget {
  final ServiceCenter serviceCenter;

  const ServiceCenterDetailsScreen({super.key, required this.serviceCenter});

  @override
  Widget build(BuildContext context) {
    final bool isVerified = serviceCenter.type == 'AUTHORIZED';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(serviceCenter.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1520340356584-f9917d1e5113?ixlib=rb-1.2.1&auto=format&fit=crop&w=1050&q=80'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    serviceCenter.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.text),
                  ),
                ),
                if (isVerified)
                  const Icon(Icons.verified, color: AppColors.accent, size: 28),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(serviceCenter.type.replaceAll('_', ' '), style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.star, color: AppColors.warn, size: 16),
                const SizedBox(width: 4),
                const Text('4.8 (120 reviews)', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.text)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppColors.textFaint, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${serviceCenter.address}, ${serviceCenter.city}',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (serviceCenter.phone != null) ...[
              const Text('Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.text)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.phone, color: AppColors.textFaint, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    serviceCenter.phone!,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDeep,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
        ),
      ),
    );
  }
}
