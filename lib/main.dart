import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_settings_helper.dart';
import 'core/utils/encryption_helper.dart';
import 'features/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize encryption
  await EncryptionHelper().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Legacy Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppEntryGate(),
    );
  }
}

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  final _appSettings = AppSettingsHelper();
  bool _isLoading = true;
  bool _showDisclaimer = false;

  @override
  void initState() {
    super.initState();
    _loadDisclaimerStatus();
  }

  Future<void> _loadDisclaimerStatus() async {
    final accepted = await _appSettings.hasAcceptedDisclaimer();
    if (!mounted) return;
    setState(() {
      _showDisclaimer = !accepted;
      _isLoading = false;
    });
  }

  Future<void> _agreeDisclaimer() async {
    await _appSettings.saveDisclaimerAccepted(true);
    if (!mounted) return;
    setState(() {
      _showDisclaimer = false;
    });
  }

  void _denyDisclaimer() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_showDisclaimer) {
      return const AuthScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Disclaimer',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'We are not responsible if your data gets leaked. '
                        'This is not a secure app and is for tracking purposes only.',
                        style: TextStyle(fontSize: 15, height: 1.45),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _denyDisclaimer,
                              child: const Text('Deny'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _agreeDisclaimer,
                              child: const Text('Agree'),
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
        ),
      ),
    );
  }
}
