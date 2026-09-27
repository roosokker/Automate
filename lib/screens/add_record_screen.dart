import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Maintenance Type')));
      return;
    }
    if ((_selectedType == 'BATTERY' || _selectedType == 'TIRE_REPLACEMENT') && _productionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Production Date is required for Tires and Batteries')));
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
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance record added!'), backgroundColor: AppColors.accentDeep),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add record. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Record', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Maintenance Type', border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
                items: _maintenanceTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.replaceAll('_', ' ')))).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              // Quality
              DropdownButtonFormField<String>(
                value: _selectedQuality,
                decoration: const InputDecoration(labelText: 'Part Quality (Optional)', border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
                items: _partQualities.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                onChanged: (val) => setState(() => _selectedQuality = val),
              ),
              const SizedBox(height: 16),
              
              // Date
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Service Date', border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_serviceDate)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Production Date
              InkWell(
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
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Part Production Date' + ((_selectedType == 'BATTERY' || _selectedType == 'TIRE_REPLACEMENT') ? ' (Required)' : ' (Optional)'),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_productionDate != null ? DateFormat('MMM dd, yyyy').format(_productionDate!) : 'Select Date'),
                      const Icon(Icons.calendar_month, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Mileage
              TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Service Mileage (km)', border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final mileage = int.tryParse(value);
                  if (mileage == null || mileage < 0) return 'Must be a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Cost
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cost (EGP)', border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final cost = double.tryParse(value);
                  if (cost == null || cost < 0) return 'Must be a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Custom Interval
              TextFormField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Next Change Interval (km) [Optional]',
                  hintText: 'e.g. 10000',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 16),
              
              // Center Name
              TextFormField(
                controller: _centerNameController,
                decoration: const InputDecoration(labelText: 'Service Center Name', border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (value.trim().length < 3) return 'Name must be at least 3 characters';
                  if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return 'Name must contain letters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
              ),
              const SizedBox(height: 32),
              
              // Submit
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.text, strokeWidth: 2))
                    : const Text('Save Record', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
