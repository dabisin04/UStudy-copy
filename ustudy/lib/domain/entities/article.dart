class Article {
  final String title;
  final String description;
  final String url;
  final String? imageUrl;

  Article({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? 'Sin título',
      description: json['description'] ?? 'Sin descripción',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'],
    );
  }
}
