class AllLeads:
    def __init__(self,
                 id_lead,
                 nome_local,
                 categoria_venda,
                 estado_leads,
                 id_localizacao,
                 nome_rua,
                 numero,
                 complemento,
                 nome_cidade,
                 uf,
                 nome_consultor,       # novo
                 nome_responsavel,     # novo
                 ultima_visita,        # novo
                 observacoes,
                 valor_proposta,
                 data_criacao):
        
        self.id_lead = id_lead
        self.nome_local = nome_local
        self.categoria_venda = categoria_venda
        self.estado_leads = estado_leads
        self.id_localizacao = id_localizacao
        
        self.nome_rua = nome_rua
        self.numero = numero
        self.complemento = complemento
        self.nome_cidade = nome_cidade
        self.uf = uf

        self.nome_consultor = nome_consultor
        self.nome_responsavel = nome_responsavel
        self.ultima_visita = ultima_visita

        self.observacoes = observacoes
        self.valor_proposta = valor_proposta
        self.data_criacao = data_criacao

    def to_dict(self):
        return self.__dict__
