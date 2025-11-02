# back_end/update_passwords_argon2.py
"""
Script para atualizar a coluna senha_hash dos usuários informados,
gerando um hash Argon2 seguro para a senha em texto plano.
"""

from argon2 import PasswordHasher
from database import get_db_connection

# senha em texto claro que você quer aplicar aos usuários
PLAIN_PASSWORD = "Senha123#"

# ids que serão atualizados
USER_IDS = [1, 2, 3, 4]

def main():
    ph = PasswordHasher()  # inicializa o hasher Argon2

    # gerar hash Argon2
    senha_hash = ph.hash(PLAIN_PASSWORD)
    print("Hash gerado (Argon2):", senha_hash)

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # query parametrizada
        sql = "UPDATE usuario SET senha_hash = %s WHERE id_usuario = %s"
        for uid in USER_IDS:
            cursor.execute(sql, (senha_hash, uid))
            print(f"Atualizando id_usuario={uid} -> {cursor.rowcount} linha(s) afetada(s)")

        conn.commit()
        print("Atualização concluída com sucesso.")
    except Exception as e:
        if conn:
            conn.rollback()
        print("Erro ao atualizar senhas:", e)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
