import traceback
import pymysql
from database import get_db_connection
from models.lead_model import Lead, Address

class LeadDAO:

    @staticmethod
    def create_localizacao(endereco: Address):
        print("=== Iniciando create_localizacao ===")
        print("Dados do endereço recebidos:", vars(endereco))

        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor) 

        try:
            # --- País ---
            cursor.execute("SELECT id_pais FROM pais WHERE nome_pais=%s", (endereco.pais,))
            pais = cursor.fetchone()
            if pais:
                id_pais = pais['id_pais']
                print(f"[LOG] País já existe: {endereco.pais} -> id_pais={id_pais}")
            else:
                cursor.execute("INSERT INTO pais (nome_pais) VALUES (%s)", (endereco.pais,))
                id_pais = cursor.lastrowid
                print(f"[LOG] País inserido: {endereco.pais} -> id_pais={id_pais}")

            # --- Estado ---
            cursor.execute("SELECT id_estado FROM estado WHERE nome_estado=%s AND id_pais=%s",
                           (endereco.estado, id_pais))
            estado = cursor.fetchone()
            if estado:
                id_estado = estado['id_estado']
                print(f"[LOG] Estado já existe: {endereco.estado} -> id_estado={id_estado}")
            else:
                cursor.execute("INSERT INTO estado (nome_estado, uf, id_pais) VALUES (%s, %s, %s)",
                               (endereco.estado, endereco.estado[:2].upper(), id_pais))
                id_estado = cursor.lastrowid
                print(f"[LOG] Estado inserido: {endereco.estado} -> id_estado={id_estado}")

            # --- Cidade ---
            cursor.execute("SELECT id_cidade FROM cidade WHERE nome_cidade=%s AND id_estado=%s",
                           (endereco.cidade, id_estado))
            cidade = cursor.fetchone()
            if cidade:
                id_cidade = cidade['id_cidade']
                print(f"[LOG] Cidade já existe: {endereco.cidade} -> id_cidade={id_cidade}")
            else:
                cursor.execute("INSERT INTO cidade (nome_cidade, id_estado) VALUES (%s, %s)",
                               (endereco.cidade, id_estado))
                id_cidade = cursor.lastrowid
                print(f"[LOG] Cidade inserida: {endereco.cidade} -> id_cidade={id_cidade}")

            # --- Bairro ---
            cursor.execute("SELECT id_bairro, id_cidade FROM bairro WHERE nome_bairro=%s", (endereco.bairro,))
            bairros = cursor.fetchall()
            id_bairro = None
            for b in bairros:
                # pega o nome da cidade correspondente
                cursor.execute("SELECT nome_cidade FROM cidade WHERE id_cidade=%s", (b['id_cidade'],))
                nome_cidade = cursor.fetchone()['nome_cidade']
                if nome_cidade == endereco.cidade:
                    id_bairro = b['id_bairro']
                    print(f"[LOG] Bairro já existe na cidade: {endereco.bairro} -> id_bairro={id_bairro}")
                    break
            if not id_bairro:
                cursor.execute("INSERT INTO bairro (nome_bairro, id_cidade) VALUES (%s, %s)",
                               (endereco.bairro, id_cidade))
                id_bairro = cursor.lastrowid
                print(f"[LOG] Bairro inserido: {endereco.bairro} -> id_bairro={id_bairro}")

            # --- Rua ---
            cursor.execute("SELECT id_rua, id_bairro FROM rua WHERE nome_rua=%s", (endereco.rua,))
            ruas = cursor.fetchall()
            id_rua = None
            for r in ruas:
                # pega o nome do bairro correspondente
                cursor.execute("SELECT nome_bairro FROM bairro WHERE id_bairro=%s", (r['id_bairro'],))
                nome_bairro = cursor.fetchone()['nome_bairro']
                if nome_bairro == endereco.bairro:
                    id_rua = r['id_rua']
                    print(f"[LOG] Rua já existe no bairro: {endereco.rua} -> id_rua={id_rua}")
                    break
            if not id_rua:
                cursor.execute("INSERT INTO rua (nome_rua, id_bairro) VALUES (%s, %s)",
                               (endereco.rua, id_bairro))
                id_rua = cursor.lastrowid
                print(f"[LOG] Rua inserida: {endereco.rua} -> id_rua={id_rua}")

            # --- Localizacao ---
            cursor.execute("""SELECT id_localizacao FROM localizacao 
                              WHERE cep=%s AND numero=%s AND complemento=%s AND id_rua=%s""",
                           (endereco.cep, endereco.numero, endereco.complemento, id_rua))
            local = cursor.fetchone()
            if local:
                id_localizacao = local['id_localizacao']
                print(f"[LOG] Localizacao já existe -> id_localizacao={id_localizacao}")
            else:
                cursor.execute("""INSERT INTO localizacao (cep, numero, complemento, id_rua)
                                  VALUES (%s, %s, %s, %s)""",
                               (endereco.cep, endereco.numero, endereco.complemento, id_rua))
                id_localizacao = cursor.lastrowid
                print(f"[LOG] Localizacao inserida -> id_localizacao={id_localizacao}")

            conn.commit()
            print("=== create_localizacao finalizado ===")
            return id_localizacao

        except Exception as e:
            print("[ERRO] create_localizacao:", e)
            traceback.print_exc()
            conn.rollback()
            raise e
        finally:
            cursor.close()
            conn.close()

    @staticmethod
    def create_lead(lead: Lead):
        """Cria o lead no banco"""
        if not all([lead.nome_local, lead.responsavel, lead.telefone, lead.estado_leads, lead.id_usuario]):
            raise ValueError("Campos obrigatórios do lead estão vazios.",lead.nome_local, lead.responsavel, lead.telefone, lead.estado_leads, lead.id_usuario)

        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            query = """
                INSERT INTO leads (nome_local, nome_responsavel, id_localizacao,
                                   id_usuario, valor_proposta, categoria_venda, observacao, estado_leads)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            values = (
                lead.nome_local,
                lead.responsavel,
                lead.id_localizacao,
                lead.id_usuario,
                lead.valor,
                lead.categoria_venda,
                lead.observacao,
                lead.estado_leads
            )
            print("Valores para insert lead:", values)

            cursor.execute(query, values)
            conn.commit()
            inserted_id = cursor.lastrowid
            print(f"Lead inserido com sucesso -> id_lead={inserted_id}")
            
                # Inserir telefone na tabela telefone
            if lead.telefone:
                tel_query = """
                    INSERT INTO telefone (id_leads, telefone)
                    VALUES (%s, %s)
                """
                cursor.execute(tel_query, (inserted_id, lead.telefone))
                conn.commit()
                print(f"Telefone inserido com sucesso -> {lead.telefone}")

            return inserted_id

        except Exception as e:
            print("Erro em create_lead:", e)
            traceback.print_exc()
            conn.rollback()
            raise e
        finally:
            cursor.close()
            conn.close()

    @staticmethod
    def get_all():
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute("SELECT * FROM leads")
            results = cursor.fetchall()
            return results
        finally:
            cursor.close()
            conn.close()
