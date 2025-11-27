class UsuarioLogado {
  final int idUsuario;
  final String nomeUsuario;
  final String cargo;
  final String matricula;
  final String email;
  final String? telefone;
  String? foto;
  final String? token; // opcional

  UsuarioLogado({
    required this.idUsuario,
    required this.nomeUsuario,
    required this.cargo,
    required this.matricula,
    required this.email,
    this.telefone,
    this.foto,
    this.token,
  });

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _parseString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  factory UsuarioLogado.fromJson(Map<String, dynamic> json) {
    // procura alternativas comuns de chaves
    final id = _parseInt(json['id_usuario'] ?? json['idUsuario'] ?? json['id']);
    final nome = _parseString(json['nome_usuario'] ?? json['nomeUsuario'] ?? json['nome']);
    final cargo = _parseString(json['cargo']);
    final matricula = _parseString(json['matricula'] ?? json['matricula_usuario']);
    final email = _parseString(json['email']);
    final telefoneRaw = json['telefone'] ?? json['telefone_usuario'] ?? json['phone'];
    final telefone = telefoneRaw == null || telefonoEmpty(telefoneRaw) ? null : _parseString(telefoneRaw);

    String? fotoVal;
    final rawFoto = json['foto'] ?? json['imagem'] ?? json['photo'];
    if (rawFoto != null) {
      final s = _parseString(rawFoto).trim();
      if (s.isNotEmpty) fotoVal = s;
    }

    final tokenVal = json['token'] ?? json['access_token'] ?? json['jwt'];

    return UsuarioLogado(
      idUsuario: id,
      nomeUsuario: nome,
      cargo: cargo,
      matricula: matricula,
      email: email,
      telefone: telefone,
      foto: fotoVal,
      token: tokenVal == null ? null : _parseString(tokenVal),
    );
  }

  static bool telefonoEmpty(dynamic v) {
    if (v == null) return true;
    if (v is String && v.trim().isEmpty) return true;
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nome_usuario': nomeUsuario,
      'cargo': cargo,
      'matricula': matricula,
      'email': email,
      'telefone': telefone ?? '',
      'foto': foto ?? '',
      'token': token,
    };
  }
}
