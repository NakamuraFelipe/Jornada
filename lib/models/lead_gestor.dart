class LeadGestor {
  final int idLead;
  final String nomeLocal;
  final String nomeResponsavel;
  final String telefone;
  final double? valorAcordado;   // vem da tabela VISITA (última visita)
  final String? categoriaVenda;
  final String? dataCriacao;
  final String estadoLead;
  final int idUsuario;
  final String nomeConsultor;

  LeadGestor({
    required this.idLead,
    required this.nomeLocal,
    required this.nomeResponsavel,
    required this.telefone,
    this.valorAcordado,
    this.categoriaVenda,
    this.dataCriacao,
    required this.estadoLead,
    required this.idUsuario,
    required this.nomeConsultor,
  });

  factory LeadGestor.fromJson(Map<String, dynamic> json) {
    return LeadGestor(
      idLead:          json['id_lead'] as int,
      nomeLocal:       json['nome_local']       as String? ?? '',
      nomeResponsavel: json['nome_responsavel'] as String? ?? '',
      telefone:        json['telefone']         as String? ?? '',
      valorAcordado: json['valor_acordado'] != null
          ? (json['valor_acordado'] as num).toDouble()
          : null,
      categoriaVenda: json['categoria_venda'] as String?,
      dataCriacao:    json['data_criacao']    as String?,
      estadoLead:     json['estado_lead']     as String? ?? 'aberta',
      idUsuario:      json['id_usuario']      as int,
      nomeConsultor:  json['nome_consultor']  as String? ?? '',
    );
  }
}