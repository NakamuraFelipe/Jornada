from flask import Flask
from flask_cors import CORS # type: ignore
from routes.login import login_bp
from routes.lead_routes import lead_bp

app = Flask(__name__)
app.secret_key = "DeAdMaU5#"  # Necessário para usar session

# 🔹 Configure corretamente o CORS
CORS(
    app,
    supports_credentials=True,
    origins=[
        "http://localhost:3000",  # se o front estiver rodando localmente
        "http://192.168.0.22:5000"  # se o front estiver acessando via rede
    ]
)

# 🔹 Registrar o blueprint de login
app.register_blueprint(login_bp)

# 🔹 Registrar o blueprint de lead
app.register_blueprint(lead_bp)

if __name__ == '__main__':
    # 🔹 Host 0.0.0.0 permite acessar de outros dispositivos na mesma rede
    app.run(host="0.0.0.0", port=5000, debug=True)
