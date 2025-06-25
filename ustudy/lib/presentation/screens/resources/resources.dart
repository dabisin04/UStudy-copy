// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:ustudy/domain/entities/article.dart';
import 'package:ustudy/core/services/news_api.dart';
import 'package:ustudy/presentation/widgets/resources/article_card.dart';
import 'package:ustudy/presentation/screens/resources/article_webview.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  late Future<List<Article>> _futureArticles;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _loadArticles() {
    _futureArticles = NewsService().fetchMentalHealthNews(limit: 10);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadArticles();
    });
  }

  void _openArticle(BuildContext context, Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ArticleWebViewScreen(url: article.url, title: article.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Article>>(
            future: _futureArticles,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final articles = snapshot.data!;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mental Health Resources",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Articles and tips to help you stay healthy and happy.",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ...articles.map(
                      (article) => ArticleCard(
                        key: Key(article.title),
                        article: article,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
