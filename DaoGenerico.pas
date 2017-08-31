unit DaoGenerico;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  Vcl.Graphics, REST.Json,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.Classes;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses UObjectClone, UDao, UContato, UCupom, UProduto, Generics.Collections,
  UDBConnection, UCliente, System.Json, Endereco;

procedure TForm1.Button1Click(Sender: TObject);
var
  teste1, teste2: TTeste;
begin
  teste1 := TTeste.Create;
  teste1.teste1 := 'Teste1';
  teste1.teste2 := 1;
  teste1.teste3 := 2.1;

  teste2 := TObjectClone.From(teste1);

  ShowMessage('String : ' + teste2.teste1 + ' | Integer = ' +
    teste2.teste2.ToString + '| Double = ' + teste2.teste3.ToString);
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  dao: TDAO;
  listaContato: TList<TContato>;
  listaProduto: TList<TProduto>;
  listaCupom: TList<TCupom>;
  listaCliente: TList<TCliente>;
  datai, dataf: TTime;
begin
  datai := Now;
  dao := TDAO.create(False);

  listaContato := dao.Query<TContato>('select first 3 * from contato');

  dataf := Now;

  if dao.CommitRelease then
    ShowMessage('Comiit realizado com sucesso!');


  ShowMessage(TimeToStr(dataf - datai));
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  TThread.Queue(nil,
    procedure
    var
      dao: TDAO;
      contato: TContato;
      cliente: TCliente;
    begin
      cliente := TCliente.Create;
      cliente.clienteid := 13;
      cliente.nome := 'nome 13';
      cliente.descricao := 'nome 13 teste';
      cliente.cpfcnpj := '08565412521';
      cliente.rgie := 'mg15456789';
      cliente.codigointerno := 1;
      cliente.status := 'Ativo';
      cliente.Endereco := TEndereco.Create;

      cliente.Endereco.numero := 13;
      cliente.Endereco.Endereco := 'Teste nome 13';

      dao := TDAO.Create;
      dao.Update<TCliente>(cliente);
      // dao.Insert<TCliente>(cliente);

      {
        contato := TContato.Create;
        contato.nome := 'Teste 1';
        contato.email := 'teste1@teste.com.br';
        contato.telefone := '33988823270';
        dao.Insert<TContato>(contato);
        ShowMessage(contato.ObjectToJSON<TContato>(contato).ToJSON);
        ShowMessage(TJson.ObjectToJsonString(contato)); }
      // contato := TJson.JsonToObject<TContato>('{"email":"teste1@teste.com.br","contatoid":0,"nome":"Volta","telefone":"33988823270"}');

      // ShowMessage(contato.nome);
    end);
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  dao: TDAO;
  listaClinente: TList<TCliente>;
begin
  listaClinente := dao.Query<TCliente>('SELECT * from cliente');

end;

procedure TForm1.Button5Click(Sender: TObject);
var
  dao: TDAO;
  cliente: TCliente;
begin
  cliente := TCliente.Create;
  cliente.clienteid := 2;
  cliente.nome := 'Teste 2';
  cliente.descricao := 'teste';
  cliente.cpfcnpj := '12345678945';
  cliente.rgie := 'mg12345645';
  cliente.codigointerno := 1;
  cliente.codigoweb := 1;
  cliente.status := 'Ativo';
  // cliente.excluido := False;

  dao := TDAO.Create;
  dao.Update<TContato>(cliente);

end;

procedure TForm1.Button6Click(Sender: TObject);
var
  cliente: TCliente;
  dao: TDAO;
begin
  cliente := TCliente.Create;
  cliente.nome := 'Teste 1';
  cliente.descricao := 'teste';
  cliente.cpfcnpj := '12345678945';
  cliente.rgie := 'mg12345645';
  cliente.codigointerno := 1;
  cliente.codigoweb := 1;
  cliente.status := 'Ativo';
  // cliente.excluido := False;

  dao := TDAO.Create;
  dao.Insert<TCliente>(cliente);

end;

procedure TForm1.Button7Click(Sender: TObject);
var
  cliente: TCliente;
  dao: TDAO;
begin
  cliente := TCliente.Create;
  cliente.clienteid := 1;

  dao := TDAO.Create;
  dao.Delete<TCliente>(cliente);

end;

procedure TForm1.Button8Click(Sender: TObject);
var
  dao: TDAO;
  contato: TContato;
  datai, dataf: TTime;
begin
  datai := Now;
  dao := TDAO.create(False);

  contato := dao.Get<TContato>(5);

  dataf := Now;

  if dao.CommitRelease then
    ShowMessage('Comiit realizado com sucesso!');


  ShowMessage(TimeToStr(dataf - datai));
end;

end.
