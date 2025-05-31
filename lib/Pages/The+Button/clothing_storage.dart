import 'dart:convert';
import 'package:flutter_application_1/Pages/The+Button/clothing_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClothingStorage {
  static const String _key = 'clothing_items';

  static Future<void> saveItem(ClothingItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getStringList(_key) ?? [];
    existingData.add(jsonEncode(item.toJson()));
    await prefs.setStringList(_key, existingData);
  }

  static Future<List<ClothingItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((item) => ClothingItem.fromJson(jsonDecode(item))).toList();
  }

  static Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
