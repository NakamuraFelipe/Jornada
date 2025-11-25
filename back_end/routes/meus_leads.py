from flask import Blueprint, request, jsonify
from dao.meus_leads import MeusLeadsDAO
import jwt

meus_leads_bp = Blueprint("meus_leads", __name__)

# 🔹 Configurações do JWT
SECRET_KEY = "DeAdMaU5#"
TOKEN_EXP_HOURS = 6  # duração do token em horas

@meus_leads_bp.route("/meus_leads", methods=["GET"])
def buscar_meus_leads():
    token = request.headers.get("Authorization")
    if not token:
        return jsonify({"erro": "Token ausente"}), 401

    token = token.strip()
    if token.startswith("Bearer "):
        token = token[7:].strip()

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        id_usuario = payload.get("id_usuario")
        if not id_usuario:
            return jsonify({"erro": "Token inválido"}), 401
    except jwt.ExpiredSignatureError:
        return jsonify({"erro": "Token expirado"}), 401
    except jwt.InvalidTokenError:
        return jsonify({"erro": "Token inválido"}), 401

    query = request.args.get("query", "").strip()
    leads = MeusLeadsDAO.buscar_leads(query, id_usuario)
    return jsonify([lead.to_dict() for lead in leads]), 200
