from flask import Flask, jsonify
from database import get_connection, test_connection

app = Flask(__name__)

@app.route('/')
def home():
    """Rota principal"""
    return jsonify({
        "api": "Jornada Ademicon",
        "status": "online",
        "endpoints": ["/teste", "/health"]
    })

@app.route('/teste')
def teste_conexao():
    """Testa conexão com banco"""
    sucesso, mensagem = test_connection()
    
    if sucesso:
        return jsonify({
            "status": "sucesso",
            "mensagem": mensagem
        })
    else:
        return jsonify({
            "status": "erro",
            "mensagem": mensagem
        }), 500

@app.route('/health')
def health():
    """Verifica saúde da aplicação"""
    sucesso, _ = test_connection()
    
    return jsonify({
        "app": "running",
        "database": "connected" if sucesso else "disconnected"
    })

if __name__ == '__main__':
    print("🚀 Iniciando API...")
    print("📍 http://localhost:5000")
    print("🧪 Teste: http://localhost:5000/teste")
    app.run(debug=True)