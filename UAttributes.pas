unit UAttributes;

interface

type
  TTipo = (tpSemDeclarar, tpBoleano, tpDataTime, tpCurrency, tpFloat, tpInteger,
    tpString, tpByte, tpTime, tpData, tpVariant, tpJsonb);

type
  TabelaAttribute = class(TCustomAttribute)
  private
    Fnome: string;
  public
    constructor Create(pNome: string);
    property nome: string read Fnome write Fnome;
  end;

type
  CampoAttribute = class(TCustomAttribute)
  private
    Fnome: string;
    Ftipo: TTipo;
    Fclassobj: string;
  public
    constructor Create(pNome: String; T: TTipo = tpSemDeclarar;
      pClassobj: string = '');

    property nome: string read Fnome write Fnome;
    property tipo: TTipo read Ftipo write Ftipo;
    property classobj: string read Fclassobj write Fclassobj;
  end;

type
  IdAttribute = class(TCustomAttribute)
  private
  public
  end;

type
  AutoIncrementoAttribute = class(TCustomAttribute)
  private
    Fsequencia: String;
  public
    constructor Create(pSequenci: String = '');
    property sequencia: String read Fsequencia write Fsequencia;
  end;

implementation

{ TTabelaAttributes }

constructor TabelaAttribute.Create(pNome: string);
begin
  Self.Fnome := pNome;
end;

{ TCampoAttributes }

constructor CampoAttribute.Create(pNome: String; T: TTipo; pClassobj: string);
begin
  Self.Fnome := pNome;
  Self.Ftipo := T;
  Self.Fclassobj := pClassobj;
end;

{ AutoIncrementoAttribute }

constructor AutoIncrementoAttribute.Create(pSequenci: String);
begin
  Self.Fsequencia := pSequenci;
end;

end.
