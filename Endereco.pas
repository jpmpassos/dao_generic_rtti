unit Endereco;

interface

Uses
  UAttributes;

type
  TEndereco = class
  private
    Fnumero: Integer;
    Fendereco: string;
  public
    [CampoAttribute('numero', tpInteger)]
    property numero: Integer read Fnumero write Fnumero;
    [CampoAttribute('endereco', tpString)]
    property Endereco: string read Fendereco write Fendereco;
  end;

implementation

end.
