import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import '../models/service_center.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

class ServiceCenterDetailsScreen extends StatelessWidget {
  final ServiceCenter serviceCenter;

  const ServiceCenterDetailsScreen({super.key, required this.serviceCenter});

  @override
  Widget build(BuildContext context) {
    final bool isVerified = serviceCenter.type == 'AUTHORIZED';

    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
              const ScreenHeader(title: 'Service center', showBack: true),
              const SizedBox(height: 16),
              Rise(child: _hero(isVerified)),
              const SizedBox(height: 22),
              const SectionLabel('Location'),
              const SizedBox(height: 10),
              Rise(
                delayMs: 80,
                child: AmCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const IconTile(icon: PhosphorIconsRegular.mapPin),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(serviceCenter.city, style: const TextStyle(fontSize: 15, color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text(
                              '${serviceCenter.address}, ${serviceCenter.city}',
                              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (serviceCenter.phone != null) ...[
                const SizedBox(height: 22),
                const SectionLabel('Contact'),
                const SizedBox(height: 10),
                Rise(
                  delayMs: 140,
                  child: AmCard(
                    child: Row(
                      children: [
                        const IconTile(icon: PhosphorIconsRegular.phone),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            serviceCenter.phone!,
                            style: const TextStyle(fontSize: 15, color: AppColors.text, fontFeatures: tabular),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              border: const Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: AmButton(
                  label: 'Book Appointment',
                  icon: PhosphorIconsRegular.calendarCheck,
                  height: 50,
                  fontSize: 15,
                  glow: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(bool isVerified) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accentTint, AppColors.surface], stops: [0, 0.7]),
        border: Border.all(color: AppColors.accentDeep),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const PositionedDirectional(top: -56, end: -46, child: _Orb()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmTag(
                isVerified ? 'Verified specialist' : serviceCenter.type.replaceAll('_', ' '),
                icon: isVerified ? PhosphorIconsFill.sealCheck : PhosphorIconsRegular.wrench,
                background: isVerified ? AppColors.accentDeep : AppColors.neutral800,
                foreground: isVerified ? AppColors.accent100 : AppColors.neutral200,
              ),
              const SizedBox(height: 10),
              Text(serviceCenter.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: -0.4, color: AppColors.text)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _meta(PhosphorIconsFill.star, '4.8 (120 reviews)', AppColors.warn),
                  _meta(PhosphorIconsRegular.navigationArrow, serviceCenter.city, AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Drifting accent glow in the hero corner (amOrb).
class _Orb extends StatefulWidget {
  const _Orb();

  @override
  State<_Orb> createState() => _OrbState();
}

class _OrbState extends State<_Orb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(-30 * t, 20 * t),
          child: Transform.scale(scale: 1 + 0.15 * t, child: child),
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppColors.accent.withValues(alpha: 0.35), AppColors.accent.withValues(alpha: 0)], stops: const [0, 0.7]),
        ),
      ),
    );
  }
}
