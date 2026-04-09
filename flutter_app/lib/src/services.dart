import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class MealDbService {
  MealDbService._();

  static final MealDbService instance = MealDbService._();
  static const _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const _ttl = Duration(minutes: 15);

  final http.Client _client = http.Client();
  final Map<String, _CacheEntry<dynamic>> _cache = {};

  Future<List<Meal>> search(String query) {
    final cleaned = query.trim();
    return _cached('search:$cleaned', () async {
      final data = await _getJson(
        '$_baseUrl/search.php?s=${Uri.encodeComponent(cleaned)}',
      );
      final meals = (data['meals'] as List?) ?? const [];
      return meals
          .map((meal) => Meal.fromApi(Map<String, dynamic>.from(meal as Map)))
          .toList();
    });
  }

  Future<List<String>> categories() {
    return _cached('categories', () async {
      final data = await _getJson('$_baseUrl/categories.php');
      final categories = (data['categories'] as List?) ?? const [];
      return categories
          .map((item) => ((item as Map)['strCategory'] ?? '').toString())
          .where((item) => item.isNotEmpty)
          .toList();
    });
  }

  Future<List<Meal>> byCategory(String category) {
    return _cached('category:$category', () async {
      final data = await _getJson(
        '$_baseUrl/filter.php?c=${Uri.encodeComponent(category)}',
      );
      final meals = (data['meals'] as List?) ?? const [];
      return meals
          .map((meal) => Meal.fromApi(Map<String, dynamic>.from(meal as Map)))
          .toList();
    });
  }

  Future<Meal?> mealById(String id) {
    return _cached('meal:$id', () async {
      final data = await _getJson(
        '$_baseUrl/lookup.php?i=${Uri.encodeComponent(id)}',
      );
      final meals = (data['meals'] as List?) ?? const [];
      if (meals.isEmpty) return null;
      return Meal.fromApi(Map<String, dynamic>.from(meals.first as Map));
    });
  }

  Future<List<Meal>> randomMeals({int count = 8}) {
    return _cached('random:$count', () async {
      final seen = <String>{};
      final results = <Meal>[];

      while (results.length < count) {
        final remaining = count - results.length;
        final batchSize = remaining == 1 ? 2 : remaining * 2;
        final batch = await Future.wait(
          List.generate(batchSize, (_) => _fetchRandomMeal()),
        );

        for (final meal in batch) {
          if (seen.add(meal.id)) {
            results.add(meal);
            if (results.length == count) {
              break;
            }
          }
        }
      }

      return results;
    });
  }

  void clearRandomCache() => _cache.remove('random:8');

  Future<Meal> _fetchRandomMeal() async {
    final data = await _getJson('$_baseUrl/random.php');
    final meals = (data['meals'] as List?) ?? const [];
    if (meals.isEmpty) {
      throw Exception('MealDB random recipe request returned no meals');
    }

    return Meal.fromApi(Map<String, dynamic>.from(meals.first as Map));
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('MealDB request failed (${response.statusCode})');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<T> _cached<T>(String key, Future<T> Function() loader) async {
    final entry = _cache[key];
    if (entry != null && entry.expiresAt.isAfter(DateTime.now())) {
      return entry.value as T;
    }

    final value = await loader();
    _cache[key] = _CacheEntry<T>(value, DateTime.now().add(_ttl));
    return value;
  }
}

class InputSanitizer {
  static final RegExp _htmlTagPattern = RegExp(
    r'<[^>]*>',
    caseSensitive: false,
    multiLine: true,
  );
  static final RegExp _dangerousSchemePattern = RegExp(
    r'(javascript\s*:|vbscript\s*:|data\s*:\s*text/html)',
    caseSensitive: false,
  );
  static final RegExp _eventHandlerPattern = RegExp(
    r'\bon[a-z]+\s*=',
    caseSensitive: false,
  );
  static final RegExp _controlCharsPattern = RegExp(r'[\u0000-\u001F\u007F]');
  static final RegExp _invalidUrlCharPattern = RegExp(r'''[\s<>"'`]''');

  static String cleanText(String input, {int maxLength = 120}) {
    var sanitized = _stripDangerousContent(input)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength).trim();
    }

    return sanitized;
  }

  static String cleanMultiline(String input, {int maxLength = 4000}) {
    var sanitized = _stripDangerousContent(input)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();

    sanitized = sanitized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');

    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength).trim();
    }

    return sanitized;
  }

  static String safeHttpUrl(String input, {bool allowHttp = false}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    if (_dangerousSchemePattern.hasMatch(trimmed) ||
        _eventHandlerPattern.hasMatch(trimmed) ||
        _invalidUrlCharPattern.hasMatch(trimmed)) {
      return '';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      return '';
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && !(allowHttp && scheme == 'http')) {
      return '';
    }

    return trimmed;
  }

  static List<String> splitLines(
    String input, {
    int maxItems = 25,
    int maxLength = 100,
  }) {
    return input
        .split(RegExp(r'\r?\n'))
        .map((line) => cleanText(line, maxLength: maxLength))
        .where((line) => line.isNotEmpty)
        .take(maxItems)
        .toList();
  }

  static List<String> splitTags(String input, {int maxItems = 8}) {
    return input
        .split(',')
        .map((tag) => cleanText(tag, maxLength: 20).toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .take(maxItems)
        .toList();
  }

  static String _stripDangerousContent(String input) {
    return input
        .replaceAll(_htmlTagPattern, ' ')
        .replaceAll(_dangerousSchemePattern, '')
        .replaceAll(_eventHandlerPattern, '')
        .replaceAll(_controlCharsPattern, ' ')
        .replaceAll(RegExp(r'[<>"`]'), '');
  }
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;
}
