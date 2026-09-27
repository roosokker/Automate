import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(title: title, showBack: true),
                const Spacer(),
                Rise(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [AppColors.accentDeep, AppColors.neutral900]),
                          border: Border.all(color: AppColors.accent700),
                          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 36)],
                        ),
                        child: const Icon(PhosphorIconsRegular.wrench, size: 34, color: AppColors.accent200),
                      ),
                      const SizedBox(height: 24),
                      Text('$title Coming Soon', style: AmText.h2),
                      const SizedBox(height: 12),
                      const Text(
                        'We are working hard to bring you this feature in the next update. Stay tuned!',
                        style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AmButton(
                  label: 'Go Back',
                  icon: PhosphorIconsRegular.arrowLeft,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
