import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();

  List<String> _sugestoes = [];
  Timer? _debounce;

  // Função para buscar endereços no Nominatim
  Future<void> _buscarEnderecos() async {
    String rua = _ruaController.text.trim();
    String cidade = _cidadeController.text.trim();

    if (rua.isEmpty && cidade.isEmpty) {
      setState(() => _sugestoes = []);
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      String query = rua;
      if (cidade.isNotEmpty) query += ', $cidade';

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5',
      );

      final response = await http.get(
        url,
        headers: {"User-Agent": "MeuAppFlutter/1.0 (meuemail@exemplo.com)"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sugestoes = List<String>.from(
            data.map((item) {
              final address = item['address'] ?? {};
              String cidadeEstado = '';
              if (address['city'] != null) {
                cidadeEstado += address['city'];
              } else if (address['town'] != null) {
                cidadeEstado += address['town'];
              } else if (address['village'] != null) {
                cidadeEstado += address['village'];
              }

              if (address['state'] != null) {
                cidadeEstado += cidadeEstado.isNotEmpty
                    ? ' / ${address['state']}'
                    : address['state'];
              }

              return '${item['display_name']} (${cidadeEstado})';
            }),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _ruaController.dispose();
    _cidadeController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            backgroundColor: const Color(0xFFD32F2F),
            elevation: 0,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              background: SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _ruaController,
                    decoration: const InputDecoration(
                      labelText: 'Rua',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.streetview,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    onChanged: (_) => _buscarEnderecos(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.location_city,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                    onChanged: (_) => _buscarEnderecos(),
                  ),
                  const SizedBox(height: 12),
                  // Sugestões
                  ..._sugestoes.map(
                    (s) => Card(
                      child: ListTile(
                        title: Text(s),
                        onTap: () {
                          _ruaController.text = s;
                          setState(() => _sugestoes = []);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
