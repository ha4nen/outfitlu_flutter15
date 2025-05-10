class Outfit {
  final int id;
  final String? photoPath;
  final String? season;
  final String? description;
  final String? tags;
  final bool isHijabFriendly;
  final String? type; // ✅ Add this line

  Outfit({
    required this.id,
    this.photoPath,
    this.season,
    this.description,
    this.tags,
    required this.isHijabFriendly,
    this.type, // ✅ Add this to the constructor
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'],
      photoPath: json['photo_path'] != null ? 'http://10.0.2.2:8000${json['photo_path']}' : null,
      season: json['season'],
      description: json['description'],
      tags: json['tags'],
      isHijabFriendly: json['is_hijab_friendly'],
      type: json['type'], // ✅ Parse from JSON
    );
  }
}
