from flask import Blueprint, request, jsonify

import jwt

from dao.all_leads import buscar_all_leads

all_leads_bp = Blueprint("all_leads", __name__)

SECRET_KEY = "DeAdMaU5#"
TOKEN_EXP_HOURS = 6

@all_leads_bp.route("/all_leads", methods=["GET"])
def buscar_all_leads_route():
    token = request.headers.get("Authorization")
    if not token:
        return jsonify({"erro": "Token ausente"}), 401

    token = token.strip()
    if token.startswith("Bearer "):
        token = token[7:].strip()

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        # ❗ Você ainda pode validar o token, mas não precisa do id_usuario agora
    except jwt.ExpiredSignatureError:
        return jsonify({"erro": "Token expirado"}), 401
    except jwt.InvalidTokenError:
        return jsonify({"erro": "Token inválido"}), 401

    query = request.args.get("query", "").strip()

    # ❗ TROCA FINAL
    leads = buscar_all_leads(query)

    return jsonify([lead.to_dict() for lead in leads]), 200
