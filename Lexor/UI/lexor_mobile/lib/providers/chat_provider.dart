import 'package:flutter/material.dart';
import 'package:lexor_mobile/api_client.dart';
import 'package:lexor_shared/lexor_shared.dart';

/// One line in the chat: either the employee's question or the bot's answer.
class ChatMessage {
  final String text;
  final bool isUser;
  final List<String> sources;
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.sources = const [],
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  bool isSending = false;
  bool isLoadingHistory = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  bool _initialLoaded = false;
  int _page = 1;
  static const int _pageSize = 20;

  Future<void> loadInitialHistory() async {
    if (_initialLoaded || isLoadingHistory) return;

    isLoadingHistory = true;
    notifyListeners();
    try {
      final data = await ApiClient.get(
        '/Chat/history',
        query: {'page': '1', 'pageSize': '$_pageSize'},
      );
      final items = (data['items'] as List)
          .map(_fromJson)
          .toList()
          .reversed
          .toList();
      messages
        ..clear()
        ..addAll(items);

      _page = 1;
      hasMore = messages.length < ((data['totalCount'] ?? 0) as int);
    } catch (_) {
      // History is non-critical; on failure just start with an empty chat.
    } finally {
      isLoadingHistory = false;
      _initialLoaded = true;
      notifyListeners();
    }
  }

  Future<void> loadOlder() async {
    if (isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final next = _page + 1;
      final data = await ApiClient.get(
        '/Chat/history',
        query: {'page': '$next', 'pageSize': '$_pageSize'},
      );
      final order = (data['items'] as List)
          .map(_fromJson)
          .toList()
          .reversed
          .toList();
      messages.insertAll(0, order);
      _page = next;
      hasMore = messages.length < ((data['totalCount'] ?? 0) as int);
    } catch (_) {
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  ChatMessage _fromJson(dynamic j) => ChatMessage(
    text: (j['content'] ?? '') as String,
    isUser: (j['role'] ?? 2) == 1,
    sources: ((j['sources'] ?? []) as List).cast<String>(),
  );

  Future<void> send(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || isSending) return;

    messages.add(ChatMessage(text: trimmed, isUser: true));
    isSending = true;

    notifyListeners();

    try {
      final data = await ApiClient.post(
        '/Chat/ask',
        body: {'question': trimmed},
      );
      final answer = (data['answer'] ?? '') as String;
      final sources = ((data['sources'] ?? []) as List).cast<String>();
      messages.add(ChatMessage(text: answer, isUser: false, sources: sources));
    } catch (e) {
      // Errors are shown as a normal bot message, human-readable (never a raw code).
      messages.add(ChatMessage(text: messageFor(e), isUser: false));
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
