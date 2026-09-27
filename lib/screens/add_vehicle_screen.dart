import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/ui.dart';

/// Add / edit a vehicle as the prototype's three-step flow:
/// 1 brand · model · year, 2 odometer, 3 building your plan.
/// Submits through [CarProvider.addCar] / [CarProvider.updateCar] as before.
class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();

  bool _isLoading = false;
  String? _carId;
  bool _isEditMode = false;
  int _step = 0;
  bool _customMake = false;
  bool _customModel = false;
  bool _done = false;
  String? _error;

  static const _brands = {
    'Toyota': ['Corolla', 'Yaris', 'C-HR', 'Fortuner'],
    'Hyundai': ['Elantra', 'Accent', 'Tucson'],
    'Kia': ['Sportage', 'Cerato', 'Picanto'],
    'Nissan': ['Sunny', 'Sentra', 'Qashqai'],
    'Chevrolet': ['Optra', 'Aveo', 'Captiva'],
    'MG': ['ZS', 'MG5', 'RX5'],
    'Renault': ['Logan', 'Duster', 'Megane'],
    'BMW': ['320i', 'X3', 'X5'],
    'Mercedes': ['C200', 'E180', 'GLC'],
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isEditMode) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        _carId = args;
        _isEditMode = true;
        final provider = Provider.of<CarProvider>(context, listen: false);
        final car = provider.getCar(_carId!);
        if (car != null) {
          _makeController.text = car.make;
          _modelController.text = car.model;
          _yearController.text = car.year.toString();
          _mileageController.text = car.currentMileage.toString();
          _customMake = !_brands.containsKey(car.make);
          _customModel = _customMake || !(_brands[car.make] ?? const []).contains(car.model);
        }
      }
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  String? _validateStep1() {
    if (_makeController.text.trim().isEmpty) return 'Make is required';
    if (_modelController.text.trim().isEmpty) return 'Model is required';
    final value = _yearController.text.trim();
    if (value.isEmpty) return 'Year is required';
    final year = int.tryParse(value);
    if (year == null || year < 1980 || year > DateTime.now().year + 1) {
      return 'Enter a valid year (1980+)';
    }
    return null;
  }

  String? _validateMileage() {
    final value = _mileageController.text.trim();
    if (value.isEmpty) return 'Required';
    final mileage = int.tryParse(value);
    if (mileage == null || mileage < 0) return 'Must be a valid positive number';
    if (mileage > 999999) return 'Mileage seems too high';
    return null;
  }

  void _next() {
    if (_step == 0) {
      final err = _validateStep1();
      if (err != null) return setState(() => _error = err);
      setState(() {
        _error = null;
        _step = 1;
      });
    } else if (_step == 1) {
      final err = _validateMileage();
      if (err != null) return setState(() => _error = err);
      setState(() {
        _error = null;
        _step = 2;
      });
      _submit();
    } else if (_done) {
      Navigator.pop(context); // Go back to dashboard/garage
    }
  }

  void _back() {
    if (_isLoading) return;
    if (_step == 0 || _done) {
      Navigator.pop(context);
    } else {
      setState(() {
        _step--;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final year = int.parse(_yearController.text.trim());
    final mileage = int.parse(_mileageController.text.trim());

    final provider = Provider.of<CarProvider>(context, listen: false);
    final started = DateTime.now();
    bool success;
    if (_isEditMode && _carId != null) {
      success = await provider.updateCar(_carId!, make, model, year, mileage);
    } else {
      success = await provider.addCar(make, model, year, mileage);
    }

    // Let the plan animation play through before revealing the result.
    final elapsed = DateTime.now().difference(started);
    if (elapsed < const Duration(milliseconds: 2000)) {
      await Future.delayed(const Duration(milliseconds: 2000) - elapsed);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Success is shown on the "plan ready" step itself.
      setState(() => _done = true);
    } else {
      setState(() => _step = 1);
      showAmToast(context, 'Failed to add vehicle. Please try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _step < 2 ? 'Continue' : (_done ? 'Go to dashboard' : 'Building…');
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 18),
                  child: Row(
                    children: [
                      AmBackButton(onPressed: _back),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlowBar(value: (_step + 1) / 3, height: 4),
                      ),
                      const SizedBox(width: 12),
                      Text('${_step + 1}/3', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFeatures: tabular)),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [...previous, ?current],
                    ),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim), child: child),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: SingleChildScrollView(
                        child: [_vehicleStep, _odometerStep, _planStep][_step](),
                      ),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.warningCircle, size: 16, color: AppColors.danger),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger))),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: AmButton(
                    label: _isEditMode && _step == 1 ? 'Save Changes' : label,
                    trailingIcon: _step == 2 && !_done ? null : PhosphorIconsRegular.arrowRight,
                    loading: _isLoading,
                    glow: _done,
                    onPressed: (_step == 2 && !_done) ? null : _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vehicleStep() {
    final make = _makeController.text.trim();
    final models = _customMake ? const <String>[] : (_brands[make] ?? const <String>[]);
    final thisYear = DateTime.now().year;
    final years = List.generate(thisYear + 1 - 1980 + 1, (i) => thisYear + 1 - i);
    final selectedYear = int.tryParse(_yearController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_isEditMode ? 'Edit your vehicle' : 'What do you drive?', style: AmText.h2),
        const SizedBox(height: 20),
        const SectionLabel('Brand'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.3,
          children: [
            ..._brands.keys.map((b) => AmChoice(
                  label: b,
                  selected: !_customMake && make == b,
                  radius: 12,
                  height: 48,
                  onTap: () => setState(() {
                    _customMake = false;
                    _customModel = false;
                    _makeController.text = b;
                    if (!(_brands[b]!).contains(_modelController.text.trim())) _modelController.text = '';
                    _error = null;
                  }),
                )),
          ],
        ),
        const SizedBox(height: 8),
        AmChoice(
          label: 'Other brand',
          icon: PhosphorIconsRegular.pencilSimple,
          selected: _customMake,
          radius: 12,
          height: 44,
          onTap: () => setState(() {
            _customMake = true;
            _customModel = true;
            if (_brands.containsKey(_makeController.text.trim())) _makeController.text = '';
            _error = null;
          }),
        ),
        if (_customMake) ...[
          const SizedBox(height: 12),
          Rise(
            offset: 6,
            child: AmField(
              label: 'MAKE (e.g. Toyota, BMW)',
              controller: _makeController,
              hint: 'Toyota',
              icon: PhosphorIconsRegular.carProfile,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionLabel('Model'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...models.map((m) => Rise(
                  offset: 0,
                  durationMs: 300,
                  child: AmChoice(
                    label: m,
                    selected: !_customModel && _modelController.text.trim() == m,
                    onTap: () => setState(() {
                      _customModel = false;
                      _modelController.text = m;
                      _error = null;
                    }),
                  ),
                )),
            if (!_customMake)
              AmChoice(
                label: 'Other',
                icon: PhosphorIconsRegular.pencilSimple,
                selected: _customModel,
                onTap: () => setState(() {
                  _customModel = true;
                  if (models.contains(_modelController.text.trim())) _modelController.text = '';
                  _error = null;
                }),
              ),
          ],
        ),
        if (_customModel) ...[
          const SizedBox(height: 12),
          Rise(
            offset: 6,
            child: AmField(
              label: 'MODEL (e.g. Corolla, X5)',
              controller: _modelController,
              hint: 'Corolla',
              icon: PhosphorIconsRegular.car,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionLabel('Year'),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: years.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => SizedBox(
              width: 64,
              child: AmChoice(
                label: '${years[i]}',
                selected: selectedYear == years[i],
                radius: 12,
                height: 44,
                padding: EdgeInsets.zero,
                onTap: () => setState(() {
                  _yearController.text = '${years[i]}';
                  _error = null;
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _odometerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("What's on the odometer?", style: AmText.h2),
        const SizedBox(height: 8),
        const Text('Check your dashboard — we use it to predict every service.', style: AmText.body),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent700),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.12), blurRadius: 40)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: _mileageController,
                  autofocus: !_isEditMode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  cursorColor: AppColors.accent,
                  onChanged: (_) => setState(() => _error = null),
                  style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w500, letterSpacing: -1.4, color: AppColors.text, fontFeatures: tabular),
                  decoration: const InputDecoration(
                    hintText: '45000',
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Text('km', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AmCard(
          child: Row(
            children: [
              const CarBadge(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_yearController.text} ${_makeController.text} ${_modelController.text}'.trim(), style: const TextStyle(fontSize: 15, color: AppColors.text)),
                    const Text('Tap back to change', style: AmText.sub),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _planStep() {
    final make = _makeController.text.trim();
    final lines = [
      'Loading $make service intervals',
      'Saving your odometer reading',
      'Scheduling maintenance reminders',
      'Finding certified centers nearby',
    ];
    final mileage = int.tryParse(_mileageController.text.trim()) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.neutral800, width: 2))),
              AnimatedOpacity(
                opacity: _done ? 0 : 1,
                duration: const Duration(milliseconds: 400),
                child: const SizedBox(width: 96, height: 96, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _done ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.gearSix,
                  key: ValueKey(_done),
                  size: 34,
                  color: AppColors.accent300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(_done ? 'Your plan is ready' : 'Building your plan', style: AmText.h2),
        const SizedBox(height: 20),
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CalcLine(label: lines[i], delayMs: 250 + i * 420, done: _done),
          ),
        if (_done)
          Rise(
            child: AmCard(
              padding: const EdgeInsets.all(16),
              edge: AppColors.accent700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isEditMode ? 'UPDATED' : 'ADDED TO YOUR GARAGE', style: const TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.accent)),
                  const SizedBox(height: 6),
                  Text('$make ${_modelController.text.trim()} · ${kmFormat.format(mileage)} km', style: const TextStyle(fontSize: 18, color: AppColors.text)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A checklist line that ticks itself on after a delay.
class _CalcLine extends StatefulWidget {
  final String label;
  final int delayMs;
  final bool done;
  const _CalcLine({required this.label, required this.delayMs, required this.done});

  @override
  State<_CalcLine> createState() => _CalcLineState();
}

class _CalcLineState extends State<_CalcLine> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final on = _on || widget.done;
    return AnimatedOpacity(
      opacity: on ? 1 : 0.35,
      duration: const Duration(milliseconds: 450),
      child: AnimatedSlide(
        offset: on ? Offset.zero : const Offset(0, 0.25),
        duration: const Duration(milliseconds: 450),
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: on ? AppColors.accent600 : AppColors.neutral800),
              child: const Icon(PhosphorIconsRegular.check, size: 13, color: AppColors.accent100),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.label, style: const TextStyle(fontSize: 15, color: AppColors.text))),
          ],
        ),
      ),
    );
  }
}
