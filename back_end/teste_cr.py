# test_credenciais.py
import oracledb

# Configurações - SUBSTITUA AQUI
USER = "ADMIN"
PASSWORD = "Jornada123."  # Senha do ADMIN
WALLET_PASSWORD = "Jornada123."  # Senha do WALLET
DSN = "jornada_medium"
WALLET_DIR = r"C:\Users\felip\Downloads\Wallet_jornada (1)"

print("=== TESTE DE CREDENCIAIS ===\n")
print(f"Usuário: {USER}")
print(f"Wallet: {WALLET_DIR}")
print(f"DSN: {DSN}\n")

# Tentar diferentes combinações
tentativas = [
    ("Senha ADMIN", PASSWORD),
    ("Senha WALLET", WALLET_PASSWORD),
]

for nome, senha in tentativas:
    print(f"Testando: {nome}")
    try:
        conn = oracledb.connect(
            user=USER,
            password=senha,  # Testa a senha
            dsn=DSN,
            config_dir=WALLET_DIR,
            wallet_location=WALLET_DIR,
            wallet_password=WALLET_PASSWORD  # Mantém a senha do wallet
        )
        
        cursor = conn.cursor()
        cursor.execute("SELECT SYSDATE FROM dual")
        data = cursor.fetchone()[0]
        
        print(f"✅ CONEXÃO BEM-SUCEDIDA! Data: {data}\n")
        conn.close()
        break
        
    except Exception as e:
        print(f"❌ Falhou: {e}\n")

print("Dica: Se a senha do ADMIN estiver errada, você pode resetá-la no console da Oracle Cloud.")