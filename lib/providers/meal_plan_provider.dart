import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';

class MealPlanProvider extends ChangeNotifier {
  List<MealPlanEntry> _entries = [];

  List<MealPlanEntry> get entries => _entries;

  MealPlanProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('meal_plan');
      if (stored != null) {
        final List<dynamic> decoded = json.decode(stored);
        _entries = decoded.map((e) => MealPlanEntry.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading meal plan: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'meal_plan', json.encode(_entries.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving meal plan: $e');
    }
  }

  List<MealPlanEntry> entriesForDay(DateTime day) {
    return _entries
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }

  void addEntry(Recipe recipe, DateTime date, MealType mealType) {
    // Remove existing entry for same day + meal type
    _entries.removeWhere((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day &&
        e.mealType == mealType);

    _entries.add(MealPlanEntry(
      id: '${date.toIso8601String()}_${mealType.index}',
      recipe: recipe,
      date: date,
      mealType: mealType,
    ));
    _save();
    notifyListeners();
  }

  void removeEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    _save();
    notifyListeners();
  }

  bool hasEntryFor(DateTime date, MealType mealType) {
    return _entries.any((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day &&
        e.mealType == mealType);
  }
}