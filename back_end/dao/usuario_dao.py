import traceback
import pymysql
from database import get_db_connection
from models.usuario_logado import UsuarioLogado

class UauarioDAO:
    @staticmethod
    def create_usuario(usuario: Usuario):
        """Cria o usuario no banco"""
        if not all([usuario.nome_usuario, usuario.cargo, usuario.senha_hash, usuario.id_supervisor]):
            raise ValueError("Campos obrigatórios do usuário estão vazios.",usuario.nome_usuario, usuario.cargo, usuario.senha_hash, usuario.id_supervisor)

        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            query = """
                INSERT INTO usuario (nome_usuario, cargo, email,
                                   telefone, foto, senha_hash, id_supervisor)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            values = (
                usuario.nome_usuario,
                usuario.cargo,
                usuario.email,
                usuario.telefone,
                usuario.foto,
                usuario.senha_hash,
                usuario.id_supervisor
            )
            print("Valores para insert usuario:", values)

            cursor.execute(query, values)
            conn.commit()
            inserted_id = cursor.lastrowid
            print(f"Usuario inserido com sucesso -> id_usuario={inserted_id}")

            return inserted_id

        except Exception as e:
            print("Erro em create_usuario:", e)
            traceback.print_exc()
            conn.rollback()
            raise e
        finally:
            cursor.close()
            conn.close()

    @staticmethod
    def get_usuarios_geridos(id_supervisor):
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        try:
            query = """
                SELECT *
                FROM usuario
                WHERE id_supervisor = %s
            """
            cursor.execute(query, (id_supervisor,))
            results = cursor.fetchall()
            return results
        finally:
            cursor.close()
            conn.close()