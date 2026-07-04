import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';

class ShoppingListProvider extends ChangeNotifier {
  List<ShoppingItem> _items = [];

  List<ShoppingItem> get items => _items;
  List<ShoppingItem> get unchecked => _items.where((i) => !i.isChecked).toList();
  List<ShoppingItem> get checked => _items.where((i) => i.isChecked).toList();

  ShoppingListProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('shopping_list');
      if (stored != null) {
        final List<dynamic> decoded = json.decode(stored);
        _items = decoded.map((e) => ShoppingItem.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading shopping list: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'shopping_list', json.encode(_items.map((i) => i.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving shopping list: $e');
    }
  }

  void addFromRecipe(Recipe recipe) {
    for (final ingredient in recipe.ingredients) {
      final alreadyExists = _items.any(
          (i) => i.name == ingredient && i.recipeTitle == recipe.title);
      if (!alreadyExists) {
        _items.add(ShoppingItem(
          id: '${recipe.id}_${ingredient.hashCode}',
          name: ingredient,
          recipeTitle: recipe.title,
        ));
      }
    }
    _save();
    notifyListeners();
  }

  void addItem(String name) {
    _items.add(ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    ));
    _save();
    notifyListeners();
  }

  void toggleItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index].isChecked = !_items[index].isChecked;
      _save();
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    _save();
    notifyListeners();
  }

  void clearChecked() {
    _items.removeWhere((i) => i.isChecked);
    _save();
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _save();
    notifyListeners();
  }
}