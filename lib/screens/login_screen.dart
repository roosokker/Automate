import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _selectedCountryCode = '+20';
  bool _otpSent = false;
  bool _isNewUser = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'MyCar ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Text(
                      'Egypt',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'PREMIUM FLEET MANAGEMENT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textFaint,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _otpSent ? 'Enter the 6-digit code sent to your phone' : 'Sign in securely with your phone number',
                          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        
                        if (!_otpSent) ...[
                          const Text(
                            'PHONE NUMBER',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '100 000 0000',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCountryCode,
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                                    items: [
                                      {'code': '+20', 'name': '🇪🇬 +20'},
                                      {'code': '+971', 'name': '🇦🇪 +971'},
                                      {'code': '+966', 'name': '🇸🇦 +966'},
                                      {'code': '+1', 'name': '🇺🇸 +1'},
                                      {'code': '+44', 'name': '🇬🇧 +44'},
                                    ]
                                        .map((country) => DropdownMenuItem(
                                              value: country['code'],
                                              child: Text(country['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedCountryCode = value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your phone number';
                              if (!RegExp(r'^\d{9,15}$').hasMatch(value)) return 'Enter a valid phone number (9-15 digits)';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '6-DIGIT OTP CODE',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _otpSent = false),
                                child: Text(
                                  'Change Phone?',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              hintText: '000000',
                              prefixIcon: Icon(Icons.password_outlined),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (value == null || value.length != 6) return 'Please enter a 6-digit code';
                              if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Code must contain only digits';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_isNewUser) ...[
                            const Text(
                              'FULL NAME',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fullNameController,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'John Doe',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your full name';
                                if (value.trim().length < 3) return 'Name must be at least 3 characters';
                                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'Name can only contain letters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _isLoading = true);
                                      
                                      if (!_otpSent) {
                                        // Step 1: Request OTP
                                        String phoneInput = _phoneController.text.trim();
                                        // Remove leading 0 if present (common in Egypt e.g. 0100...)
                                        if (phoneInput.startsWith('0')) {
                                          phoneInput = phoneInput.substring(1);
                                        }
                                        final fullPhone = '$_selectedCountryCode$phoneInput';
                                        
                                        final result = await AuthService().requestOtp(fullPhone);
                                        
                                        if (!context.mounted) return;
                                        setState(() => _isLoading = false);
                                        
                                        if (result['success'] == true) {
                                          setState(() {
                                            _otpSent = true;
                                            _isNewUser = result['isNewUser'] == true;
                                            if (result['devOtp'] != null) {
                                              _otpController.text = result['devOtp'];
                                            }
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('OTP Code sent!'), backgroundColor: AppColors.accentDeep),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed: ${result['error']}')),
                                          );
                                        }
                                      } else {
                                        // Step 2: Verify OTP
                                        String phoneInput = _phoneController.text.trim();
                                        if (phoneInput.startsWith('0')) {
                                          phoneInput = phoneInput.substring(1);
                                        }
                                        final fullPhone = '$_selectedCountryCode$phoneInput';
                                        
                                        final error = await AuthService().verifyOtp(
                                          fullPhone, 
                                          _otpController.text,
                                          fullName: _isNewUser ? _fullNameController.text.trim() : null,
                                        );
                                        
                                        if (!context.mounted) return;
                                        setState(() => _isLoading = false);
                                        
                                        if (error == null) {
                                          Navigator.pushReplacementNamed(context, '/main');
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Verification failed: $error')),
                                          );
                                        }
                                      }
                                    }
                                  },
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.text, strokeWidth: 2))
                                : const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Or continue with divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(fontSize: 10, color: AppColors.textFaint, letterSpacing: 1),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.g_mobiledata, color: AppColors.danger, size: 24),
                                label: const Text('Google', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.normal)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.lineStrong),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.apple, color: AppColors.text, size: 20),
                                label: const Text('Apple', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.normal)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.lineStrong),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Footer
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Don\'t have an account? ', style: TextStyle(color: AppColors.textMuted)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                      child: Text(
                        'Create Account',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'SYSTEM V4.2.0-ALPHA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
