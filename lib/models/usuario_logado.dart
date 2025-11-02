class UsuarioLogado {
  final int idUsuario;
  final String nomeUsuario;
  final String cargo;
  final String email;
  final String? telefone;
  String? foto;
  final String? token; // ⚠️ novo campo para JWT

  UsuarioLogado({
    required this.idUsuario,
    required this.nomeUsuario,
    required this.cargo,
    required this.email,
    this.telefone,
    this.foto,
    this.token,
  });

  factory UsuarioLogado.fromJson(Map<String, dynamic> json) {
    return UsuarioLogado(
      idUsuario: json['id_usuario'],
      nomeUsuario: json['nome_usuario'],
      cargo: json['cargo'],
      email: json['email'],
      telefone: json['telefone'],
      foto: json['foto'],
      token: json['token'], // capturar o token do backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'nome_usuario': nomeUsuario,
      'cargo': cargo,
      'email': email,
      'telefone': telefone,
      'foto': foto,
      'token': token, // incluir token ao enviar
    };
  }
}
