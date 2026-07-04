import 'recipe.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }
}

class MealPlanEntry {
  final String id;
  final Recipe recipe;
  final DateTime date;
  final MealType mealType;

  MealPlanEntry({
    required this.id,
    required this.recipe,
    required this.date,
    required this.mealType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipe': recipe.toJson(),
        'date': date.toIso8601String(),
        'mealType': mealType.index,
      };

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'],
        recipe: Recipe.fromJson(json['recipe']),
        date: DateTime.parse(json['date']),
        mealType: MealType.values[json['mealType']],
      );
}

class ShoppingItem {
  final String id;
  final String name;
  bool isChecked;
  final String? recipeTitle;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.recipeTitle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isChecked': isChecked,
        'recipeTitle': recipeTitle,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'],
        name: json['name'],
        isChecked: json['isChecked'] ?? false,
        recipeTitle: json['recipeTitle'],
      );
}