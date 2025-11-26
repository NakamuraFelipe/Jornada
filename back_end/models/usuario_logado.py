# models/usuario_logado.py
class UsuarioLogado:
    def __init__(self, id_usuario, nome_usuario, cargo, email, telefone=None, foto=None, matricula=None):
        self.id_usuario = id_usuario
        self.nome_usuario = nome_usuario
        self.cargo = cargo
        self.matricula = matricula
        self.email = email
        self.telefone = telefone
        self.foto = foto

    def to_dict(self):
        return {
        "id_usuario": self.id_usuario,
        "nome_usuario": self.nome_usuario,
        "cargo": self.cargo,
        "matricula": self.matricula or "",  # substitui null por string vazia
        "email": self.email or "",
        "telefone": self.telefone or "",
        "foto": self.foto or ""
    }

