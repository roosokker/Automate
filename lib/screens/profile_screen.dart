import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import '../services/auth_service.dart';
import 'placeholder_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: AuthService().fetchProfile(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final fullName = user?['fullName'] ?? (snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : 'AutoMate Member');
              final phone = user?['phone'] ?? 'Manage your account';

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                children: [
                  ScreenHeader(title: 'Profile', showBack: Navigator.canPop(context)),
                  const SizedBox(height: 14),
                  // Profile Header
                  Rise(
                    child: Row(
                      children: [
                        InitialsAvatar(initials: initialsOf(user?['fullName'] ?? ''), size: 64, ring: 1.5, glow: true),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: AppColors.text)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(PhosphorIconsFill.sealCheck, size: 15, color: AppColors.accent),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(phone, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  _buildSection(
                    context,
                    delay: 50,
                    title: 'Account Settings',
                    items: [
                      (PhosphorIconsRegular.user, 'Personal Info', phone),
                      (PhosphorIconsRegular.shieldCheck, 'Security', 'Password and authentication'),
                    ],
                  ),
                  _buildSection(
                    context,
                    delay: 100,
                    title: 'Vehicle Management',
                    items: [
                      (PhosphorIconsRegular.garage, 'My Fleet', 'Manage registered vehicles'),
                      (PhosphorIconsRegular.fileText, 'Documents', 'Licenses and insurance logs'),
                    ],
                    extra: const _StaticRow(icon: PhosphorIconsRegular.ruler, title: 'Units', value: 'Kilometers · EGP'),
                  ),
                  _buildSection(
                    context,
                    delay: 150,
                    title: 'Notifications',
                    items: [
                      (PhosphorIconsRegular.bellRinging, 'Reminders', 'Maintenance and oil changes'),
                      (PhosphorIconsRegular.megaphone, 'Alerts', 'Critical system updates'),
                    ],
                  ),
                  _buildSection(
                    context,
                    delay: 200,
                    title: 'Support',
                    items: [
                      (PhosphorIconsRegular.question, 'Help Center', 'FAQs and guides'),
                      (PhosphorIconsRegular.envelopeSimple, 'Contact Us', 'Get professional assistance'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Log Out Button
                  Rise(
                    delayMs: 250,
                    child: AmButton(
                      kind: AmButtonKind.danger,
                      label: 'Log Out',
                      icon: PhosphorIconsRegular.signOut,
                      height: 48,
                      fontSize: 14,
                      onPressed: () async {
                        await AuthService().logout();
                        if (!context.mounted) return;
                        // Navigate back to Login Screen, clearing history
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<(IconData, String, String)> items, required int delay, Widget? extra}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Rise(
        delayMs: delay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(title),
            const SizedBox(height: 8),
            AmCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const FadingRule(),
                    _buildListItem(context: context, icon: items[i].$1, title: items[i].$2, subtitle: items[i].$3),
                  ],
                  if (extra != null) ...[const FadingRule(), extra],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({required BuildContext context, required IconData icon, required String title, required String subtitle}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceholderScreen(title: title),
          ),
        );
      },
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: AppColors.text)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight, size: 15, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StaticRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.text))),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
