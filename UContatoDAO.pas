unit UContatoDAO;

interface

Uses
  UDAO, Generics.Collections, UContato;

type
  TContatoDAO = class(TDAO)
  public
    function CarregarContatos: TList<TContato>;
    procedure Salvar(contato: TContato);
    procedure Excluir(contato : TContato);
    function Carregar(codigo: Integer): TContato;
  end;

implementation

{ TContatoDAO }

function TContatoDAO.Carregar(codigo: Integer): TContato;
begin
  Result := Get<TContato>(codigo);
end;

function TContatoDAO.CarregarContatos: TList<TContato>;
begin
  Result := Query<TContato>('select * from contato ;');
end;

procedure TContatoDAO.Excluir(contato: TContato);
begin
  Delete<TContato>(contato);
end;

procedure TContatoDAO.Salvar(contato: TContato);
begin
  if contato.contatoid > 0 then
    Update<TContato>(contato)
  else
    Insert<TContato>(contato);
end;

end.
