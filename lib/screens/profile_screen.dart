import 'package:flutter/material.dart';
import 'notifications_screen.dart';
import '../widgets/notification_bell.dart';
import '../services/auth_service.dart';
import 'placeholder_screen.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          'AutoMate',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        actions: [
          const NotificationBell(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService().fetchProfile(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final fullName = user?['fullName'] ?? (snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : 'AutoMate Member');
          final phone = user?['phone'] ?? 'Manage your account';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                children: [
                  // Profile Header
                  Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.lineStrong),
                            image: const DecorationImage(
                              image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.bg, width: 2),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.accentDeep,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings, color: AppColors.text, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.text),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentTint, // Light blue pill
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('Premium Member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildSection(
                title: 'ACCOUNT SETTINGS',
                items: [
                  _buildListItem(context: context, icon: Icons.person_outline, title: 'Personal Info', subtitle: phone),
                  _buildListItem(context: context, icon: Icons.security_outlined, title: 'Security', subtitle: 'Password and authentication', showDivider: false),
                ],
              ),
              const SizedBox(height: 24),

              _buildSection(
                title: 'VEHICLE MANAGEMENT',
                items: [
                  _buildListItem(context: context, icon: Icons.directions_car_outlined, title: 'My Fleet', subtitle: 'Manage registered vehicles'),
                  _buildListItem(context: context, icon: Icons.description_outlined, title: 'Documents', subtitle: 'Licenses and insurance logs', showDivider: false),
                ],
              ),
              const SizedBox(height: 24),

              _buildSection(
                title: 'NOTIFICATIONS',
                items: [
                  _buildListItem(context: context, icon: Icons.notifications_active_outlined, title: 'Reminders', subtitle: 'Maintenance and oil changes'),
                  _buildListItem(context: context, icon: Icons.campaign_outlined, title: 'Alerts', subtitle: 'Critical system updates', showDivider: false),
                ],
              ),
              const SizedBox(height: 24),

              _buildSection(
                title: 'SUPPORT',
                items: [
                  _buildListItem(context: context, icon: Icons.help_outline, title: 'Help Center', subtitle: 'FAQs and guides'),
                  _buildListItem(context: context, icon: Icons.email_outlined, title: 'Contact Us', subtitle: 'Get professional assistance', showDivider: false),
                ],
              ),
              const SizedBox(height: 32),

              // Log Out Button
              OutlinedButton.icon(
                onPressed: () async {
                  await AuthService().logout();
                  if (!context.mounted) return;
                  // Navigate back to Login Screen, clearing history
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.dangerLine),
                  backgroundColor: AppColors.dangerTint,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
      }),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: AppColors.textFaint),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.line, width: 1),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({required BuildContext context, required IconData icon, required String title, required String subtitle, bool showDivider = true}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.text, size: 24),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.text)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceholderScreen(title: title),
              ),
            );
          },
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.line, indent: 16, endIndent: 16),
      ],
    );
  }
}
