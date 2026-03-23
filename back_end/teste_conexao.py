import oracledb

# Configurações - SUBSTITUA PELOS SEUS DADOS REAIS
config = {
    "user": "ADMIN",
    "password": "Jornada123.",
    "dsn": "jornada_medium",  # Nome do alias no tnsnames.ora
    "config_dir": r"C:\Users\felip\Downloads\Wallet_jornada",  # Caminho da wallet
    "wallet_location": r"C:\Users\felip\Downloads\Wallet_jornada",
    "wallet_password": "Jornada123."
}

print("=== TESTE DE CONEXÃO ORACLE ===")
print(f"Conectando ao banco: {config['dsn']}")
print(f"Wallet: {config['config_dir']}")

try:
    # Tentativa de conexão
    connection = oracledb.connect(**config)
    print("✅ Conexão estabelecida com sucesso!")
    
    with connection.cursor() as cursor:
        # Teste 1: Consulta simples
        cursor.execute("SELECT 'Olá Oracle!' as mensagem, SYSDATE as data_atual FROM dual")
        resultado = cursor.fetchone()
        print(f"✅ Query executada: {resultado[0]} - Data: {resultado[1]}")
        
        # Teste 2: Verificar versão do banco
        cursor.execute("SELECT banner FROM v$version WHERE rownum = 1")
        versao = cursor.fetchone()
        print(f"✅ Versão do Oracle: {versao[0]}")
        
        # Teste 3: Verificar tabelas do usuário
        cursor.execute("SELECT COUNT(*) FROM user_tables")
        total_tabelas = cursor.fetchone()[0]
        print(f"✅ Total de tabelas no esquema: {total_tabelas}")
        
    connection.close()
    print("\n🎉 Teste concluído com sucesso!")
    
except oracledb.Error as e:
    print(f"\n❌ Erro ao conectar:")
    error_obj, = e.args
    print(f"   Código: {error_obj.code}")
    print(f"   Mensagem: {error_obj.message}")
    
except Exception as e:
    print(f"\n❌ Erro inesperado: {e}")