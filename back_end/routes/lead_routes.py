from flask import Blueprint, request, jsonify
from dao.lead_dao import LeadDAO
from models.lead_model import Lead

lead_bp = Blueprint('lead', __name__)

from flask import session

import jwt

SECRET_KEY = "DeAdMaU5#"

def decode_jwt(token: str):
    """Decodifica o JWT e retorna o payload"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise ValueError("Token expirado")
    except jwt.InvalidTokenError:
        raise ValueError("Token inválido")


@lead_bp.route('/criar_lead', methods=['POST'])
def criar_lead():
    data = request.get_json()
    if not data:
        return jsonify({"status": "erro", "mensagem": "JSON inválido"}), 400

    # Supondo que você esteja usando JWT no cabeçalho
    usuario_id = None
    if 'usuarioId' in session:
        usuario_id = session['usuarioId']
    elif request.headers.get('Authorization'):
        # decodificar token JWT e extrair id_usuario
        token = request.headers['Authorization'].split(" ")[1]
        usuario_id = decode_jwt(token)['id_usuario']  # sua função decode_jwt

    if not usuario_id:
        return jsonify({"status": "erro", "mensagem": "Usuário não logado"}), 401

    try:
        lead = Lead.from_json(data)
        lead.id_usuario = usuario_id  # ⚠️ importante: usa id do usuário logado

        if lead.endereco:
            lead.id_localizacao = LeadDAO.create_localizacao(lead.endereco)

        inserted_id = LeadDAO.create_lead(lead)

        return jsonify({
            "status": "ok",
            "mensagem": "Lead criado com sucesso",
            "id_lead": inserted_id
        }), 201

    except Exception as e:
        print("Erro criar_lead:", e)
        return jsonify({"status": "erro", "mensagem": str(e)}), 500


