import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutocompletePage extends StatefulWidget {
  const AutocompletePage({super.key});

  @override
  State<AutocompletePage> createState() => _AutocompletePageState();
}

class _AutocompletePageState extends State<AutocompletePage> {
  final TextEditingController _controller = TextEditingController();
  final String apiKey =
      'AIzaSyCWaK80DL4E84s-qMKXl1tM-7o7BSMc-DY'; // Substitua pela sua chave
  List<dynamic> _suggestions = [];
  Map<String, String?>? _detalhes;

  /// Busca sugestões de endereço usando Google Places Autocomplete API
  Future<void> buscarSugestoes(String input) async {
    if (input.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&language=pt_BR',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final dados = json.decode(response.body);
      setState(() {
        _suggestions = dados['predictions'];
      });
    }
  }

  /// Busca detalhes do endereço usando Geocoding API
  Future<void> buscarDetalhes(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final dados = json.decode(response.body);
      if (dados['status'] == 'OK') {
        final resultado = dados['results'][0];
        final componentes = resultado['address_components'] as List;

        String? pais;
        String? estado;
        String? cidade;
        String? rua;

        for (var comp in componentes) {
          final types = comp['types'] as List;
          if (types.contains('country')) {
            pais = comp['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            estado = comp['long_name'];
          } else if (types.contains('locality') ||
              types.contains('administrative_area_level_2')) {
            cidade = comp['long_name'];
          } else if (types.contains('sublocality')) {
            cidade ??= comp['long_name'];
          } else if (types.contains('route')) {
            rua = comp['long_name'];
          }
        }

        setState(() {
          _detalhes = {
            'pais': pais,
            'estado': estado,
            'cidade': cidade,
            'rua': rua,
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autocomplete Geocoding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Digite a rua',
                border: OutlineInputBorder(),
              ),
              onChanged: buscarSugestoes,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final sugestao = _suggestions[index];
                  return ListTile(
                    title: Text(sugestao['description']),
                    onTap: () {
                      buscarDetalhes(sugestao['place_id']);
                      setState(() {
                        _controller.text = sugestao['description'];
                        _suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
            if (_detalhes != null) ...[
              const Divider(),
              Text('País: ${_detalhes!['pais'] ?? 'Não encontrado'}'),
              Text('Estado: ${_detalhes!['estado'] ?? 'Não encontrado'}'),
              Text('Cidade: ${_detalhes!['cidade'] ?? 'Não encontrado'}'),
              Text('Rua: ${_detalhes!['rua'] ?? 'Não encontrado'}'),
            ],
          ],
        ),
      ),
    );
  }
}
