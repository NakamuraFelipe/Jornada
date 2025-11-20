class Address:
    def __init__(self, cep=None, pais=None, estado=None, cidade=None, bairro=None, rua=None, numero=None, complemento=None):
        self.cep = cep
        self.pais = pais
        self.estado = estado
        self.cidade = cidade
        self.bairro = bairro
        self.rua = rua
        self.numero = numero
        self.complemento = complemento

    @classmethod
    def from_json(cls, data):
        return cls(
            cep=data.get('cep'),
            pais=data.get('pais'),
            estado=data.get('estado'),
            cidade=data.get('cidade'),
            bairro=data.get('bairro'),
            rua=data.get('rua'),
            numero=data.get('numero'),
            complemento=data.get('complemento')
        )


class Lead:
    def __init__(self, nome_local, responsavel, telefone, endereco: Address, estado_leads,
                 categoria_venda=None, observacao=None, valor=None, id_usuario=None):
        self.nome_local = nome_local
        self.responsavel = responsavel
        self.telefone = telefone
        self.endereco = endereco
        self.estado_leads = estado_leads
        self.categoria_venda = categoria_venda
        self.observacao = observacao
        self.valor = valor
        self.id_usuario = id_usuario
        self.id_localizacao = None  # inicializa como None

    @classmethod
    def from_json(cls, data):
        endereco = Address.from_json(data.get('endereco', {}))  # pega dict do endereço
        return cls(
            nome_local=data.get('nome_local'),
            responsavel=data.get('nome_responsavel'),
            telefone=data.get('telefone'),
            endereco=endereco,
            estado_leads=data.get('estado_leads'),
            categoria_venda=data.get('categoria_venda'),
            observacao=data.get('observacao'),
            valor=data.get('valor_proposta'),
            id_usuario=data.get('id_usuario')
        )
