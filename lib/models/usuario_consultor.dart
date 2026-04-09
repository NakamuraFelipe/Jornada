class UsuarioConsultor {
  final int idUsuario;
  final String nomeUsuario;
  final String cargo;
  final String? email;
  final String? telefone;
 
  UsuarioConsultor({
    required this.idUsuario,
    required this.nomeUsuario,
    required this.cargo,
    this.email,
    this.telefone,
  });
 
  factory UsuarioConsultor.fromJson(Map<String, dynamic> json) {
    return UsuarioConsultor(
      idUsuario: json['id_usuario'] as int,
      nomeUsuario: json['nome_usuario'] as String,
      cargo: json['cargo'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
    );
  }
 
  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'nome_usuario': nomeUsuario,
    'cargo': cargo,
    'email': email,
    'telefone': telefone,
  };
}