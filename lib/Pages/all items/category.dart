class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class SubCategory {
  final int id;
  final String name;
  final int categoryId;

  SubCategory({required this.id, required this.name, required this.categoryId});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'],
      name: json['name'],
      categoryId: json['category']['id'],
    );
  }
}
