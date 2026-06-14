import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider extends ChangeNotifier {
  static String? accessToken;
  int? userId;
  final String _baseUrl = 'http://10.0.2.2:5170/';

  Future<void> login(String username, String password) async {
    var uri = Uri.parse('${_baseUrl}Access/login');
    var body = jsonEncode({'username': username, 'password': password});
    var headers = {'Content-Type': 'application/json'};

    var response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      accessToken = data['accessToken'];
      userId = data['userId'];
      notifyListeners();
    } else {
      throw Exception("Pogrešan username ili lozinka");
    }
  }

  String get fullName {
    if (accessToken == null) return '';
    Map<String, dynamic> decoded = JwtDecoder.decode(accessToken!);
    return '${decoded['given_name']} ${decoded['family_name']}';
  }
}
