unit UProduto;

interface

Uses
  UAttributes;

type

  [Tabela('produtos')]
  TProduto = class
  private
    Fprodutoid: Integer;
    Fnome: string;
    Fnomefiscal: string;
    Fcodigobarra: string;
    Fpreco: Double;
    Fcomposto: Boolean;
  public
    [CampoAttribute('produtos_id', tpInteger)]
    property produtoid: Integer read Fprodutoid write Fprodutoid;
    [CampoAttribute('produto_nome', tpString)]
    property nome: string read Fnome write Fnome;
    [CampoAttribute('produto_nome_fiscal', tpString)]
    property nomefiscal: string read Fnomefiscal write Fnomefiscal;
    [CampoAttribute('produto_cod_barras', tpString)]
    property codigobarra: string read Fcodigobarra write Fcodigobarra;
    [CampoAttribute('produto_preco', tpFloat)]
    property preco: Double read Fpreco write Fpreco;
    [CampoAttribute('produto_composto', tpBoleano)]
    property composto: Boolean read Fcomposto write Fcomposto;

  end;

implementation

end.
