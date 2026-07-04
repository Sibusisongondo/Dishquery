import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';

const String _apiKey = '65232507';
const String _apiBase = 'https://www.themealdb.com/api/json/v2/$_apiKey';

class RecipeProvider extends ChangeNotifier {
  List<Recipe> recipes = [];
  List<Recipe> favorites = [];
  List<Category> categories = [];
  List<String> areas = [];

  bool isLoading = true;
  bool isFetchingMore = false;
  bool canInfiniteScroll = true;
  String? error;
  String? selectedCategory;
  String? selectedArea;

  RecipeProvider() {
    loadFavorites();
    fetchInitialRecipes();
    fetchCategories();
    fetchAreas();
  }

  // --- Favorites ---
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('favorites');
      if (stored != null) {
        final List<dynamic> decoded = json.decode(stored);
        favorites = decoded.map((item) => Recipe.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'favorites', json.encode(favorites.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  void toggleFavorite(Recipe recipe) {
    final index = favorites.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      favorites.removeAt(index);
    } else {
      favorites.add(recipe);
    }
    saveFavorites();
    notifyListeners();
  }

  bool isFavorite(String id) => favorites.any((r) => r.id == id);

  // --- Initial & Random ---
  Future<void> fetchInitialRecipes() async {
    isLoading = true;
    error = null;
    selectedCategory = null;
    selectedArea = null;
    canInfiniteScroll = true;
    recipes.clear();
    notifyListeners();

    await fetchMoreRandomRecipes();

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMoreRandomRecipes() async {
    if (isFetchingMore) return;
    isFetchingMore = true;
    error = null;
    notifyListeners();

    try {
      final response =
          await http.get(Uri.parse('$_apiBase/randomselection.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final newMeals = (data['meals'] as List)
              .map((meal) => _formatMeal(meal))
              .toList();
          recipes.addAll(newMeals);
        }
      } else {
        error = 'Failed to load recipes.';
      }
    } catch (e) {
      error = 'Failed to load recipes. Please check your connection.';
      debugPrint('Error fetching random meals: $e');
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  // --- Search ---
  Future<void> searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      fetchInitialRecipes();
      return;
    }
    isLoading = true;
    error = null;
    selectedCategory = null;
    selectedArea = null;
    canInfiniteScroll = false;
    notifyListeners();

    try {
      final response =
          await http.get(Uri.parse('$_apiBase/search.php?s=${query.trim()}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          recipes =
              (data['meals'] as List).map((meal) => _formatMeal(meal)).toList();
        } else {
          recipes = [];
          error = 'No recipes found for "$query".';
        }
      } else {
        error = 'Failed to search recipes.';
      }
    } catch (e) {
      error = 'Failed to search recipes. Please try again.';
      debugPrint('Error searching: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Detail ---
  Future<Recipe?> fetchRecipeDetails(String id) async {
    try {
      final response =
          await http.get(Uri.parse('$_apiBase/lookup.php?i=$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && data['meals'].isNotEmpty) {
          return _formatMeal(data['meals'][0]);
        }
      }
    } catch (e) {
      debugPrint('Error fetching details: $e');
    }
    return null;
  }

  // --- Categories & Areas ---
  Future<void> fetchCategories() async {
    try {
      final response =
          await http.get(Uri.parse('$_apiBase/categories.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['categories'] != null) {
          categories = (data['categories'] as List)
              .map((c) => Category.fromJson(c))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  Future<void> fetchAreas() async {
    try {
      final response =
          await http.get(Uri.parse('$_apiBase/list.php?a=list'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          areas = (data['meals'] as List)
              .map((a) => a['strArea'] as String)
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching areas: $e');
    }
  }

  Future<void> fetchByCategory(String name) =>
      _fetchByFilter('filter.php?c=$name', name, 'category');

  Future<void> fetchByArea(String name) =>
      _fetchByFilter('filter.php?a=$name', name, 'area');

  Future<void> _fetchByFilter(
      String endpoint, String filter, String type) async {
    isLoading = true;
    error = null;
    canInfiniteScroll = false;
    if (type == 'category') {
      selectedCategory = filter;
      selectedArea = null;
    } else {
      selectedArea = filter;
      selectedCategory = null;
    }
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_apiBase/$endpoint'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null) {
          final toFetch = (data['meals'] as List).take(20).toList();
          final detailed = <Recipe>[];
          for (final meal in toFetch) {
            final r = await fetchRecipeDetails(meal['idMeal']);
            if (r != null) detailed.add(r);
          }
          recipes = detailed;
        } else {
          recipes = [];
          error = 'No recipes found.';
        }
      } else {
        error = 'Failed to load recipes.';
      }
    } catch (e) {
      error = 'Failed to load recipes. Please try again.';
      debugPrint('Error filtering: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Formatter ---
  Recipe _formatMeal(Map<String, dynamic> meal) {
    final ingredients = <String>[];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients
            .add('${measure ?? ''} ${ingredient.toString().trim()}'.trim());
      }
    }
    final steps = (meal['strInstructions'] as String? ?? '')
        .split(RegExp(r'\r\n|\r|\n'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    List<String> tags = [];
    if (meal['strTags'] != null && meal['strTags'].toString().isNotEmpty) {
      tags = meal['strTags'].toString().split(',');
    }
    return Recipe(
      id: meal['idMeal'],
      title: meal['strMeal'],
      imageUrl: meal['strMealThumb'],
      category: meal['strCategory'] ?? 'Unknown',
      area: meal['strArea'] ?? 'Unknown',
      ingredients: ingredients,
      instructions: steps,
      tags: tags,
      youtubeUrl: meal['strYoutube'],
    );
  }
}