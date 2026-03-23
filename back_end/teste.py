from database import test_connection

if __name__ == "__main__":
    print("=== TESTE DE CONEXÃO ===\n")
    sucesso, mensagem = test_connection()
    
    if sucesso:
        print(f"✅ {mensagem}")
    else:
        print(f"❌ {mensagem}")