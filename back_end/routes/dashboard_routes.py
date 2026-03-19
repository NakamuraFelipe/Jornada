from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
import traceback
from database import get_db_connection

dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/api/dashboard')

@dashboard_bp.route('/metricas', methods=['GET'])
def get_metricas():
    """Retorna os cards superiores do dashboard"""
    try:
        # Parâmetros de filtro
        id_usuario = request.args.get('id_usuario', type=int)
        estado = request.args.get('estado')
        cidade = request.args.get('cidade')
        bairro = request.args.get('bairro')
        categoria = request.args.get('categoria')
        data_inicio = request.args.get('data_inicio')
        data_fim = request.args.get('data_fim')
        valor_min = request.args.get('valor_min', type=float)
        valor_max = request.args.get('valor_max', type=float)

        conn = get_db_connection()
        cursor = conn.cursor()

        # Query base para totais
        query = """
            SELECT 
                COUNT(*) as total_leads,
                SUM(CASE WHEN estado_leads = 'fechada' THEN 1 ELSE 0 END) as total_fechados,
                SUM(CASE WHEN estado_leads = 'aberta' THEN 1 ELSE 0 END) as total_abertos,
                SUM(CASE WHEN estado_leads = 'conexao' THEN 1 ELSE 0 END) as total_conexao,
                SUM(CASE WHEN estado_leads = 'negociacao' THEN 1 ELSE 0 END) as total_negociacao,
                COALESCE(SUM(valor_proposta), 0) as valor_total,
                COALESCE(AVG(CASE WHEN YEAR(data_criacao) = YEAR(CURDATE()) THEN valor_proposta END), 0) as media_anual
            FROM leads l
            LEFT JOIN localizacao loc ON l.id_localizacao = loc.id_localizacao
            LEFT JOIN rua r ON loc.id_rua = r.id_rua
            LEFT JOIN bairro b ON r.id_bairro = b.id_bairro
            LEFT JOIN cidade c ON b.id_cidade = c.id_cidade
            LEFT JOIN estado e ON c.id_estado = e.id_estado
            WHERE 1=1
        """
        params = []

        if id_usuario:
            query += " AND l.id_usuario = %s"
            params.append(id_usuario)
        
        if estado and estado != 'Todos':
            query += " AND e.nome_estado = %s"
            params.append(estado)
        
        if cidade and cidade != 'Todas':
            query += " AND c.nome_cidade = %s"
            params.append(cidade)
        
        if bairro and bairro != 'Todos':
            query += " AND b.nome_bairro = %s"
            params.append(bairro)
        
        if categoria and categoria != 'Todas':
            query += " AND l.categoria_venda = %s"
            params.append(categoria.lower())
        
        if data_inicio:
            query += " AND DATE(l.data_criacao) >= %s"
            params.append(data_inicio)
        
        if data_fim:
            query += " AND DATE(l.data_criacao) <= %s"
            params.append(data_fim)
        
        if valor_min is not None:
            query += " AND l.valor_proposta >= %s"
            params.append(valor_min)
        
        if valor_max is not None:
            query += " AND l.valor_proposta <= %s"
            params.append(valor_max)

        cursor.execute(query, params)
        result = cursor.fetchone()

        # Calcular métricas derivadas
        total_leads = result['total_leads'] or 0
        total_fechados = result['total_fechados'] or 0
        taxa_conversao = (total_fechados / total_leads * 100) if total_leads > 0 else 0

        # Calcular cobertura de bairros
        cursor.execute("""
            SELECT COUNT(DISTINCT b.nome_bairro) as bairros_com_leads,
                   (SELECT COUNT(*) FROM bairro) as total_bairros
            FROM leads l
            LEFT JOIN localizacao loc ON l.id_localizacao = loc.id_localizacao
            LEFT JOIN rua r ON loc.id_rua = r.id_rua
            LEFT JOIN bairro b ON r.id_bairro = b.id_bairro
        """)
        cobertura = cursor.fetchone()
        cobertura_percent = (cobertura['bairros_com_leads'] / cobertura['total_bairros'] * 100) if cobertura['total_bairros'] > 0 else 0

        # Variações (comparação com mês anterior)
        cursor.execute("""
            SELECT 
                SUM(CASE WHEN estado_leads = 'fechada' THEN 1 ELSE 0 END) as fechados_mes_anterior
            FROM leads
            WHERE YEAR(data_criacao) = YEAR(CURDATE() - INTERVAL 1 MONTH)
            AND MONTH(data_criacao) = MONTH(CURDATE() - INTERVAL 1 MONTH)
        """)
        mes_anterior = cursor.fetchone()
        
        fechados_mes_anterior = mes_anterior['fechados_mes_anterior'] or 0
        variacao_fechados = ((total_fechados - fechados_mes_anterior) / fechados_mes_anterior * 100) if fechados_mes_anterior > 0 else 0

        cursor.close()
        conn.close()

        return jsonify({
            'status': 'ok',
            'dados': {
                'fechado': total_fechados,
                'abertos': result['total_abertos'] or 0,
                'conexao': result['total_conexao'] or 0,
                'negociacao': result['total_negociacao'] or 0,
                'total': total_leads,
                'conversao': round(taxa_conversao, 1),
                'cobertura': round(cobertura_percent, 1),
                'valor_total': float(result['valor_total']),
                'media_anual': float(result['media_anual']),
                'variacao_fechados': round(variacao_fechados, 1)
            }
        })

    except Exception as e:
        print("Erro em get_metricas:", e)
        traceback.print_exc()
        return jsonify({'status': 'erro', 'mensagem': str(e)}), 500


@dashboard_bp.route('/evolucao', methods=['GET'])
def get_evolucao():
    """Retorna dados para o gráfico de evolução"""
    try:
        periodo = request.args.get('periodo', 'Mes')  # Dia, Semana, Mes, Ano
        situacao = request.args.get('situacao', 'Todos')
        id_usuario = request.args.get('id_usuario', type=int)
        estado = request.args.get('estado')
        cidade = request.args.get('cidade')
        categoria = request.args.get('categoria')

        conn = get_db_connection()
        cursor = conn.cursor()

        # Definir agrupamento baseado no período
        if periodo == 'Dia':
            group_by = "DAYNAME(data_criacao)"
            order_by = "DAYOFWEEK(data_criacao)"
            limit = 7
            labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom']
        elif periodo == 'Semana':
            group_by = "WEEK(data_criacao)"
            order_by = "WEEK(data_criacao)"
            limit = 4
            labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4']
        elif periodo == 'Ano':
            group_by = "YEAR(data_criacao)"
            order_by = "YEAR(data_criacao)"
            limit = 5
            labels = []
        else:  # Mês (padrão)
            group_by = "MONTH(data_criacao)"
            order_by = "MONTH(data_criacao)"
            limit = 12
            labels = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 
                     'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez']

        # Construir a query
        query = f"""
            SELECT 
                {group_by} as periodo,
                COUNT(*) as total,
                SUM(CASE WHEN estado_leads = 'fechada' THEN 1 ELSE 0 END) as fechados,
                SUM(CASE WHEN estado_leads = 'aberta' THEN 1 ELSE 0 END) as abertos,
                SUM(CASE WHEN estado_leads = 'conexao' THEN 1 ELSE 0 END) as conexao,
                SUM(CASE WHEN estado_leads = 'negociacao' THEN 1 ELSE 0 END) as negociacao,
                COALESCE(SUM(valor_proposta), 0) as valor_total
            FROM leads l
            LEFT JOIN localizacao loc ON l.id_localizacao = loc.id_localizacao
            LEFT JOIN rua r ON loc.id_rua = r.id_rua
            LEFT JOIN bairro b ON r.id_bairro = b.id_bairro
            LEFT JOIN cidade c ON b.id_cidade = c.id_cidade
            LEFT JOIN estado e ON c.id_estado = e.id_estado
            WHERE 1=1
        """
        params = []

        if periodo != 'Ano':
            query += f" AND YEAR(data_criacao) = YEAR(CURDATE())"

        if id_usuario:
            query += " AND l.id_usuario = %s"
            params.append(id_usuario)
        
        if estado and estado != 'Todos':
            query += " AND e.nome_estado = %s"
            params.append(estado)
        
        if cidade and cidade != 'Todas':
            query += " AND c.nome_cidade = %s"
            params.append(cidade)
        
        if categoria and categoria != 'Todas':
            query += " AND l.categoria_venda = %s"
            params.append(categoria.lower())

        query += f" GROUP BY periodo ORDER BY {order_by} LIMIT %s"
        params.append(limit)

        cursor.execute(query, params)
        results = cursor.fetchall()

        # Processar resultados
        dados = []
        if situacao == 'Aberto':
            campo = 'abertos'
        elif situacao == 'Fechado':
            campo = 'fechados'
        elif situacao == 'Em Conexão':
            campo = 'conexao'
        else:
            campo = 'total'

        for row in results:
            dados.append(float(row[campo] or 0))

        # Garantir que temos dados para todos os períodos
        while len(dados) < limit:
            dados.append(0)

        cursor.close()
        conn.close()

        return jsonify({
            'status': 'ok',
            'dados': dados,
            'labels': labels[:len(dados)]
        })

    except Exception as e:
        print("Erro em get_evolucao:", e)
        traceback.print_exc()
        return jsonify({'status': 'erro', 'mensagem': str(e)}), 500


@dashboard_bp.route('/leads-por-bairro', methods=['GET'])
def get_leads_por_bairro():
    """Retorna distribuição de leads por bairro"""
    try:
        id_usuario = request.args.get('id_usuario', type=int)
        estado = request.args.get('estado')
        cidade = request.args.get('cidade')
        limit = request.args.get('limit', 5, type=int)

        conn = get_db_connection()
        cursor = conn.cursor()

        query = """
            SELECT 
                b.nome_bairro,
                COUNT(*) as total_leads,
                SUM(CASE WHEN l.estado_leads = 'fechada' THEN 1 ELSE 0 END) as fechados,
                COALESCE(SUM(l.valor_proposta), 0) as valor_total
            FROM leads l
            JOIN localizacao loc ON l.id_localizacao = loc.id_localizacao
            JOIN rua r ON loc.id_rua = r.id_rua
            JOIN bairro b ON r.id_bairro = b.id_bairro
            JOIN cidade c ON b.id_cidade = c.id_cidade
            JOIN estado e ON c.id_estado = e.id_estado
            WHERE 1=1
        """
        params = []

        if id_usuario:
            query += " AND l.id_usuario = %s"
            params.append(id_usuario)
        
        if estado and estado != 'Todos':
            query += " AND e.nome_estado = %s"
            params.append(estado)
        
        if cidade and cidade != 'Todas':
            query += " AND c.nome_cidade = %s"
            params.append(cidade)

        query += " GROUP BY b.nome_bairro ORDER BY total_leads DESC LIMIT %s"
        params.append(limit)

        cursor.execute(query, params)
        results = cursor.fetchall()

        leads_por_bairro = {}
        conversao_por_bairro = {}

        for row in results:
            bairro = row['nome_bairro']
            leads_por_bairro[bairro] = row['total_leads']
            if row['total_leads'] > 0:
                conversao = row['fechados'] / row['total_leads']
                conversao_por_bairro[bairro] = round(conversao, 2)

        cursor.close()
        conn.close()

        return jsonify({
            'status': 'ok',
            'leads_por_bairro': leads_por_bairro,
            'conversao_por_bairro': conversao_por_bairro
        })

    except Exception as e:
        print("Erro em get_leads_por_bairro:", e)
        traceback.print_exc()
        return jsonify({'status': 'erro', 'mensagem': str(e)}), 500


@dashboard_bp.route('/top-consultores', methods=['GET'])
def get_top_consultores():
    """Retorna ranking dos melhores consultores"""
    try:
        limit = request.args.get('limit', 5, type=int)

        conn = get_db_connection()
        cursor = conn.cursor()

        query = """
            SELECT 
                u.id_usuario,
                u.nome_usuario,
                COUNT(l.id_leads) as total_leads,
                SUM(CASE WHEN l.estado_leads = 'fechada' THEN 1 ELSE 0 END) as fechados,
                COALESCE(SUM(l.valor_proposta), 0) as valor_total,
                COUNT(DISTINCT v.id_visita) as total_visitas
            FROM usuario u
            LEFT JOIN leads l ON u.id_usuario = l.id_usuario
            LEFT JOIN visita v ON l.id_leads = v.id_leads
            WHERE u.cargo IN ('consultor', 'supervisor')
            GROUP BY u.id_usuario, u.nome_usuario
            ORDER BY fechados DESC, valor_total DESC
            LIMIT %s
        """

        cursor.execute(query, (limit,))
        results = cursor.fetchall()

        consultores = []
        for row in results:
            taxa_conversao = (row['fechados'] / row['total_leads'] * 100) if row['total_leads'] > 0 else 0
            consultores.append({
                'nome': row['nome_usuario'],
                'visitas': row['total_visitas'] or 0,
                'fechados': row['fechados'] or 0,
                'valor': float(row['valor_total']),
                'taxa_conversao': round(taxa_conversao, 1)
            })

        cursor.close()
        conn.close()

        return jsonify({
            'status': 'ok',
            'consultores': consultores
        })

    except Exception as e:
        print("Erro em get_top_consultores:", e)
        traceback.print_exc()
        return jsonify({'status': 'erro', 'mensagem': str(e)}), 500


@dashboard_bp.route('/alertas', methods=['GET'])
def get_alertas():
    """Retorna alertas e ações prioritárias"""
    try:
        id_usuario = request.args.get('id_usuario', type=int)

        conn = get_db_connection()
        cursor = conn.cursor()

        alertas = []

        # 1. Leads sem contato há mais de 15 dias
        query = """
            SELECT COUNT(*) as total
            FROM leads l
            LEFT JOIN visita v ON l.id_leads = v.id_leads
            WHERE (v.data_visita IS NULL OR v.data_visita < DATE_SUB(CURDATE(), INTERVAL 15 DAY))
            AND l.estado_leads IN ('aberta', 'conexao')
        """
        params = []
        if id_usuario:
            query += " AND l.id_usuario = %s"
            params.append(id_usuario)
        
        cursor.execute(query, params)
        result = cursor.fetchone()
        if result['total'] > 0:
            alertas.append({
                'tipo': 'alerta',
                'icone': 'warning',
                'cor': 'orange',
                'mensagem': f"{result['total']} leads sem contato há 15+ dias"
            })

        # 2. Visitas com retorno atrasado
        cursor.execute("""
            SELECT COUNT(*) as total
            FROM visita
            WHERE retorno IS NOT NULL 
            AND retorno < CURDATE()
            AND id_leads IN (SELECT id_leads FROM leads WHERE estado_leads != 'fechada')
        """)
        result = cursor.fetchone()
        if result['total'] > 0:
            alertas.append({
                'tipo': 'urgente',
                'icone': 'access_time',
                'cor': 'red',
                'mensagem': f"{result['total']} visitas com retorno atrasado"
            })

        # 3. Leads com alta probabilidade (em negociação)
        cursor.execute("""
            SELECT COUNT(*) as total
            FROM leads
            WHERE estado_leads = 'negociacao'
            AND valor_proposta > 50000
        """)
        result = cursor.fetchone()
        if result['total'] > 0:
            alertas.append({
                'tipo': 'oportunidade',
                'icone': 'trending_up',
                'cor': 'green',
                'mensagem': f"{result['total']} leads com alta probabilidade (>R$50k)"
            })

        # 4. Meta mensal
        cursor.execute("""
            SELECT 
                COALESCE(SUM(valor_proposta), 0) as total_mes,
                COUNT(*) as leads_mes
            FROM leads
            WHERE MONTH(data_criacao) = MONTH(CURDATE())
            AND YEAR(data_criacao) = YEAR(CURDATE())
            AND estado_leads = 'fechada'
        """)
        meta = cursor.fetchone()
        
        # Meta exemplo: R$ 500k por mês
        meta_mensal = 500000
        progresso = (meta['total_mes'] / meta_mensal) * 100

        cursor.close()
        conn.close()

        return jsonify({
            'status': 'ok',
            'alertas': alertas,
            'meta': {
                'atual': float(meta['total_mes']),
                'meta': meta_mensal,
                'progresso': round(progresso, 1),
                'dias_restantes': (datetime.now().replace(day=28) + timedelta(days=4)).day - datetime.now().day
            }
        })

    except Exception as e:
        print("Erro em get_alertas:", e)
        traceback.print_exc()
        return jsonify({'status': 'erro', 'mensagem': str(e)}), 500


@dashboard_bp.route('/filtros/locais', methods=['GET'])
def get_opcoes_filtros():
    """Retorna opções para os filtros (estados, cidades, etc)"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Estados
        cursor.execute("SELECT DISTINCT nome_estado FROM estado ORDER BY nome_estado")
        estados = [row['nome_estado'] for row in cursor.fetchall()]

        # Cidades (com estado)
        cursor.execute("""
            SELECT c.nome_cidade, e.nome_estado 
            FROM cidade c
            JOIN estado e ON c.id_estado = e.id_estado
            ORDER BY c.nome_cidade
        """)
        cidades = cursor.fetchall()

        # Bairros (com cidade)
        cursor.execute("""
            SELECT b.nome_bairro, c.nome_cidade
            FROM bairro b
            JOIN cidade c ON b.id_cidade = c.id_cidade
            ORDER BY b.nome_bairro
        """)
        bairros = cursor.fetchall()

        # Categorias
        cursor.execute("""
            SELECT DISTINCT categoria_venda 
            FROM leads 
            WHERE categoria_venda IS NOT NULL
        """)
        categorias = [row['categoria_venda'] for row in cursor.fetchall()]

        cursor.close()
        conn.close()

        return jsonify({
            'status': 'ok',
            'estados': ['Todos'] + estados,
            'cidades': cidades,
            'bairros': bairros,
            'categorias': ['Todas'] + categorias
        })

    except Exception as e:
        print("Erro em get_opcoes_filtros:", e)
        traceback.print_exc()
        return jsonify({'status': 'erro', 'mensagem': str(e)}), 500