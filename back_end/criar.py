from database import get_db_connection
from passlib.hash import argon2

def criar_usuario_teste():
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()

        # Dados do usuário de teste
        nome = "Usuário Teste"
        cargo = "gestor"  # gestor | consultor | supervisor
        email = "teste@teste.com"
        telefone = "11999999999"
        senha = "1234"  # senha simples só para testes

        # Gera hash Argon2
        senha_hash = argon2.hash(senha)

        sql = """
            INSERT INTO usuario (nome_usuario, cargo, email, telefone, senha_hash)
            VALUES (%s, %s, %s, %s, %s)
        """

        cursor.execute(sql, (nome, cargo, email, telefone, senha_hash))
        connection.commit()

        print("✅ Usuário de teste criado com sucesso!")
        print(f"✅ Email: {email}")
        print(f"✅ Senha: {senha}")

    except Exception as e:
        print(f"❌ Erro ao criar usuário: {e}")

    finally:
        if connection:
            connection.close()


if __name__ == "__main__":
    criar_usuario_teste()
