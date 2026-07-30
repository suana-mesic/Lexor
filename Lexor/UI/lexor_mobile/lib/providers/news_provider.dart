import 'package:flutter/foundation.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_mobile/models/news_response.dart';
import 'package:lexor_shared/lexor_shared.dart';

class NewsProvider extends ChangeNotifier {
  List<NewsItem> news = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchNews() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get(
        '/News',
        query: {'sortBy': 'PublishedAt desc', 'pageSize': '20'},
      );
      final items = (data['items'] as List?) ?? [];
      news = items
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      error = messageFor(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    news = [];
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
