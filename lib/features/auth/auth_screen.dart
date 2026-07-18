import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/access_code_helper.dart';
import '../../core/utils/biometric_helper.dart';
import '../home/home_screen.dart';
import '../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _biometricHelper = BiometricHelper();
  final _accessCodeHelper = AccessCodeHelper();
  bool _isAuthenticating = false;
  bool _hasAccessCode = false;
  String _errorMessage = '';

  static final RegExp _accessCodePattern = RegExp(r'^[A-Za-z0-9]{4,8}$');

  String _normalizeAccessCode(String code) => code.trim().toUpperCase();

  String? _validateAccessCode(String? value) {
    final code = _normalizeAccessCode(value ?? '');
    if (!_accessCodePattern.hasMatch(code)) {
      return 'Enter 4 to 8 letters or numbers.';
    }
                    return null;
  }
  @override
  void initState() {
    super.initState();
    _initializeAuthFlow();
  }

  Future<void> _initializeAuthFlow() async {
    await _loadAccessCodeStatus();
    if (!mounted) return;

    if (AppConstants.enableBiometricAuth) {
      _authenticate();
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _errorMessage = _hasAccessCode
          ? 'Use access code to continue.'
          : 'Set an access code to continue.';
    });
  }

  Future<void> _loadAccessCodeStatus() async {
    final hasCode = await _accessCodeHelper.hasAccessCode();
    if (!mounted) return;
    setState(() => _hasAccessCode = hasCode);
  }

  Future<void> _authenticate() async {
    if (!AppConstants.enableBiometricAuth) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = _hasAccessCode
            ? 'Use access code to continue.'
            : 'Set an access code to continue.';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    try {
      final authenticated = await _biometricHelper.authenticate(
        message: 'Authenticate to access your Digital Legacy Vault',
    );

      if (authenticated) {
        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = _hasAccessCode
              ? 'Authentication failed. Try again or use access code.'
              : 'Authentication failed. Try again or set an access code.';
          _isAuthenticating = false;
        });
  }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isAuthenticating = false;
      });
}
  }

  Future<void> _promptAccessCode() async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final unlock = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter Access Code'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: codeController,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              maxLength: 8,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Access code',
                hintText: '4 to 8 letters or numbers',
              ),
              validator: _validateAccessCode,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final isValid = await _accessCodeHelper.verifyAccessCode(
                  _normalizeAccessCode(codeController.text),
                );
                if (!dialogContext.mounted) return;
                if (!isValid) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Incorrect access code.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );

    if (unlock == true) {
      _navigateToHome();
    }
  }

  Future<void> _promptSetAccessCode() async {
    final codeController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set Access Code'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'New access code',
                    hintText: '4 to 8 letters or numbers',
                  ),
                  validator: _validateAccessCode,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Confirm access code',
                    hintText: 'Re-enter code',
                  ),
                  validator: (value) {
                    final confirm = _normalizeAccessCode(value ?? '');
                    final newCode = _normalizeAccessCode(codeController.text);
                    if (confirm != newCode) {
                      return 'Codes do not match.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await _accessCodeHelper.saveAccessCode(
                  _normalizeAccessCode(codeController.text),
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      await _loadAccessCodeStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access code saved. You can use it to unlock.'),
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon with glow effect
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // App Name
                  Text(
                    'Legacy Vault',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      letterSpacing: -1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Secure your digital legacy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary.withOpacity(0.9),
                                                  fontSize: 16,
                                            letterSpacing: 0.2,
              ),
            ),
                  const SizedBox(height: 80),

                  // Authentication Status
                  if (_isAuthenticating)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
        ),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                            ),
                              strokeWidth: 3,
      ),
                          ),
                                  ),
                        const SizedBox(height: 24),
                        Text(
                          'Authenticating...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                              ),
                              ),
                      ],
                            ),
                  // Error Message
                  if (_errorMessage.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.white,
                                size: 24,
                    ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
              ),
            ),
          ),
                            ],
        ),
      ),
                        const SizedBox(height: 24),
                        if (AppConstants.enableBiometricAuth)
                          ElevatedButton.icon(
                            onPressed: _authenticate,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF667EEA),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        if (AppConstants.enableBiometricAuth)
                          const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _hasAccessCode
                              ? _promptAccessCode
                              : _promptSetAccessCode,
                          icon: Icon(
                            _hasAccessCode
                                ? Icons.pin_outlined
                                : Icons.add_moderator_outlined,
                          ),
                          label: Text(
                            _hasAccessCode
                                ? 'Use Access Code'
                                : 'Set Access Code',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.65),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

