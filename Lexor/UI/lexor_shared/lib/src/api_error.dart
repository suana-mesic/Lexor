import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Turns backend HTTP errors and exceptions into user-friendly messages.
/// Shared between the mobile and desktop apps via the `lexor_shared` package.
class ApiError {
  /// Message for a failed HTTP response (status != 2xx).
  /// Prefers the message returned by the backend (e.g. validation); if there is
  /// none, falls back to a generic message based on the status code.
  static String fromResponse(http.Response response) {
    final backendMessage = _extractMessage(response.body);

    switch (response.statusCode) {
      case 400:
        return backendMessage ?? 'Neispravan zahtjev.';
      case 401:
        return 'Vaša sesija je istekla. Prijavite se ponovo.';
      case 403:
        return 'Nemate dozvolu za pristup ovim podacima.';
      case 404:
        return backendMessage ?? 'Traženi podaci nisu pronađeni.';
      case 408:
        return 'Zahtjev je predugo trajao. Pokušajte ponovo.';
      case 409:
        return backendMessage ??
            'Došlo je do konflikta sa postojećim podacima.';
      case 422:
        return backendMessage ?? 'Uneseni podaci nisu ispravni.';
      case 500:
      case 502:
      case 503:
        return 'Greška na serveru. Pokušajte ponovo kasnije.';
      default:
        return backendMessage ?? 'Došlo je do greške. Pokušajte ponovo.';
    }
  }

  /// Message for an exception raised while sending the request (network, timeout, parsing).
  static String fromException(Object e) {
    if (e is SocketException) {
      return 'Nije moguće povezati se sa serverom. Provjerite internet konekciju.';
    }
    if (e is http.ClientException) {
      return 'Nije moguće povezati se sa serverom. Provjerite da li je server pokrenut.';
    }
    if (e is FormatException) {
      return 'Server je vratio neočekivan odgovor.';
    }
    return 'Došlo je do greške. Pokušajte ponovo.';
  }

  /// Whether the response is a session expiry (401) — used to redirect the user to login.
  static bool isSessionExpired(http.Response response) =>
      response.statusCode == 401;

  /// Tries to extract a message from the response body (ASP.NET ProblemDetails / { message } / { errors }).
  static String? _extractMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        final title = data['title'];
        if (title is String && title.trim().isNotEmpty) {
          return title;
        }
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstField = errors.values.first;
          if (firstField is List && firstField.isNotEmpty) {
            return firstField.first.toString();
          }
        }
      }
    } catch (_) {
      // body is not JSON — ignore
    }
    return null;
  }
}
