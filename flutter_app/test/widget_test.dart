import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/services.dart';

void main() {
  test('InputSanitizer strips basic script-like content', () {
    final cleaned = InputSanitizer.cleanText(
      '<script>alert(1)</script> Best Pasta Ever',
      maxLength: 80,
    );

    expect(cleaned.contains('<script>'), isFalse);
    expect(cleaned.contains('javascript:'), isFalse);
    expect(cleaned.contains('Best Pasta Ever'), isTrue);
  });
}
