import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  static final BiometricHelper _instance = BiometricHelper._internal();
  factory BiometricHelper() => _instance;
  BiometricHelper._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticate({
    String message = 'Authenticate to access your vault',
  }) async {
    try {
      final bool canAuthenticate = await canCheckBiometrics() || 
                                   await isDeviceSupported();
      
      if (!canAuthenticate) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: message,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
