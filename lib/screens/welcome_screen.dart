import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Rise(
                    offset: 0,
                    durationMs: 600,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const BrandMark(),
                          const SizedBox(height: 26),
                          const Center(child: _Orbit()),
                          const Spacer(),
                          const SizedBox(height: 30),
                          const Text('Your car,\non autopilot.', style: AmText.h1),
                          const SizedBox(height: 12),
                          const Text(
                            'Log every pound, track every kilometer, and get reminded before anything wears out.',
                            style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 22),
                          AmButton(
                            label: 'Get started',
                            trailingIcon: PhosphorIconsRegular.arrowRight,
                            glow: true,
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                          ),
                          const SizedBox(height: 6),
                          AmButton(
                            label: 'I already have an account',
                            kind: AmButtonKind.ghost,
                            height: 46,
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Steering-wheel mark + wordmark.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(color: AppColors.accent),
          ),
          child: Icon(PhosphorIconsRegular.steeringWheel, size: size * 0.58, color: AppColors.accent),
        ),
        const SizedBox(width: 8),
        Text('AutoMate', style: TextStyle(fontSize: size * 0.56 + 0.5, fontWeight: FontWeight.w500, letterSpacing: -0.15, color: AppColors.text)),
      ],
    );
  }
}

class _Orbit extends StatefulWidget {
  const _Orbit();

  @override
  State<_Orbit> createState() => _OrbitState();
}

class _OrbitState extends State<_Orbit> with TickerProviderStateMixin {
  late final AnimationController _outer = AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
  late final AnimationController _inner = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _outer.dispose();
    _inner.dispose();
    _float.dispose();
    super.dispose();
  }

  Widget _satellite(IconData icon, {double size = 46, bool accent = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent ? AppColors.accentDeep : AppColors.surface,
        border: Border.all(color: accent ? AppColors.accent600 : AppColors.neutral700),
        boxShadow: accent
            ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 24)]
            : const [BoxShadow(color: Color(0x8C000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Icon(icon, size: size * 0.43, color: accent ? AppColors.accent200 : AppColors.neutral200),
    );
  }

  @override
  Widget build(BuildContext context) {
    const box = 290.0;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ring(0, AppColors.line),
          _ring(45, AppColors.line),
          _ring(90, AppColors.accentDeep),
          Positioned.fill(
            left: 105,
            top: 105,
            right: 105,
            bottom: 105,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [AppColors.accentDeep, AppColors.neutral900]),
                border: Border.all(color: AppColors.accent700),
                boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 70)],
              ),
              child: const Icon(PhosphorIconsRegular.carProfile, size: 44, color: AppColors.accent200),
            ),
          ),
          // Outer orbit: fuel (top) and map pin (bottom), clockwise.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _outer,
              builder: (context, _) {
                final a = _outer.value * 2 * math.pi;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _onCircle(box / 2, a - math.pi / 2, _satellite(PhosphorIconsRegular.gasPump)),
                    _onCircle(box / 2, a + math.pi / 2, _satellite(PhosphorIconsRegular.mapPin)),
                  ],
                );
              },
            ),
          ),
          // Inner orbit: alert bell (left) and wrench (right), counter-clockwise.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _inner,
              builder: (context, _) {
                final a = -_inner.value * 2 * math.pi;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _onCircle(box / 2 - 45, a + math.pi, _satellite(PhosphorIconsFill.bellRinging, size: 42, accent: true)),
                    _onCircle(box / 2 - 45, a, _satellite(PhosphorIconsRegular.wrench, size: 42)),
                  ],
                );
              },
            ),
          ),
          Positioned(
            right: -14,
            top: 30,
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -8 * Curves.easeInOut.transform(_float.value)),
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.neutral800.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral700),
                  boxShadow: const [BoxShadow(color: Color(0x8C000000), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.warn)),
                    const SizedBox(width: 6),
                    const Text('Oil change reminders', style: TextStyle(fontSize: 12, color: AppColors.text)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(double inset, Color color) {
    return Positioned.fill(
      left: inset,
      top: inset,
      right: inset,
      bottom: inset,
      child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color))),
    );
  }

  Widget _onCircle(double r, double angle, Widget child) {
    const c = 145.0;
    return Positioned(
      left: c + r * math.cos(angle),
      top: c + r * math.sin(angle),
      child: FractionalTranslation(translation: const Offset(-0.5, -0.5), child: child),
    );
  }
}
