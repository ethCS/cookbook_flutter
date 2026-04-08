import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientItem {
  const IngredientItem({required this.name, required this.measure});

  final String name;
  final String measure;
}

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.area,
    required this.instructions,
    required this.ingredients,
    this.sourceUrl,
    this.youtubeUrl,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String area;
  final String instructions;
  final List<IngredientItem> ingredients;
  final String? sourceUrl;
  final String? youtubeUrl;

  factory Meal.fromApi(Map<String, dynamic> json) {
    final ingredients = <IngredientItem>[];
    for (var i = 1; i <= 20; i++) {
      final ingredient = (json['strIngredient$i'] ?? '').toString().trim();
      final measure = (json['strMeasure$i'] ?? '').toString().trim();
      if (ingredient.isNotEmpty) {
        ingredients.add(IngredientItem(name: ingredient, measure: measure));
      }
    }

    return Meal(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? 'Untitled recipe').toString(),
      imageUrl: (json['strMealThumb'] ?? '').toString(),
      category: (json['strCategory'] ?? '').toString(),
      area: (json['strArea'] ?? '').toString(),
      instructions: (json['strInstructions'] ?? '').toString(),
      ingredients: ingredients,
      sourceUrl: (json['strSource'] ?? '').toString().isEmpty
          ? null
          : json['strSource'].toString(),
      youtubeUrl: (json['strYoutube'] ?? '').toString().isEmpty
          ? null
          : json['strYoutube'].toString(),
    );
  }

  factory Meal.fromFavorite(Map<String, dynamic> json) {
    return Meal(
      id: (json['recipeId'] ?? '').toString(),
      name: (json['title'] ?? 'Saved recipe').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      area: '',
      instructions: '',
      ingredients: const [],
      sourceUrl: null,
      youtubeUrl: null,
    );
  }
}

class SearchArguments {
  const SearchArguments({this.query, this.category});

  final String? query;
  final String? category;
}

class CustomRecipe {
  const CustomRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    required this.prepTime,
    required this.servings,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final String instructions;
  final List<String> tags;
  final int? prepTime;
  final int? servings;
  final Timestamp? createdAt;

  factory CustomRecipe.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CustomRecipe(
      id: doc.id,
      title: (data['title'] ?? 'Untitled').toString(),
      description: (data['description'] ?? '').toString(),
      ingredients: ((data['ingredients'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      instructions: (data['instructions'] ?? '').toString(),
      tags: ((data['tags'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(),
      prepTime: data['prepTime'] is int ? data['prepTime'] as int : null,
      servings: data['servings'] is int ? data['servings'] as int : null,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
