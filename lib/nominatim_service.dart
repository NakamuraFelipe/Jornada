import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  static Future<List<String>> buscarEnderecos(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search"
      "?format=json"
      "&addressdetails=1"
      "&limit=8"
      "&countrycodes=br"
      "&q=$query",
    );

    final response = await http.get(
      url,
      headers: {
        "User-Agent": "SeuApp/1.0 (felipe.s.nakamura@gmail.com)", // obrigatório
      },
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);

    return List<String>.from(
      data.map((item) => item["display_name"] as String),
    );
  }
}
