import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../theme/app_colors.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  
  bool _isLoading = false;
  String? _carId;
  bool _isEditMode = false;

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
        }
      }
    }
  }
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final year = int.parse(_yearController.text.trim());
    final mileage = int.parse(_mileageController.text.trim());

    final provider = Provider.of<CarProvider>(context, listen: false);
    bool success;
    if (_isEditMode && _carId != null) {
      success = await provider.updateCar(_carId!, make, model, year, mileage);
    } else {
      success = await provider.addCar(make, model, year, mileage);
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditMode ? 'Vehicle updated successfully!' : 'Vehicle added successfully!'), backgroundColor: AppColors.accentDeep),
      );
      Navigator.pop(context); // Go back to dashboard/garage
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add vehicle. Please try again.')),
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
        title: Text(
          _isEditMode ? 'Edit Vehicle' : 'Add Vehicle',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VEHICLE DETAILS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1),
                      ),
                      const SizedBox(height: 24),

                      // MAKE
                      const Text(
                        'MAKE (e.g. Toyota, BMW)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _makeController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Toyota',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // MODEL
                      const Text(
                        'MODEL (e.g. Corolla, X5)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _modelController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Corolla',
                          prefixIcon: Icon(Icons.drive_eta_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // YEAR
                      const Text(
                        'YEAR',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          hintText: '2024',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final year = int.tryParse(value);
                          if (year == null || year < 1980 || year > DateTime.now().year + 1) {
                            return 'Enter a valid year (1980+)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // MILEAGE
                      const Text(
                        'CURRENT MILEAGE (km)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _mileageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '45000',
                          prefixIcon: Icon(Icons.speed_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          final mileage = int.tryParse(value);
                          if (mileage == null || mileage < 0) return 'Must be a valid positive number';
                          if (mileage > 999999) return 'Mileage seems too high';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.text, strokeWidth: 2))
                    : Text(_isEditMode ? 'Save Changes' : 'Register Vehicle', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
