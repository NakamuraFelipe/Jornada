import pymysql
from database import get_db_connection
from models.meus_leads import MeusLeads

class MeusLeadsDAO:

    @staticmethod
    def buscar_leads(query, id_usuario):
        conn = get_db_connection()
        cursor = conn.cursor(pymysql.cursors.DictCursor)

        # ----------------------------------------------
        # 1 — Buscar ID(s) da rua pelo nome digitado
        # ----------------------------------------------
        cursor.execute("""
            SELECT id_rua 
            FROM rua 
            WHERE nome_rua LIKE %s
        """, (f"%{query}%",))
        ruas = cursor.fetchall()
        id_ruas = [r["id_rua"] for r in ruas]

        # ----------------------------------------------
        # 2 — Buscar ID(s) da localizacao para essas ruas
        # ----------------------------------------------
        id_localizacoes = []
        if id_ruas:
            in_tuple = tuple(id_ruas)
            cursor.execute(f"""
                SELECT id_localizacao
                FROM localizacao
                WHERE id_rua IN {in_tuple}
            """)
            locs = cursor.fetchall()
            id_localizacoes = [l["id_localizacao"] for l in locs]

        # ----------------------------------------------
        # 3 — Query principal
        # ----------------------------------------------

        sql = """
        SELECT 
            l.id_leads,
            l.nome_local,
            l.categoria_venda,
            l.estado_leads,
            l.id_localizacao,

            lo.numero,
            lo.complemento,

            r.nome_rua,
            c.nome_cidade,
            e.uf,

            l.nome_responsavel,
            l.observacao,
            l.valor_proposta,
            l.data_criacao

        FROM leads l
        INNER JOIN localizacao lo ON lo.id_localizacao = l.id_localizacao
        INNER JOIN rua r ON r.id_rua = lo.id_rua
        INNER JOIN bairro b ON b.id_bairro = r.id_bairro
        INNER JOIN cidade c ON c.id_cidade = b.id_cidade
        INNER JOIN estado e ON e.id_estado = c.id_estado

        WHERE l.id_usuario = %s
          AND (
                l.nome_local LIKE %s
                OR l.categoria_venda LIKE %s
                OR l.estado_leads LIKE %s
                OR (%s != '' AND l.id_localizacao = %s)
             )
        """

        like = f"%{query}%"
        id_localizacao_filter = int(query) if query.isdigit() else None
        id_localizacao_check = query if query.isdigit() else ""

        cursor.execute(sql, (
            id_usuario,
            like, like, like,
            id_localizacao_check, id_localizacao_filter
        ))

        rows = cursor.fetchall()

        # ----------------------------------------------
        # Converter rows → OBJETO MeusLeads
        # ----------------------------------------------
        leads = []
        for row in rows:
            lead_obj = MeusLeads(
                id_lead=row["id_leads"],
                nome_local=row["nome_local"],
                categoria_venda=row["categoria_venda"],
                estado_leads=row["estado_leads"],
                id_localizacao=row["id_localizacao"],

                nome_rua=row["nome_rua"],
                numero=row["numero"],
                complemento=row["complemento"],
                nome_cidade=row["nome_cidade"],
                uf=row["uf"],

                nome_consultor=None,        # ainda não existe no SELECT
                ultima_visita=None,         # ainda não existe no SELECT
                observacoes=row["observacao"],
                valor_proposta=row["valor_proposta"],
                data_criacao=str(row["data_criacao"])
            )

            leads.append(lead_obj)

        cursor.close()
        conn.close()
        return leads
