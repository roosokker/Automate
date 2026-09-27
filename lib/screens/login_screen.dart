import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/phosphor_icons.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ui.dart';
import 'welcome_screen.dart';

enum _Step { phone, otp, name, welcome }

/// Phone number → SMS code → (new number) name, or (existing) welcome back.
/// Uses [AuthService.requestOtp] / [AuthService.verifyOtp] exactly as before.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _selectedCountryCode = '+20';
  _Step _step = _Step.phone;
  bool _isNewUser = false;
  bool _isLoading = false;
  String _code = '';
  String? _devOtp;
  String? _error;
  int _timer = 30;
  Timer? _ticker;

  // Welcome-back sync state
  String? _userName;
  int _syncStage = 0;
  (int, int, int)? _syncCounts;

  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  static const _countries = [
    {'code': '+20', 'flag': 'EG', 'name': '🇪🇬 +20'},
    {'code': '+971', 'flag': 'AE', 'name': '🇦🇪 +971'},
    {'code': '+966', 'flag': 'SA', 'name': '🇸🇦 +966'},
    {'code': '+1', 'flag': 'US', 'name': '🇺🇸 +1'},
    {'code': '+44', 'flag': 'GB', 'name': '🇬🇧 +44'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ticker?.cancel();
    _shake.dispose();
    super.dispose();
  }

  String get _fullPhone {
    String phoneInput = _phoneController.text.trim();
    // Remove leading 0 if present (common in Egypt e.g. 0100...)
    if (phoneInput.startsWith('0')) {
      phoneInput = phoneInput.substring(1);
    }
    return '$_selectedCountryCode$phoneInput';
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^\d{9,15}$').hasMatch(value)) return 'Enter a valid phone number (9-15 digits)';
    return null;
  }

  String? _validateName(String value) {
    if (value.isEmpty) return 'Please enter your full name';
    if (value.trim().length < 3) return 'Name must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'Name can only contain letters';
    return null;
  }

  void _fail(String message) {
    setState(() => _error = message);
    _shake.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  void _startTimer() {
    _ticker?.cancel();
    setState(() => _timer = 30);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_timer <= 0) return t.cancel();
      setState(() => _timer--);
    });
  }

  // Step 1: Request OTP
  Future<void> _sendCode() async {
    final err = _validatePhone(_phoneController.text.trim());
    if (err != null) return _fail(err);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AuthService().requestOtp(_fullPhone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _step = _Step.otp;
        _isNewUser = result['isNewUser'] == true;
        _code = '';
        _devOtp = result['devOtp']?.toString();
      });
      _startTimer();
      showAmToast(context, 'OTP Code sent!', icon: PhosphorIconsFill.chatCircleText);
    } else {
      _fail('Failed: ${result['error']}');
    }
  }

  void _press(String k) {
    if (_isLoading) return;
    setState(() {
      _error = null;
      if (k == 'del') {
        if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
      } else if (_code.length < 6) {
        _code += k;
      }
    });
    if (_code.length == 6) _onCodeComplete();
  }

  void _onCodeComplete() {
    if (!RegExp(r'^\d{6}$').hasMatch(_code)) return _fail('Code must contain only digits');
    if (_isNewUser) {
      setState(() => _step = _Step.name);
    } else {
      _verify();
    }
  }

  // Step 2: Verify OTP
  Future<void> _verify() async {
    String? fullName;
    if (_isNewUser) {
      fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      final err = _validateName(fullName);
      if (err != null) return _fail(err);
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final error = await AuthService().verifyOtp(
      _fullPhone,
      _code,
      fullName: _isNewUser ? fullName : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      if (_isNewUser) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        _ticker?.cancel();
        setState(() => _step = _Step.welcome);
        _runSync();
      }
    } else {
      setState(() {
        _step = _Step.otp;
        _code = '';
      });
      _fail('Verification failed: $error');
    }
  }

  Future<void> _runSync() async {
    final provider = Provider.of<CarProvider>(context, listen: false);
    AuthService().fetchProfile().then((user) {
      if (mounted) setState(() => _userName = user?['fullName'] as String?);
    });
    await provider.fetchCars();
    await provider.fetchAllRecords();
    if (!mounted) return;
    final reminders = provider.cars.fold<int>(0, (sum, c) {
      final s = provider.getSummary(c.id);
      return sum + (s == null ? 0 : s.upcoming.length + s.due.length + s.overdue.length);
    });
    _syncCounts = (provider.cars.length, provider.allExpenses.length, reminders);
    for (var i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _syncStage = i);
    }
  }

  void _back() {
    if (_isLoading) return;
    switch (_step) {
      case _Step.phone:
        Navigator.maybePop(context);
        break;
      case _Step.otp:
        _ticker?.cancel();
        setState(() {
          _step = _Step.phone;
          _error = null;
        });
        break;
      case _Step.name:
        setState(() {
          _step = _Step.otp;
          _code = '';
          _error = null;
        });
        break;
      case _Step.welcome:
        break;
    }
  }

  void _pickCountry() {
    showAmSheet(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetTitle('Country code'),
          const SizedBox(height: 12),
          ..._countries.map((c) {
            final sel = c['code'] == _selectedCountryCode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AmChoice(
                label: c['name']!,
                selected: sel,
                height: 50,
                radius: 14,
                onTap: () {
                  setState(() => _selectedCountryCode = c['code']!);
                  Navigator.pop(context);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  String get _flag => _countries.firstWhere((c) => c['code'] == _selectedCountryCode)['flag']!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 22),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        opacity: _step == _Step.welcome ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: AmBackButton(onPressed: _back),
                      ),
                      const Spacer(),
                      const BrandMark(size: 24),
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
                    child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case _Step.phone:
        return _phoneStep();
      case _Step.otp:
        return _otpStep();
      case _Step.name:
        return _nameStep();
      case _Step.welcome:
        return _welcomeStep();
    }
  }

  Widget _shaking(Widget child) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = t == 0 || t == 1 ? 0.0 : math.sin(t * math.pi * 6) * 7 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }

  Widget _errorLine() {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.warningCircle, size: 16, color: AppColors.danger),
          const SizedBox(width: 6),
          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.danger))),
        ],
      ),
    );
  }

  Widget _scrollable(List<Widget> top, List<Widget> bottom) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...top, const Spacer(), const SizedBox(height: 24), ...bottom, const SizedBox(height: 16)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneStep() {
    final valid = _validatePhone(_phoneController.text.trim()) == null;
    return _scrollable(
      [
        const Align(alignment: Alignment.centerLeft, child: _PingIcon()),
        const SizedBox(height: 22),
        const Text('Your phone number', style: AmText.h2),
        const SizedBox(height: 8),
        const Text("We'll text you a 6-digit code. One number, one account — your cars and history stay with it.", style: AmText.body),
        const SizedBox(height: 24),
        _shaking(
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _error != null ? AppColors.danger : (valid ? AppColors.accent : AppColors.neutral700)),
              boxShadow: valid ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.18), blurRadius: 24)] : null,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickCountry,
                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.only(right: 12),
                    decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.line))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.neutral800, borderRadius: BorderRadius.circular(4)),
                          child: Text(_flag, style: const TextStyle(fontSize: 11, letterSpacing: 0.7, color: AppColors.neutral200)),
                        ),
                        const SizedBox(width: 6),
                        Text(_selectedCountryCode, style: const TextStyle(fontSize: 16, color: AppColors.neutral200)),
                        const SizedBox(width: 2),
                        const Icon(PhosphorIconsRegular.caretDown, size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    cursorColor: AppColors.accent,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _sendCode(),
                    style: const TextStyle(fontSize: 22, letterSpacing: 0.4, color: AppColors.text, fontFeatures: tabular),
                    decoration: const InputDecoration(
                      hintText: '100 000 0000',
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: valid ? 1 : 0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  child: const Icon(PhosphorIconsFill.checkCircle, size: 22, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
        _errorLine(),
      ],
      [
        AmButton(
          label: 'Send code',
          trailingIcon: PhosphorIconsRegular.chatCircleDots,
          loading: _isLoading,
          onPressed: _sendCode,
        ),
        const SizedBox(height: 12),
        const Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.textFaint),
        ),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Enter the code', style: AmText.h2),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Sent by SMS to ', style: AmText.body),
            Text(_fullPhone, style: const TextStyle(fontSize: 14, color: AppColors.text, fontFeatures: tabular)),
            const SizedBox(width: 4),
            AmLink('Edit', onTap: _back),
          ],
        ),
        const SizedBox(height: 20),
        _shaking(
          Row(
            children: List.generate(6, (i) {
              final filled = i < _code.length;
              final active = i == _code.length && !_isLoading;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _error != null ? AppColors.danger : (active ? AppColors.accent : (filled ? AppColors.accent700 : AppColors.neutral800)),
                        width: active ? 1.5 : 1,
                      ),
                      boxShadow: active ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 16)] : null,
                    ),
                    child: filled
                        ? Text(_code[i], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: AppColors.text, fontFeatures: tabular))
                        : (active ? const _BlinkCaret() : null),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(
          height: 36,
          child: _isLoading
              ? const Row(children: [AmSpinner(size: 14), SizedBox(width: 8), Text('Verifying…', style: TextStyle(fontSize: 13, color: AppColors.accent300))])
              : _errorLine(),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _timer > 0
              ? Text('Resend code in 0:${_timer.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, color: AppColors.textFaint, fontFeatures: tabular))
              : AmLink('Resend code', icon: PhosphorIconsRegular.arrowClockwise, onTap: _isLoading ? null : _sendCode),
        ),
        const Spacer(),
        if (_devOtp != null)
          Center(
            child: Rise(
              delayMs: 600,
              child: Pressable(
                onTap: () {
                  setState(() => _code = '');
                  for (final d in _devOtp!.split('')) {
                    _press(d);
                  }
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.neutral800, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.neutral700)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsFill.chatCircleText, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      const Text('From Messages ', style: TextStyle(fontSize: 13, color: AppColors.neutral200)),
                      Text(_devOtp!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 1.6, color: AppColors.text)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        _Keypad(onKey: _press),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _nameStep() {
    return _scrollable(
      [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            decoration: BoxDecoration(color: AppColors.accentTint, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accentDeep)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsFill.sealCheck, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(_fullPhone, style: const TextStyle(fontSize: 12.5, color: AppColors.accent200)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('What should we call you?', style: AmText.h2),
        const SizedBox(height: 8),
        const Text("This number is new to AutoMate — let's create your account.", style: AmText.body),
        const SizedBox(height: 24),
        _shaking(Column(
          children: [
            AmField(
              label: 'First name',
              controller: _firstNameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 14),
            AmField(
              label: 'Last name',
              controller: _lastNameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
            ),
          ],
        )),
        _errorLine(),
        const SizedBox(height: 20),
        AmCard(
          child: Row(
            children: [
              const IconTile(icon: PhosphorIconsRegular.fingerprint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your AutoMate ID', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    Text(_fullPhone, style: const TextStyle(fontSize: 15, color: AppColors.text, fontFeatures: tabular)),
                  ],
                ),
              ),
              const Icon(PhosphorIconsRegular.lockSimple, size: 18, color: AppColors.textFaint),
            ],
          ),
        ),
      ],
      [
        AmButton(
          label: 'Create account',
          trailingIcon: PhosphorIconsRegular.arrowRight,
          loading: _isLoading,
          onPressed: _firstNameController.text.trim().isEmpty ? null : _verify,
        ),
      ],
    );
  }

  Widget _welcomeStep() {
    final name = _userName ?? '';
    final first = name.trim().split(RegExp(r'\s+')).first;
    final done = _syncStage >= 3;
    final rows = _syncCounts == null
        ? const <String>[]
        : [
            '${_syncCounts!.$1} ${_syncCounts!.$1 == 1 ? 'vehicle' : 'vehicles'}',
            '${_syncCounts!.$2} expenses',
            '${_syncCounts!.$3} active reminders',
          ];
    return _scrollable(
      [
        Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 24),
              child: InitialsAvatar(initials: initialsOf(name), size: 86, ring: 2, glow: true),
            ),
          ),
        ),
        Rise(delayMs: 200, child: Text(first.isEmpty ? 'Welcome back' : 'Welcome back, $first', style: AmText.h2)),
        const SizedBox(height: 8),
        Rise(delayMs: 300, child: Text('We found your account on $_fullPhone', style: AmText.body)),
        const SizedBox(height: 26),
        Rise(
          delayMs: 400,
          child: AmCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    done ? const Icon(PhosphorIconsFill.cloudCheck, size: 16, color: AppColors.accent) : const AmSpinner(size: 14),
                    const SizedBox(width: 8),
                    Text(done ? 'All synced' : 'Syncing your garage…', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
                for (var i = 0; i < 3; i++) ...[
                  const SizedBox(height: 14),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _syncStage > i ? 1 : 0.35,
                    child: Row(
                      children: [
                        AnimatedScale(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          scale: _syncStage > i ? 1 : 0.6,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: _syncStage > i ? AppColors.accent600 : AppColors.neutral800),
                            child: const Icon(PhosphorIconsRegular.check, size: 13, color: AppColors.accent100),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(i < rows.length ? rows[i] : ['Vehicles', 'Expenses', 'Reminders'][i], style: const TextStyle(fontSize: 15, color: AppColors.text)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      [
        AmButton(
          label: 'Go to dashboard',
          trailingIcon: PhosphorIconsRegular.arrowRight,
          glow: done,
          onPressed: done ? () => Navigator.pushReplacementNamed(context, '/main') : null,
        ),
      ],
    );
  }
}

class _PingIcon extends StatefulWidget {
  const _PingIcon();

  @override
  State<_PingIcon> createState() => _PingIconState();
}

class _PingIconState extends State<_PingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeOut.transform(_c.value);
              return Transform.scale(
                scale: 0.6 + 2.0 * t,
                child: Opacity(
                  opacity: (0.35 * (1 - t)).clamp(0, 1),
                  child: Container(decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(20))),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(begin: Alignment(-0.5, -1), end: Alignment(0.5, 1), colors: [AppColors.accentDeep, AppColors.neutral900]),
              border: Border.all(color: AppColors.accent600),
              boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 30)],
            ),
            child: const Center(child: Icon(PhosphorIconsRegular.deviceMobileSpeaker, size: 30, color: AppColors.accent200)),
          ),
        ],
      ),
    );
  }
}

class _BlinkCaret extends StatefulWidget {
  const _BlinkCaret();

  @override
  State<_BlinkCaret> createState() => _BlinkCaretState();
}

class _BlinkCaretState extends State<_BlinkCaret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: _c.value < 0.5 ? 1 : 0,
        child: Container(width: 2, height: 26, color: AppColors.accent),
      ),
    );
  }
}

/// On-screen numeric keypad (1–9, blank, 0, delete).
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  const _Keypad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 2.3,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox.shrink();
        return _Key(label: k, onTap: () => onKey(k));
      }).toList(),
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _Key({required this.label, required this.onTap});

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _down ? AppColors.accent.withValues(alpha: 0.25) : AppColors.text.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.label == 'del'
              ? const Icon(PhosphorIconsRegular.backspace, size: 22, color: AppColors.text)
              : Text(widget.label, style: const TextStyle(fontSize: 24, color: AppColors.text)),
        ),
      ),
    );
  }
}
