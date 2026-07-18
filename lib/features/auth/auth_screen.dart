import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/access_code_helper.dart';
import '../home/home_screen.dart';
import '../../core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _accessCodeHelper = AccessCodeHelper();
  bool _hasAccessCode = false;
  String _errorMessage = '';

  // Form keys and controllers for inline unlock form
  final _formKeyUnlock = GlobalKey<FormState>();
  final _unlockController = TextEditingController();
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

  @override
  void dispose() {
    _unlockController.dispose();
    super.dispose();
  }

  Future<void> _initializeAuthFlow() async {
    await _loadAccessCodeStatus();
    if (!mounted) return;

    setState(() {
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
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
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
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                      color: AppTheme.textPrimary.withOpacity(0.9),
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 80),

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
                        // Inline unlock form or set code button
                        if (_hasAccessCode)
                          // Unlock form (inline)
                          Form(
                            key: _formKeyUnlock,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _unlockController,
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: true,
                                  maxLength: 8,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[A-Za-z0-9]')),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'Access code',
                                    hintText: '4 to 8 letters or numbers',
                                  ),
                                  validator: _validateAccessCode,
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () async {
                                    if (!_formKeyUnlock.currentState!
                                        .validate()) return;
                                    final isValid =
                                        await _accessCodeHelper.verifyAccessCode(
                                          _normalizeAccessCode(
                                              _unlockController.text),
                                    );
                                    if (!mounted) return;
                                    if (!isValid) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content:
                                                  Text('Incorrect access code.')));
                                      return;
                                    }
                                    _navigateToHome();
                                  },
                                  child: const Text('Unlock'),
                                ),
                              ],
                            ),
                          )
                        else
                          // Button to set access code (opens dialog)
                          FilledButton(
                            onPressed: _promptSetAccessCode,
                            child: const Text('Set Access Code'),
                            style: FilledButton.styleFrom(
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