class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final String area;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final String? youtubeUrl;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.area,
    required this.ingredients,
    required this.instructions,
    required this.tags,
    this.youtubeUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'category': category,
        'area': area,
        'ingredients': ingredients,
        'instructions': instructions,
        'tags': tags,
        'youtubeUrl': youtubeUrl,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'],
        title: json['title'],
        imageUrl: json['imageUrl'],
        category: json['category'],
        area: json['area'],
        ingredients: List<String>.from(json['ingredients']),
        instructions: List<String>.from(json['instructions']),
        tags: List<String>.from(json['tags']),
        youtubeUrl: json['youtubeUrl'],
      );
}

class Category {
  final String id;
  final String name;
  final String thumbUrl;
  final String description;

  Category({
    required this.id,
    required this.name,
    required this.thumbUrl,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['idCategory'],
        name: json['strCategory'],
        thumbUrl: json['strCategoryThumb'],
        description: json['strCategoryDescription'],
      );
}