class MeusLeadsModel {
  final int idLead;
  final String nomeLocal;
  final String categoriaVenda;
  final String estadoLeads;
  final int idLocalizacao;

  final String nomeRua;
  final int numero;
  final String? complemento;
  final String nomeCidade;
  final String uf;

  final String nomeConsultor;
  final String? ultimaVisita;
  final String? observacoes;
  final double? valorProposta;
  final String dataCriacao;

  MeusLeadsModel({
    required this.idLead,
    required this.nomeLocal,
    required this.categoriaVenda,
    required this.estadoLeads,
    required this.idLocalizacao,
    required this.nomeRua,
    required this.numero,
    this.complemento,
    required this.nomeCidade,
    required this.uf,
    required this.nomeConsultor,
    this.ultimaVisita,
    this.observacoes,
    this.valorProposta,
    required this.dataCriacao,
  });

  factory MeusLeadsModel.fromJson(Map<String, dynamic> json) {
    return MeusLeadsModel(
      idLead: json['id_lead'],
      nomeLocal: json['nome_local'],
      categoriaVenda: json['categoria_venda'] ?? "",
      estadoLeads: json['estado_leads'],
      idLocalizacao: json['id_localizacao'],

      nomeRua: json['nome_rua'],
      numero: json['numero'],
      complemento: json['complemento'],
      nomeCidade: json['nome_cidade'],
      uf: json['uf'],

      nomeConsultor: json['nome_consultor'],
      ultimaVisita: json['ultima_visita'],
      observacoes: json['observacoes'],
      valorProposta: json['valor_proposta'] != null
          ? double.tryParse(json['valor_proposta'].toString())
          : null,
      dataCriacao: json['data_criacao'],
    );
  }
}
