import 'package:flutter/material.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/maintenance_ui.dart';
import '../widgets/ui.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  final _centerNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController();

  String? _selectedType;
  String? _selectedQuality;
  DateTime _serviceDate = DateTime.now();
  DateTime? _productionDate;
  bool _isLoading = false;

  final List<String> _maintenanceTypes = [
    'ENGINE_OIL', 'BRAKE_OIL', 'GEAR_OIL', 'ENGINE_BELT',
    'AIR_FILTER', 'AC_FILTER', 'BATTERY', 'ENGINE_COOLANT',
    'SPARK_PLUGS', 'TIRE_REPLACEMENT', 'TIRE_ROTATION', 'AC_REFRIGERANT_SERVICE'
  ];

  final List<String> _partQualities = ['ORIGINAL', 'OEM', 'AFTERMARKET', 'COMMERCIAL'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mileageController.text.isEmpty) {
      final carId = ModalRoute.of(context)?.settings.arguments as String?;
      if (carId != null) {
        final car = Provider.of<CarProvider>(context, listen: false).getCar(carId);
        if (car != null) {
          _mileageController.text = car.currentMileage.toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _costController.dispose();
    _mileageController.dispose();
    _centerNameController.dispose();
    _notesController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _serviceDate) {
      setState(() {
        _serviceDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      showAmToast(context, 'Please select a Maintenance Type', error: true);
      return;
    }
    if ((_selectedType == 'BATTERY' || _selectedType == 'TIRE_REPLACEMENT') && _productionDate == null) {
      showAmToast(context, 'Production Date is required for Tires and Batteries', error: true);
      return;
    }

    final carId = ModalRoute.of(context)?.settings.arguments as String?;
    if (carId == null) return;

    setState(() => _isLoading = true);

    final data = {
      "maintenanceType": _selectedType,
      if (_selectedQuality != null) "partQuality": _selectedQuality,
      "serviceDate": DateFormat('yyyy-MM-dd').format(_serviceDate),
      "serviceMileage": int.tryParse(_mileageController.text.trim()) ?? 0,
      "cost": double.tryParse(_costController.text.trim()) ?? 0.0,
      if (_intervalController.text.trim().isNotEmpty)
        "customIntervalKm": int.tryParse(_intervalController.text.trim()),
      "serviceCenterName": _centerNameController.text.trim(),
      "notes": _notesController.text.trim(),
      if (_productionDate != null)
        "metadata": {
          "productionDate": DateFormat('yyyy-MM-dd').format(_productionDate!),
        }
    };

    final provider = Provider.of<CarProvider>(context, listen: false);
    final success = await provider.addMaintenanceRecord(carId, data);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      showAmToastOn(messenger, 'Maintenance record added!');
    } else {
      showAmToast(context, 'Failed to add record. Please try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carId = ModalRoute.of(context)?.settings.arguments as String?;
    final car = carId != null ? Provider.of<CarProvider>(context, listen: false).getCar(carId) : null;
    final needsProduction = _selectedType == 'BATTERY' || _selectedType == 'TIRE_REPLACEMENT';

    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
              children: [
                ScreenHeader(
                  title: 'Add record',
                  subtitle: car != null ? '${car.make} ${car.model}' : null,
                  showBack: true,
                ),
                const SizedBox(height: 14),

                // Cost
                Rise(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('EGP', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          IntrinsicWidth(
                            child: TextFormField(
                              controller: _costController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              cursorColor: AppColors.accent,
                              textAlign: TextAlign.center,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -2,
                                color: _costController.text.isEmpty ? AppColors.textFaint : AppColors.text,
                                fontFeatures: tabular,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(color: AppColors.neutral700),
                                filled: false,
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                errorStyle: TextStyle(fontSize: 12, color: AppColors.danger),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final cost = double.tryParse(value);
                                if (cost == null || cost < 0) return 'Must be a valid positive number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Text('Cost of this service', style: AmText.sub),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Type
                const SectionLabel('Maintenance Type'),
                const SizedBox(height: 10),
                Rise(
                  delayMs: 60,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _maintenanceTypes
                        .map((type) => AmChoice(
                              label: typeLabel(type),
                              icon: typeIcon(type),
                              selected: _selectedType == type,
                              height: 36,
                              radius: 18,
                              fontSize: 13,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              onTap: () => setState(() => _selectedType = type),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Car + date
                Row(
                  children: [
                    Expanded(
                      child: _pill(PhosphorIconsRegular.carProfile, car != null ? '${car.make} ${car.model}' : 'Vehicle'),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: _pill(PhosphorIconsRegular.calendarBlank, DateFormat('MMM dd, yyyy').format(_serviceDate), trailing: PhosphorIconsRegular.caretDown),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                const SectionLabel('Details'),
                const SizedBox(height: 10),
                AmField(
                  label: 'Service Mileage (km)',
                  controller: _mileageController,
                  keyboardType: TextInputType.number,
                  icon: PhosphorIconsRegular.gauge,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final mileage = int.tryParse(value);
                    if (mileage == null || mileage < 0) return 'Must be a valid positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AmField(
                  label: 'Service Center Name',
                  controller: _centerNameController,
                  icon: PhosphorIconsRegular.storefront,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    if (value.trim().length < 3) return 'Name must be at least 3 characters';
                    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return 'Name must contain letters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AmField(
                  label: 'Next Change Interval (km) · optional',
                  controller: _intervalController,
                  hint: 'e.g. 10000',
                  keyboardType: TextInputType.number,
                  icon: PhosphorIconsRegular.arrowsClockwise,
                ),
                const SizedBox(height: 22),

                // Quality
                const SectionLabel('Part Quality · optional'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _partQualities
                      .map((q) => AmChoice(
                            label: q == 'OEM' ? q : q[0] + q.substring(1).toLowerCase(),
                            selected: _selectedQuality == q,
                            height: 36,
                            radius: 18,
                            fontSize: 13,
                            onTap: () => setState(() => _selectedQuality = _selectedQuality == q ? null : q),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),

                // Production Date
                AmCard(
                  radius: 14,
                  edge: needsProduction && _productionDate == null ? AppColors.warn.withValues(alpha: 0.5) : AppColors.line,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _productionDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _productionDate = picked);
                    }
                  },
                  child: Row(
                    children: [
                      const IconTile(icon: PhosphorIconsRegular.calendarDots),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Part Production Date${needsProduction ? ' (Required)' : ' (Optional)'}',
                              style: TextStyle(fontSize: 11.5, color: needsProduction ? AppColors.warn : AppColors.textMuted),
                            ),
                            Text(
                              _productionDate != null ? DateFormat('MMM dd, yyyy').format(_productionDate!) : 'Select Date',
                              style: const TextStyle(fontSize: 15, color: AppColors.text),
                            ),
                          ],
                        ),
                      ),
                      const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textFaint),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Notes
                AmField(
                  label: 'Notes',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Submit
                AmButton(
                  label: 'Save Record',
                  icon: PhosphorIconsRegular.check,
                  loading: _isLoading,
                  glow: true,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, {IconData? trailing}) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.accent),
          const SizedBox(width: 6),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
          if (trailing != null) ...[const SizedBox(width: 4), Icon(trailing, size: 12, color: AppColors.textMuted)],
        ],
      ),
    );
  }
}
