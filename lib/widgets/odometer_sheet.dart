import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../models/car.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';
import 'maintenance_ui.dart';
import 'ui.dart';

/// "Update odometer" sheet: −/+ steppers, a slider, a typed value, and a live
/// preview of which reminders the new reading would bring due. Saving calls
/// [CarProvider.logMileage] exactly as before.
Future<void> showOdometerSheet(BuildContext context, Car car) {
  return showAmSheet(context, builder: (_) => _OdometerSheet(car: car));
}

class _OdometerSheet extends StatefulWidget {
  final Car car;
  const _OdometerSheet({required this.car});

  @override
  State<_OdometerSheet> createState() => _OdometerSheetState();
}

class _OdometerSheetState extends State<_OdometerSheet> {
  late final TextEditingController _controller;
  late int _value;
  bool _isLoading = false;
  String? _errorText;

  int get _min => widget.car.currentMileage;
  int get _max => widget.car.currentMileage + 5000;

  @override
  void initState() {
    super.initState();
    _value = widget.car.currentMileage;
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(int v) {
    setState(() {
      _value = v < 0 ? 0 : v;
      _controller.text = _value.toString();
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      _errorText = null;
    });
  }

  Future<void> _save() async {
    final input = int.tryParse(_controller.text.trim());
    if (input == null) {
      setState(() => _errorText = 'Please enter a valid number');
      return;
    }
    if (input <= widget.car.currentMileage) {
      setState(() => _errorText = 'New mileage must be greater than current');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final provider = Provider.of<CarProvider>(context, listen: false);
    final success = await provider.logMileage(widget.car.id, input);

    if (!mounted) return;

    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showAmToastOn(messenger, 'Mileage updated successfully!');
    } else {
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to update mileage. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CarProvider>(context);
    final delta = _value - widget.car.currentMileage;
    final triggers = sortedReminders(provider.getReminders(widget.car.id), widget.car)
        .where((r) =>
            r.reminder.dueMileage != null &&
            (r.status == MStatus.ok || r.status == MStatus.soon) &&
            r.reminder.dueMileage! <= _value)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetTitle('Update odometer'),
          Text('Last reading ${kmFormat.format(widget.car.currentMileage)} km · ${widget.car.displayName}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          Row(
            children: [
              AmIconButton(icon: PhosphorIconsRegular.minus, size: 48, onPressed: () => _set(_value - 100)),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      cursorColor: AppColors.accent,
                      onChanged: (v) => setState(() {
                        _value = int.tryParse(v) ?? _value;
                        _errorText = null;
                      }),
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w500, letterSpacing: -1.5, height: 1.1, color: AppColors.text, fontFeatures: tabular),
                      decoration: const InputDecoration(
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                    Text(
                      delta > 0 ? '+${kmFormat.format(delta)} km since last update' : 'km',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.accent300),
                    ),
                  ],
                ),
              ),
              AmIconButton(icon: PhosphorIconsRegular.plus, size: 48, onPressed: () => _set(_value + 100)),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.neutral800,
              thumbColor: AppColors.accent200,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              min: _min.toDouble(),
              max: _max.toDouble(),
              value: _value.clamp(_min, _max).toDouble(),
              onChanged: (v) => _set((v / 10).round() * 10),
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.warningCircle, size: 16, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_errorText!, style: const TextStyle(fontSize: 13, color: AppColors.danger))),
                ],
              ),
            ),
          const SectionLabel('What this triggers'),
          const SizedBox(height: 8),
          if (triggers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(PhosphorIconsRegular.checkCircle, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 10),
                  Text('Nothing new becomes due', style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
                ],
              ),
            )
          else
            ...triggers.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Rise(
                    offset: 0,
                    durationMs: 300,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(color: MStatus.due.tint, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsFill.bellRinging, size: 18, color: AppColors.warn),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.name, style: const TextStyle(fontSize: 13.5, color: AppColors.text))),
                          Text('Due at ${kmFormat.format(t.reminder.dueMileage)}', style: const TextStyle(fontSize: 12, color: AppColors.warn)),
                        ],
                      ),
                    ),
                  ),
                )),
          const SizedBox(height: 14),
          AmButton(
            label: 'Save reading',
            icon: PhosphorIconsRegular.gauge,
            height: 50,
            fontSize: 15,
            loading: _isLoading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
