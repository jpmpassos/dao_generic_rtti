unit UContato;

interface

Uses
  UAttributes, UBaseObject;

type

  [Tabela('contato')]
  TContato = class(TBaseObject)
  private
    Femail: String;
    Fcontatoid: Integer;
    Fnome: String;
    Ftelefone: String;

  public
    [IdAttribute]
    [AutoIncrementoAttribute]
    [CampoAttribute('contatoid', tpInteger)]
    property contatoid: Integer read Fcontatoid write Fcontatoid;
    [CampoAttribute('nome', tpString)]
    property nome: String read Fnome write Fnome;
    [CampoAttribute('email', tpString)]
    property email: String read Femail write Femail;
    [CampoAttribute('telefone', tpString)]
    property telefone: String read Ftelefone write Ftelefone;
  end;

implementation

end.
