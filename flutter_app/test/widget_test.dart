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

  test('InputSanitizer removes common XSS payload fragments', () {
    final cleaned = InputSanitizer.cleanText(
      '<img src=x onerror=alert(1)> javascript:alert(1) data:text/html,boom',
      maxLength: 120,
    );

    expect(cleaned.toLowerCase().contains('onerror='), isFalse);
    expect(cleaned.toLowerCase().contains('javascript:'), isFalse);
    expect(cleaned.toLowerCase().contains('data:text/html'), isFalse);
    expect(cleaned.contains('<'), isFalse);
    expect(cleaned.contains('>'), isFalse);
  });

  test('InputSanitizer only allows safe web image URLs', () {
    expect(
      InputSanitizer.safeHttpUrl('https://www.themealdb.com/image.jpg'),
      'https://www.themealdb.com/image.jpg',
    );
    expect(InputSanitizer.safeHttpUrl('javascript:alert(1)'), isEmpty);
    expect(InputSanitizer.safeHttpUrl('data:text/html,<script>'), isEmpty);
  });
}
