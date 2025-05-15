import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/Outfits/outfit.dart'; // Update path based on your project structure

// General-purpose function (internal use)
Future<List<Outfit>> fetchOutfits({int? userId}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    throw Exception('No auth token found');
  }

  final url = userId != null
      ? Uri.parse('http://10.0.2.2:8000/api/users/$userId/outfits/')
      : Uri.parse('http://10.0.2.2:8000/api/outfits/');

  final response = await http.get(
    url,
    headers: {'Authorization': 'Token $token'},
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Outfit.fromJson(json)).toList();
  } else {
    throw Exception('Failed to fetch outfits: ${response.statusCode}');
  }
}
Future<List<Outfit>> fetchAllOutfits() async {
  return fetchOutfits(); // No userId = current user
}
Future<List<Outfit>> fetchOutfitsByUser(int userId) async {
  return fetchOutfits(userId: userId);
}


Map<String, List<Outfit>> groupOutfitsBySeason(List<Outfit> outfits) {
  final Map<String, List<Outfit>> grouped = {
    'Winter': [],
    'Spring': [],
    'Summer': [],
    'Autumn': [],
    'All-Season': [],
  };

  for (final outfit in outfits) {
    final season = outfit.season ?? 'All-Season';
    grouped[season]?.add(outfit);
  }

  return grouped;
}

Future<void> deleteOutfit(int outfitId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    throw Exception('No auth token found');
  }

  final url = Uri.parse('http://10.0.2.2:8000/api/outfits/$outfitId/');

  final response = await http.delete(
    url,
    headers: {'Authorization': 'Token $token'},
  );

  if (response.statusCode != 204) {
    final body = await json.decode(response.body);
    throw Exception('Failed to delete outfit: ${body.toString()}');
  }
}