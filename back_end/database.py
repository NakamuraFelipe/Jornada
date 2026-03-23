import oracledb
import os

# Configurações do banco
DB_CONFIG = {
    "user": "ADMIN",
    "password": "Jornada123.",  # ← ALTERE
    "dsn": "jornada_medium",
    "config_dir": r"C:\Users\felip\Downloads\Wallet_jornada",
    "wallet_location": r"C:\Users\felip\Downloads\Wallet_jornada",
    "wallet_password": "Jornada123."  # ← ALTERE
}

# Caminho para a pasta do Instant Client que você baixou e extraiu
ORACLE_CLIENT_PATH = r"C:\Users\felip\Downloads\instantclient-basic-windows.x64-23.26.1.0.0\instantclient_23_0"

def init_oracle_client():
    """Inicializa o cliente Oracle no modo Thick apontando para a wallet."""
    if not os.path.exists(ORACLE_CLIENT_PATH):
        raise FileNotFoundError(f"Oracle Client não encontrado em: {ORACLE_CLIENT_PATH}")
    
    # Pasta da wallet (onde está o tnsnames.ora)
    wallet_dir = DB_CONFIG["config_dir"]
    if not os.path.exists(wallet_dir):
        raise FileNotFoundError(f"Wallet não encontrada em: {wallet_dir}")
    
    # Inicializa o modo Thick passando o diretório de configuração
    oracledb.init_oracle_client(lib_dir=ORACLE_CLIENT_PATH, config_dir=wallet_dir)
    print(f"✅ Modo Thick inicializado (Cliente: {ORACLE_CLIENT_PATH})")
    print(f"✅ Wallet configurada em: {wallet_dir}")

def get_connection():
    """Retorna uma conexão com o banco de dados."""
    connection = oracledb.connect(**DB_CONFIG)
    return connection

def test_connection():
    """Testa a conexão com o banco."""
    try:
        init_oracle_client()
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT SYSDATE FROM dual")
        data = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return True, f"Conexão OK! Data/Hora do banco: {data}"
    except Exception as e:
        return False, f"Erro: {e}"