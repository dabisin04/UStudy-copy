import 'dart:convert';
import 'package:ustudy/domain/entities/article.dart';
import 'package:http/http.dart' as http;

class NewsService {
  final String _apiKey = 'bafeb70d2786406690b6059f667d4111';

  Future<List<Article>> fetchMentalHealthNews({int limit = 10}) async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?q=mental%20health&pageSize=$limit&language=en&sortBy=publishedAt&apiKey=$_apiKey',
    );

    print('Fetching articles from: $url'); // debug
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final articles = (data['articles'] as List)
          .map((a) => Article.fromJson(a))
          .toList();
      print('Fetched ${articles.length} articles.'); // debug
      return articles;
    } else {
      print('Error fetching articles: ${response.body}'); // debug
      throw Exception('No se pudieron cargar las noticias');
    }
  }
}
