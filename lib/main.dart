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

  static const List<String> _disclaimerLines = [
    '## Important Security and Use Disclaimer',
    'This application is intended only as a personal organizational tool for recording general information about assets, accounts, property, documents, and related instructions.',
    '',
    '### Limited Security',
    'This application is protected only by a user-created PIN. PIN protection is intended to discourage casual access, but it does not provide a guarantee of security. The application may not protect your information if your device is lost, stolen, shared, unlocked, rooted, jailbroken, infected with malicious software, accessed through device backups, or otherwise compromised.',
    '',
    '**Do not store highly sensitive or confidential information in this application**, including:',
    '',
    '- Passwords or usernames',
    '- Debit or credit card PINs',
    '- Full bank account or routing numbers',
    '- Social Security numbers',
    '- Authentication or verification codes',
    '- Cryptocurrency seed phrases or private keys',
    '- Copies of identity documents',
    '- Security-question answers',
    '- Any information that could allow another person to access or take control of your financial accounts',
    'Where possible, record only general descriptions, institution names, account types, partial account numbers, contact information, and the physical location of important documents.',
    '',
    '### Local Device Storage',
    'Information entered into the application is stored locally on your device. The developer does not operate a cloud storage service for your records and does not receive, access, monitor, recover, or maintain the information you enter.',
    '',
    'You are solely responsible for:',
    '',
    '- Protecting access to your device and PIN',
    '- Deciding what information to enter',
    '- Maintaining secure backups, where available',
    '- Preventing unauthorized access to exported or shared files',
    '- Confirming that stored information remains accurate and current',
    'Deleting the application, losing your device, resetting your device, clearing application data, or forgetting required access information may result in permanent data loss.',
    '',
    '### No Guarantee',
    'No application, device, PIN, or security measure can guarantee complete protection against unauthorized access, data loss, theft, malware, operating-system vulnerabilities, device failure, or user error.',
    '',
    'You use this application and store information in it entirely at your own risk.',
    '',
    '### No Professional Advice',
    'This application does not provide legal, financial, tax, investment, insurance, cybersecurity, or estate-planning advice. It does not create or replace a will, trust, deed, power of attorney, beneficiary designation, contract, or other legally valid document.',
    '',
    'Consult qualified professionals regarding your legal, financial, tax, security, and estate-planning needs.',
    '',
    '### Limitation of Responsibility',
    'To the maximum extent permitted by applicable law, the developer and distributor of this application will not be responsible for unauthorized access, disclosure, theft, misuse, corruption, deletion, loss, or inability to recover information stored in the application, or for any financial, legal, personal, incidental, indirect, or consequential loss arising from use of the application.',
    '',
    'By continuing, you acknowledge that you understand the application provides only limited PIN protection, that you have been advised not to store sensitive information, and that you accept the risks associated with storing information locally on your device.',
    '',
    '**I understand and accept**',
  ];
  
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

  Widget _buildDisclaimerLine(String line) {
    if (line.isEmpty) {
      return const SizedBox(height: 8);
    }

    final isBoldLine =
        line.startsWith('##') || line.startsWith('###') || line.contains('**');
    final normalized = line
        .replaceFirst(RegExp(r'^###\s*'), '')
        .replaceFirst(RegExp(r'^##\s*'), '')
        .replaceAll('**', '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        normalized,
        style: TextStyle(
          fontSize: 15,
          height: 1.45,
          fontWeight: isBoldLine ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

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
            child: SizedBox(
              width: screenSize.width * 0.8,
              height: screenSize.height * 0.8,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
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
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _disclaimerLines
                                .map(_buildDisclaimerLine)
                                .toList(),
                          ),
                        ),
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
                              child: const Text('I Agree'),
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
