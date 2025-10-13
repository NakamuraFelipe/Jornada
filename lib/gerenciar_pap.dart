import 'package:flutter/material.dart';
import 'package:teste/home_page_gestor.dart';

class GerenciarPAP extends StatefulWidget {
  @override
  State<GerenciarPAP> createState() => _GerenciarPAPState();
}

class _GerenciarPAPState extends State<GerenciarPAP> {
  // Listas simuladas — futuramente virão do banco de dados
  final List<String> consultores = [
    'João Pereira',
    'Maria Silva',
    'Carlos Santos',
    'Ana Oliveira',
    'Lucas Souza',
    'Fernanda Costa',
    'Rafael Martins',
    'Bianca Rocha',
    'Marcos Lima',
    'Paula Andrade'
  ];

  final List<String> ruas = [
    'Rua das Flores',
    'Avenida Central',
    'Travessa da Paz',
    'Rua dos Cedros',
    'Alameda das Acácias',
    'Rua Dom Pedro II',
    'Avenida Brasil',
    'Rua das Palmeiras',
    'Rua Monte Castelo',
    'Rua do Sol'
  ];

  // Função para abrir o pop-up de consulta
  void _abrirPopup(String tipo) {
    showDialog(
      context: context,
      barrierDismissible: false, // só fecha com o botão X
      builder: (BuildContext context) {
        String filtro = '';
        List<String> listaOriginal =
            tipo == 'consultor' ? consultores : ruas;
        List<String> resultados = List.from(listaOriginal);

        return StatefulBuilder(
          builder: (context, setState) {
            void filtrar(String valor) {
              setState(() {
                filtro = valor.toLowerCase();
                resultados = listaOriginal
                    .where((item) => item.toLowerCase().contains(filtro))
                    .toList();
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(15),
                constraints: const BoxConstraints(maxHeight: 450, maxWidth: 350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho com título e botão X
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tipo == 'consultor'
                              ? 'Selecionar Consultor'
                              : 'Selecionar Rua',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const Divider(thickness: 1),
                    const SizedBox(height: 10),

                    // Campo de pesquisa
                    TextField(
                      onChanged: filtrar,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: tipo == 'consultor'
                            ? 'Pesquisar consultor...'
                            : 'Pesquisar rua...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Lista com resultados filtrados
                    Expanded(
                      child: resultados.isEmpty
                          ? const Center(
                              child: Text('Nenhum resultado encontrado.'),
                            )
                          : ListView.builder(
                              itemCount: resultados.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: Icon(
                                    tipo == 'consultor'
                                        ? Icons.person
                                        : Icons.location_on,
                                    color: Colors.red,
                                  ),
                                  title: Text(resultados[index]),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tipo == 'consultor'
                                              ? 'Consultor selecionado: ${resultados[index]}'
                                              : 'Rua selecionada: ${resultados[index]}',
                                        ),
                                        duration:
                                            const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Estilo padrão dos botões
  ButtonStyle _botaoEstilo() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 5,
      padding: const EdgeInsets.symmetric(vertical: 25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Topo com foto e logo
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            color: const Color(0xFFFF0000),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      AssetImage('assets/images/foto_perfil_teste.png'),
                ),
                Image.asset('assets/images/logo.png', height: 50),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Título da página
          const Text(
            'Gerenciar PAP',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 40),

          // Botões centrais
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _abrirPopup('consultor'),
                  style: _botaoEstilo(),
                  child: const Center(
                    child: Text(
                      'Lista por Consultor',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _abrirPopup('rua'),
                  style: _botaoEstilo(),
                  child: const Center(
                    child: Text(
                      'Lista por Rua',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Rodapé fixo com botão Home
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Color(0xFFFF0000),
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => HomePage_Gestor()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                  backgroundColor: Colors.white,
                  elevation: 5,
                ),
                child: Icon(
                  Icons.home,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
