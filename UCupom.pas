unit UCupom;

interface

Uses
  UAttributes;

type

  [Tabela('cupons')]
  TCupom = class
  private
    Fcupomid: Integer;
    Fstatus: String;
    Ftotalliquido: Double;
    Ftotalbruto: Double;
    Fnomeconsumidor: string;
    Fmovimentoid: Integer;
    Ffuncionarioid: Integer;
    Fclienteid: Integer;
    Fecfcaixa: Integer;
    Fecfnumeroadicional: Boolean;
    Fecfnumerofab: String;
    Fecfmodelo: string;
    Fecfnumusuario: Integer;
    Fecfccf: Integer;
    Fecfcoo: Integer;
    Femissao: TDate;
    Fdescontoacrescimo: Double;
    Ftotalrecebido: Double;
    Ftotaltroco: Double;
    Fcancelado: Boolean;
    Fdav: Boolean;
    Fprevendo: Boolean;
    Ffidelidadeid: Integer;
    Fecfmarca: string;
    Fdescontoacrescimoitem: Double;
    Fnotamanual: string;
    Fdavidentificador: string;
    Fobservacao: string;
    Fdependenteid: Integer;
    Fvalorimportacao: Integer;
    Flogimportacao: string;
    Futilizatef: Boolean;
    Fstatustef: Integer;

  public
    [PrimaryKeyAttribute(true)]
    [CampoAttribute('cupons_id', tpInteger)]
    property cupomid: Integer read Fcupomid write Fcupomid;
    [CampoAttribute('cupom_status', tpString)]
    property status: String read Fstatus write Fstatus;
    [CampoAttribute('cupom_total_liquido', tpFloat)]
    property totalliquido: Double read Ftotalliquido write Ftotalliquido;
    [CampoAttribute('cupom_total_bruto', tpFloat)]
    property totalbruto: Double read Ftotalbruto write Ftotalbruto;
    [CampoAttribute('cupom_nome_cons_final', tpString)]
    property nomeconsumidor: string read Fnomeconsumidor write Fnomeconsumidor;
    [CampoAttribute('movimentos_id', tpInteger)]
    property movimentoid: Integer read Fmovimentoid write Fmovimentoid;
    [CampoAttribute('funcionarios_id', tpInteger)]
    property funcionarioid: Integer read Ffuncionarioid write Ffuncionarioid;
    [CampoAttribute('clientes_id', tpInteger)]
    property clienteid: Integer read Fclienteid write Fclienteid;
    [CampoAttribute('cupom_ecf_caixa', tpInteger)]
    property ecfcaixa: Integer read Fecfcaixa write Fecfcaixa;
    [CampoAttribute('cupom_ecf_num_fabrica', tpString)]
    property ecfnumerofab: String read Fecfnumerofab write Fecfnumerofab;
    [CampoAttribute('cupom_ecf_mf_adicional', tpBoleano)]
    property ecfnumeroadicional: Boolean read Fecfnumeroadicional
      write Fecfnumeroadicional;
    [CampoAttribute('cupom_ecf_modelo', tpString)]
    property ecfmodelo: string read Fecfmodelo write Fecfmodelo;
    [CampoAttribute('cupom_ecf_num_usuario', tpInteger)]
    property ecfnumusuario: Integer read Fecfnumusuario write Fecfnumusuario;
    [CampoAttribute('cupom_ecf_ccf', tpInteger)]
    property ecfccf: Integer read Fecfccf write Fecfccf;
    [CampoAttribute('cupom_ecf_coo', tpInteger)]
    property ecfcoo: Integer read Fecfcoo write Fecfcoo;
    [CampoAttribute('cupom_data_emissao', tpData)]
    property emissao: TDate read Femissao write Femissao;
    [CampoAttribute('cupom_desc_acre', tpFloat)]
    property descontoacrescimo: Double read Fdescontoacrescimo
      write Fdescontoacrescimo;
    [CampoAttribute('cupom_total_recebido', tpFloat)]
    property totalrecebido: Double read Ftotalrecebido write Ftotalrecebido;
    [CampoAttribute('cupom_total_troco', tpFloat)]
    property totaltroco: Double read Ftotaltroco write Ftotaltroco;
    [CampoAttribute('cupom_cancelado', tpBoleano)]
    property cancelado: Boolean read Fcancelado write Fcancelado;
    [CampoAttribute('cupom_dav', tpBoleano)]
    property dav: Boolean read Fdav write Fdav;
    [CampoAttribute('cupom_pre_venda', tpBoleano)]
    property prevendo: Boolean read Fprevendo write Fprevendo;
    [CampoAttribute('cliente_fidelidade_id', tpInteger)]
    property fidelidadeid: Integer read Ffidelidadeid write Ffidelidadeid;
    [CampoAttribute('cupom_ecf_marca', tpString)]
    property ecfmarca: string read Fecfmarca write Fecfmarca;
    [CampoAttribute('cupom_desc_acre_item', tpFloat)]
    property descontoacrescimoitem: Double read Fdescontoacrescimoitem
      write Fdescontoacrescimoitem;
  end;

implementation

end.
