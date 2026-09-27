import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import '../theme/app_colors.dart';

/// Shared building blocks for the Nocturne screens: the page background,
/// entrance animations, buttons, cards, tags and headers used everywhere.

const tabular = [FontFeature.tabularFigures()];

class AmText {
  AmText._();
  static const h1 = TextStyle(fontSize: 38, height: 1.05, fontWeight: FontWeight.w500, letterSpacing: -1.3, color: AppColors.text);
  static const h2 = TextStyle(fontSize: 30, height: 1.12, fontWeight: FontWeight.w500, letterSpacing: -0.9, color: AppColors.text);
  static const h3 = TextStyle(fontSize: 25, height: 1.12, fontWeight: FontWeight.w500, letterSpacing: -0.6, color: AppColors.text);
  static const h4 = TextStyle(fontSize: 20, height: 1.12, fontWeight: FontWeight.w500, letterSpacing: -0.3, color: AppColors.text);
  static const body = TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMuted);
  static const sub = TextStyle(fontSize: 12, color: AppColors.textMuted);
}

/// The phone ground: a soft accent bloom top-left and an indigo one bottom-right.
class AmBackground extends StatelessWidget {
  final Widget child;
  const AmBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bg),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.7, -1.16),
                  radius: 1.1,
                  colors: [AppColors.accentTint, Color(0x002B2741)],
                  stops: [0, 0.62],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.2, 1.16),
                  radius: 0.95,
                  colors: [AppColors.section.withValues(alpha: 0.75), AppColors.section.withValues(alpha: 0)],
                  stops: const [0, 0.62],
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Fade + rise entrance (the prototype's amRise).
class Rise extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final double offset;
  const Rise({super.key, required this.child, this.delayMs = 0, this.durationMs = 450, this.offset = 14});

  @override
  Widget build(BuildContext context) {
    final total = delayMs + durationMs;
    final start = total == 0 ? 0.0 : delayMs / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, t, child) {
        final p = start >= 1 ? 1.0 : ((t - start) / (1 - start)).clamp(0.0, 1.0);
        final v = Curves.easeOutCubic.transform(p);
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, offset * (1 - v)), child: child),
        );
      },
      child: child,
    );
  }
}

/// Animated count-up for large numbers.
class CountUp extends StatelessWidget {
  final num value;
  final TextStyle style;
  final String Function(num v) format;
  final int durationMs;
  const CountUp({super.key, required this.value, required this.style, required this.format, this.durationMs = 1200});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style.copyWith(fontFeatures: tabular)),
    );
  }
}

enum AmButtonKind { primary, secondary, ghost, danger }

/// Nocturne buttons: primary is an accent outline with a faint glow, never a flood.
class AmButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final AmButtonKind kind;
  final double height;
  final double radius;
  final double fontSize;
  final bool expand;
  final bool loading;
  final bool glow;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AmButton({
    super.key,
    this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.kind = AmButtonKind.primary,
    this.height = 52,
    this.radius = 14,
    this.fontSize = 16,
    this.expand = true,
    this.loading = false,
    this.glow = false,
    this.padding,
    this.color,
  });

  const AmButton.secondary({
    super.key,
    this.label,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.height = 48,
    this.radius = 14,
    this.fontSize = 14,
    this.expand = true,
    this.loading = false,
    this.padding,
    this.color,
  })  : kind = AmButtonKind.secondary,
        glow = false;

  @override
  State<AmButton> createState() => _AmButtonState();
}

class _AmButtonState extends State<AmButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    Color fg;
    Color border;
    Color fill;
    switch (widget.kind) {
      case AmButtonKind.primary:
        fg = AppColors.accent;
        border = AppColors.accent;
        fill = AppColors.accent.withValues(alpha: _pressed ? 0.22 : 0.0);
        break;
      case AmButtonKind.secondary:
        fg = AppColors.text;
        border = AppColors.line;
        fill = AppColors.text.withValues(alpha: _pressed ? 0.14 : 0.0);
        break;
      case AmButtonKind.ghost:
        fg = AppColors.accent;
        border = Colors.transparent;
        fill = AppColors.accent.withValues(alpha: _pressed ? 0.18 : 0.0);
        break;
      case AmButtonKind.danger:
        fg = AppColors.danger;
        border = AppColors.line;
        fill = AppColors.danger.withValues(alpha: _pressed ? 0.14 : 0.0);
        break;
    }
    if (widget.color != null) fg = widget.color!;

    final children = <Widget>[];
    if (widget.loading) {
      children.add(SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: fg, backgroundColor: fg.withValues(alpha: 0.3)),
      ));
    } else {
      if (widget.icon != null) children.add(Icon(widget.icon, size: widget.fontSize + 2, color: fg));
      if (widget.label != null) {
        if (children.isNotEmpty) children.add(const SizedBox(width: 6));
        children.add(Flexible(
          child: Text(
            widget.label!,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.w500, color: fg, height: 1.2),
          ),
        ));
      }
      if (widget.trailingIcon != null) {
        children.add(const SizedBox(width: 6));
        children.add(Icon(widget.trailingIcon, size: widget.fontSize + 2, color: fg));
      }
    }

    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: widget.height,
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: widget.kind == AmButtonKind.ghost ? 4 : 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: border),
        boxShadow: widget.glow && enabled ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 30)] : null,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );

    return Opacity(
      opacity: enabled || widget.loading ? 1 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: btn,
      ),
    );
  }
}

/// Square outlined icon button (44px, radius 14) used for back / add / close.
class AmIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double radius;
  final bool primary;
  final Widget? badge;
  const AmIconButton({super.key, required this.icon, this.onPressed, this.size = 44, this.radius = 14, this.primary = false, this.badge});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        splashColor: AppColors.accent.withValues(alpha: 0.14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: primary ? AppColors.accent : AppColors.line),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: size * 0.41, color: primary ? AppColors.accent : AppColors.text),
              ?badge,
            ],
          ),
        ),
      ),
    );
  }
}

/// Back arrow in the header.
class AmBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AmBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AmIconButton(
      icon: PhosphorIconsRegular.arrowLeft,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}

/// Surface card with the hairline edge (shadow-sm).
class AmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? edge;
  final List<BoxShadow>? shadow;
  const AmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 8,
    this.onTap,
    this.color,
    this.gradient,
    this.edge,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge ?? AppColors.neutral800),
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, child: box);
  }
}

/// Scales down slightly while pressed (the prototype's :active transforms).
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.98});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}

/// Small uppercase section label (h6).
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 13, letterSpacing: 1.04, fontWeight: FontWeight.w500, color: AppColors.textMuted),
    );
    if (trailing == null) return label;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [label, trailing!],
    );
  }
}

/// Small text link in the accent (btn-ghost).
class AmLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final IconData? icon;
  final double fontSize;
  const AmLink(this.text, {super.key, this.onTap, this.icon, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: fontSize + 2, color: AppColors.accent), const SizedBox(width: 5)],
            Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

/// Tinted tag.
class AmTag extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final double fontSize;
  const AmTag(this.text, {super.key, this.background = AppColors.accentDeep, this.foreground = AppColors.accent100, this.icon, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: fontSize + 1, color: foreground), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: fontSize, letterSpacing: 0.2, color: foreground, height: 1.3)),
        ],
      ),
    );
  }
}

/// Page header: optional back button, title (h3) with subtitle, trailing actions.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  const ScreenHeader({super.key, required this.title, this.subtitle, this.showBack = false, this.onBack, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Rise(
      offset: 0,
      durationMs: 400,
      child: Row(
        children: [
          if (showBack) ...[AmBackButton(onPressed: onBack), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AmText.h3, overflow: TextOverflow.ellipsis),
                if (subtitle != null) Text(subtitle!, style: AmText.sub, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 10), action],
        ],
      ),
    );
  }
}

/// Rounded tinted icon tile (40px).
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double radius;
  final Color? edge;
  const IconTile({super.key, required this.icon, this.color = AppColors.accent300, this.background = AppColors.accentTint, this.size = 40, this.radius = 12, this.edge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: edge != null ? Border.all(color: edge!) : null,
      ),
      child: Icon(icon, size: size * 0.48, color: color),
    );
  }
}

/// Thin glowing progress bar with an animated fill.
class GlowBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final bool glow;
  final Gradient? gradient;
  const GlowBar({super.key, required this.value, this.color = AppColors.accent, this.height = 5, this.glow = true, this.gradient});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.neutral800,
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: gradient == null ? color : null,
                gradient: gradient,
                borderRadius: BorderRadius.circular(height),
                boxShadow: glow ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 10)] : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rule that fades to transparent at both ends.
class FadingRule extends StatelessWidget {
  const FadingRule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, decoration: const BoxDecoration(gradient: AppColors.fadingRule));
  }
}

/// Segmented filter (the maintenance filter / profile language control).
class AmSegmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final double height;
  final Color background;
  const AmSegmented({super.key, required this.values, required this.selected, required this.label, required this.onChanged, this.height = 34, this.background = AppColors.surface});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral800),
      ),
      child: Row(
        children: values.map((v) {
          final sel = v == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.accentTint : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: sel ? AppColors.accent700 : Colors.transparent),
                ),
                child: Text(
                  label(v),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: sel ? AppColors.accent200 : AppColors.textMuted),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Selectable pill / grid option used in pickers and filters.
class AmChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final Widget? leading;
  const AmChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.height = 40,
    this.radius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.fontSize = 14,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentTint : AppColors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: selected ? AppColors.accent : AppColors.line),
          boxShadow: selected ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 14)] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 7)],
            if (icon != null) ...[Icon(icon, size: fontSize + 1, color: selected ? AppColors.accent200 : AppColors.textMuted), const SizedBox(width: 6)],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, color: selected ? AppColors.accent200 : AppColors.textSecondary, fontFeatures: tabular),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled text input in the prototype's field style.
class AmField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final IconData? icon;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  const AmField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.icon,
    this.suffix,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.text.withValues(alpha: 0.7))),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          onChanged: onChanged,
          textCapitalization: textCapitalization,
          cursorColor: AppColors.accent,
          style: const TextStyle(fontSize: 16, color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: icon != null ? Icon(icon, size: 19) : null,
            suffixIcon: suffix,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 14 : 15),
          ),
        ),
      ],
    );
  }
}

/// Car tile: blurple gradient square with a car outline.
class CarBadge extends StatelessWidget {
  final double size;
  const CarBadge({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 3),
        gradient: const LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [AppColors.accentDeep, AppColors.neutral900]),
        border: Border.all(color: AppColors.accentDeep),
      ),
      child: Icon(PhosphorIconsRegular.carProfile, size: size * 0.52, color: AppColors.accent300),
    );
  }
}

/// Round initials avatar with the accent ring.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final double ring;
  final bool glow;
  const InitialsAvatar({super.key, required this.initials, this.size = 46, this.ring = 1, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4 + ring * 2,
      height: size + 4 + ring * 2,
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent600,
        boxShadow: glow ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 30)] : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bg),
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [AppColors.accent700, AppColors.section]),
          ),
          child: Text(initials, style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w500, color: AppColors.accent100)),
        ),
      ),
    );
  }
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'AM';
  if (parts.length == 1) return parts.first.substring(0, math.min(2, parts.first.length)).toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Spinning accent ring (loading).
class AmSpinner extends StatelessWidget {
  final double size;
  const AmSpinner({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.accent,
        backgroundColor: AppColors.accent.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Dashed outline "add another" tile.
class DashedAddTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const DashedAddTile({super.key, required this.icon, required this.title, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(color: AppColors.neutral700, radius: 14),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppColors.accent),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 15, color: AppColors.text)),
              const SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: AmText.sub),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 6, metric.length)), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color;
}

/// Circular progress ring with an optional glow (health ring, document rings).
class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;
  final bool glow;
  RingPainter({required this.progress, required this.color, this.track = AppColors.neutral800, this.stroke = 14, this.glow = true});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(center, r, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (glow) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }
    canvas.drawArc(rect, -math.pi / 2, sweep, false, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke);
  }

  @override
  bool shouldRepaint(covariant RingPainter old) => old.progress != progress || old.color != color;
}

/// Bottom-sheet chrome: handle + surface + rounded top.
Future<T?> showAmSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.neutral900.withValues(alpha: 0.65),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: AppColors.neutral700, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Sheet title row with close button.
class SheetTitle extends StatelessWidget {
  final String title;
  const SheetTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AmText.h4)),
        AmIconButton(icon: PhosphorIconsRegular.x, size: 36, radius: 12, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}

/// Themed snackbar.
void showAmToast(BuildContext context, String message, {IconData icon = PhosphorIconsFill.checkCircle, bool error = false}) {
  showAmToastOn(ScaffoldMessenger.of(context), message, icon: icon, error: error);
}

void showAmToastOn(ScaffoldMessengerState messenger, String message, {IconData icon = PhosphorIconsFill.checkCircle, bool error = false}) {
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: AppColors.neutral800.withValues(alpha: 0.95),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: error ? AppColors.dangerLine : AppColors.accent700),
      ),
      content: Row(
        children: [
          Icon(error ? PhosphorIconsRegular.warningCircle : icon, color: error ? AppColors.danger : AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.text, fontSize: 14))),
        ],
      ),
    ),
  );
}
