import 'package:teste/criar_leads.dart';

class Lead {
  final String nome_local;
  final String responsavel;
  final String telefone;
  final Address endereco;
  final String estado_leads;
  final String? categoria_venda;
  final String? observacao;
  final double? valor;
  final int id_usuario; // usuário logado

  Lead({
    required this.nome_local,
    required this.responsavel,
    required this.telefone,
    required this.endereco,
    required this.estado_leads,
    this.categoria_venda,
    this.observacao,
    this.valor,
    required this.id_usuario,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome_local': nome_local,
      'nome_responsavel': responsavel,
      'telefone': telefone,
      'endereco': endereco.toJson(), // <- enviar o endereço completo
      'valor_proposta': valor,
      'categoria_venda': categoria_venda,
      'observacao': observacao,
      'estado_leads': estado_leads,
      'id_usuario': id_usuario,
    };
  }
}