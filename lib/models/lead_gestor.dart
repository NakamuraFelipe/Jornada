class LeadGestor {
  final int idLeads;
  final String nomeLocal;
  final String nomeResponsavel;
  final String telefone;
  final double? valorProposta;
  final String? categoriaVenda;
  final String? dataCriacao;
  final String estadoLeads;
  final int idUsuario;
  final String nomeConsultor;
 
  LeadGestor({
    required this.idLeads,
    required this.nomeLocal,
    required this.nomeResponsavel,
    required this.telefone,
    this.valorProposta,
    this.categoriaVenda,
    this.dataCriacao,
    required this.estadoLeads,
    required this.idUsuario,
    required this.nomeConsultor,
  });
 
  factory LeadGestor.fromJson(Map<String, dynamic> json) {
    return LeadGestor(
      idLeads: json['id_leads'] as int,
      nomeLocal: json['nome_local'] as String,
      nomeResponsavel: json['nome_responsavel'] as String,
      telefone: json['telefone'] as String,
      valorProposta: json['valor_proposta'] != null
          ? (json['valor_proposta'] as num).toDouble()
          : null,
      categoriaVenda: json['categoria_venda'] as String?,
      dataCriacao: json['data_criacao'] as String?,
      estadoLeads: json['estado_leads'] as String? ?? 'aberta',
      idUsuario: json['id_usuario'] as int,
      nomeConsultor: json['nome_consultor'] as String? ?? '',
    );
  }
}