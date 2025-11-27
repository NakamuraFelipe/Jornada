from flask import Blueprint, request, jsonify, session
from database import get_db_connection
from passlib.hash import argon2
from models.usuario_logado import UsuarioLogado
import base64
import jwt
import datetime

login_bp = Blueprint('login_bp', __name__)

SECRET_KEY = "DeAdMaU5#"
TOKEN_EXP_HOURS = 6


# =====================================================
# Função para limpar qualquer rastro de usuário logado
# =====================================================
def limpar_usuario_logado():
    print("\n🧹 Limpando dados de usuário logado anterior...")

    try:
        # Caso você use flask session
        try:
            session.clear()
        except:
            pass

        # Se estiver usando objeto global:
        try:
            UsuarioLogado.id_usuario = None
            UsuarioLogado.nome_usuario = None
            UsuarioLogado.cargo = None
            UsuarioLogado.email = None
            UsuarioLogado.telefone = None
            UsuarioLogado.foto = None
        except:
            pass

        print("✔ Dados limpos com sucesso!\n")

    except Exception as e:
        print(f"⚠ Erro ao limpar dados anteriores: {e}")


@login_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data.get('email')
    senha = data.get('password')

    if not email or not senha:
        return jsonify({"status": "erro", "mensagem": "Email e senha são obrigatórios"}), 400

    # =====================================================
    # 🔥 LIMPAR DADOS DO LOGIN ANTERIOR ANTES DE CONTINUAR
    # =====================================================
    limpar_usuario_logado()

    connection = get_db_connection()
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM usuario WHERE email = %s", (email,))
        user = cursor.fetchone()

        if user and not isinstance(user, dict):
            columns = [desc[0] for desc in cursor.description]
            user = dict(zip(columns, user))
    except Exception as e:
        return jsonify({"status": "erro", "mensagem": f"Erro no banco de dados: {str(e)}"}), 500
    finally:
        connection.close()

    if not user:
        return jsonify({"status": "erro", "mensagem": "Email ou senha inválidos"}), 401

    senha_hash = user.get('senha_hash')

    try:
        if senha_hash and argon2.verify(senha, senha_hash):
            foto_base64 = None
            if user.get('foto'):
                foto_base64 = base64.b64encode(user['foto']).decode('utf-8')

            usuario = UsuarioLogado(
                id_usuario=user['id_usuario'],
                nome_usuario=user['nome_usuario'],
                cargo=user['cargo'],
                email=user['email'],
                telefone=user.get('telefone'),
                foto=foto_base64
            )

            payload = {
                "id_usuario": user['id_usuario'],
                "email": user['email'],
                "nome_usuario": user['nome_usuario'],
                "cargo": user['cargo'],
                "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=TOKEN_EXP_HOURS)
            }

            token = jwt.encode(payload, SECRET_KEY, algorithm="HS256")

            # =====================================================
            # 🔍 PRINT NO TERMINAL COM INFO DO USUÁRIO LOGADO
            # =====================================================
            print("\n================== 👤 USUÁRIO LOGADO ==================")
            print(f"ID: {usuario.id_usuario}")
            print(f"Nome: {usuario.nome_usuario}")
            print(f"Cargo: {usuario.cargo}")
            print(f"Email: {usuario.email}")
            print(f"Telefone: {usuario.telefone}")
            print(f"Foto base64: {'Sim' if usuario.foto else 'Não'}")
            print("========================================================\n")

            return jsonify({
                "status": "ok",
                "token": token,
                "usuario": usuario.to_dict()
            })

    except Exception as e:
        return jsonify({"status": "erro", "mensagem": f"Erro ao verificar senha: {str(e)}"}), 500

    return jsonify({"status": "erro", "mensagem": "Email ou senha inválidos"}), 401



@login_bp.route('/usuario_logado', methods=['GET'])
def usuario_logado():
    token_header = request.headers.get('Authorization')
    print(f"Header Authorization recebido: {token_header}")  # 🔹 imprime o header completo

    if not token_header:
        return jsonify({"status": "erro", "mensagem": "Token não fornecido"}), 401

    # Se o token vier no formato "Bearer <token>", vamos separar
    if token_header.startswith("Bearer "):
        token = token_header.split(" ")[1]
        print(f"Token extraído: {token}")  # 🔹 imprime o token sem o Bearer
    else:
        token = token_header
        print(f"Token direto usado: {token}")  # 🔹 imprime se não tiver Bearer

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        print(f"Payload decodificado: {payload}")  # 🔹 imprime o conteúdo do token
        return jsonify({"status": "ok", "usuario": payload})
    except jwt.ExpiredSignatureError:
        print("Erro: Token expirado")
        return jsonify({"status": "erro", "mensagem": "Token expirado"}), 401
    except jwt.InvalidTokenError as e:
        print(f"Erro: Token inválido - {e}")
        return jsonify({"status": "erro", "mensagem": "Token inválido"}), 401



# Endpoint para buscar apenas a foto do usuário
@login_bp.route('/usuario/<int:id_usuario>/foto', methods=['GET'])
def get_foto_usuario(id_usuario):
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        cursor.execute("SELECT foto FROM usuario WHERE id_usuario = %s", (id_usuario,))
        user = cursor.fetchone()
        connection.close()

        if not user or not user.get('foto'):
            return jsonify({"status": "erro", "mensagem": "Foto não encontrada"}), 404

        foto_bytes = user['foto']
        foto_base64 = base64.b64encode(foto_bytes).decode('utf-8')

        return jsonify({"status": "ok", "foto": foto_base64})

    except Exception as e:
        return jsonify({"status": "erro", "mensagem": f"Erro ao buscar foto: {str(e)}"}), 500