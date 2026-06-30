import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Pretvara HTTP greške i izuzetke sa backenda u poruke razumljive korisniku.
/// Dijeli se između mobilne i desktop aplikacije preko `lexor_shared` paketa.
class ApiError {
  /// Poruka za neuspješan HTTP odgovor (status != 2xx).
  /// Prvo pokušava iskoristiti poruku koju je vratio backend (npr. validacija),
  /// a ako je nema, vraća generičku poruku prema status kodu.
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

  /// Poruka za izuzetak nastao tokom slanja zahtjeva (mreža, timeout, parsiranje).
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

  /// Da li je odgovor istek sesije (401) — koristi se da se korisnik preusmjeri na prijavu.
  static bool isSessionExpired(http.Response response) =>
      response.statusCode == 401;

  /// Pokušava izvući poruku iz tijela odgovora (ASP.NET ProblemDetails / { message } / { errors }).
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
      // tijelo nije JSON — ignoriši
    }
    return null;
  }
}
