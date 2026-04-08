import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _configureAppCheck();
  runApp(const CookbookApp());
}

Future<void> _configureAppCheck() async {
  try {
    const siteKey = String.fromEnvironment(
      'RECAPTCHA_ENTERPRISE_KEY',
      defaultValue: '6Le4ia0sAAAAAG9N9tnFPwoo49eKjASl3d4XLhvn',
    );

    if (kIsWeb && siteKey.isEmpty) {
      debugPrint(
        'App Check web provider is not active yet. '
        'Pass RECAPTCHA_ENTERPRISE_KEY during build/deploy to enable reCAPTCHA Enterprise.',
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      providerWeb: kIsWeb ? ReCaptchaEnterpriseProvider(siteKey) : null,
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (error) {
    debugPrint('App Check setup skipped: $error');
  }
}
