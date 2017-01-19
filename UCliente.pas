unit UCliente;

interface

Uses
  UAttributes, Endereco;

type

  [Tabela('cliente')]
  TCliente = class
  private
    Fclienteid: Integer;
    Fnome: String;
    Fname: string;
    Fcpfcnpj: String;
    Frgie: String;
    Fcodigointerno: Integer;
    Fcodigoweb: Integer;
    Fstatus: String;
    Fexcluido: Boolean;
    Fendereco: TEndereco;
  public
    [IdAttribute]
    [AutoIncrementoAttribute('cliente_clienteid_seq')]
    [CampoAttribute('clienteid', tpInteger)]
    property clienteid: Integer read Fclienteid write Fclienteid;
    [CampoAttribute('nome', tpString)]
    property nome: String read Fnome write Fnome;
    [CampoAttribute('descricao', tpString)]
    property descricao: string read Fname write Fname;
    [CampoAttribute('cpfcnpj', tpString)]
    property cpfcnpj: String read Fcpfcnpj write Fcpfcnpj;
    [CampoAttribute('rgie', tpString)]
    property rgie: String read Frgie write Frgie;
    [CampoAttribute('codigointerno', tpInteger)]
    property codigointerno: Integer read Fcodigointerno write Fcodigointerno;
    [CampoAttribute('codigoweb', tpInteger)]
    property codigoweb: Integer read Fcodigoweb write Fcodigoweb;
    [CampoAttribute('status', tpString)]
    property status: String read Fstatus write Fstatus;
   // [CampoAttribute('excluido', tpBoleano)]
//    property excluido: Boolean read Fexcluido write Fexcluido;
    [CampoAttribute('endereco', tpJsonb, 'Endereco.TEndereco')]
    property endereco: TEndereco read Fendereco write Fendereco;

  end;

implementation

end.
