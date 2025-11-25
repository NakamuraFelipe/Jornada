import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: unused_import
import '../models/meus_leads.dart';

class MeusLeadsService {

  static const String baseUrl = "http://192.168.0.22:5000";

static Future<List<dynamic>> buscarLeads(String query, int idUsuario) async {
  final url = Uri.parse("$baseUrl/meus_leads?query=$query&id_usuario=$idUsuario");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    return [];
  }
}

}
