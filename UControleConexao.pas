unit UControleConexao;

interface

uses
  System.Generics.Collections, System.Classes, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Comp.Client, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, FireDAC.Phys.IBBase,
  FireDAC.Phys.FB, FireDAC.Phys.PG;

type
  TConnetion = class(TFDConnection)
  private
    Fid: Integer;
    Fquery: TFDQuery;
    FDPhysPgDriverLink: TFDPhysPgDriverLink;
    Fautocommit: Boolean;
  public
    property id: Integer read Fid write Fid;
    property autocommit: Boolean read Fautocommit write Fautocommit;
    property DPhysPgDriverLink: TFDPhysPgDriverLink read FDPhysPgDriverLink
      write FDPhysPgDriverLink;
    property query: TFDQuery read Fquery write Fquery;
  end;

type
  TConexoesLista = Class(TThreadList<TConnetion>)
  private
    FMaxId: Integer;
    class var FInstance: TConexoesLista;

    function getConnectionPorId(id: Integer): TConnetion;
    function createConnection: TConnetion;
    constructor CreatePrivate;
  public
    property MaxId: Integer read FMaxId write FMaxId;
    class function Acquire(id: Integer = 0): TConnetion;
    class procedure Release(AConnection: TConnetion);
    constructor create;
  End;

implementation

uses
  USystemConfig;

{ TConexoesLista }

class function TConexoesLista.Acquire(id: Integer): TConnetion;
begin
  if FInstance = nil then
    FInstance := TConexoesLista.create;

  if id > 0 then
  begin
    Result := FInstance.getConnectionPorId(id);
    if Result <> nil then
      Exit;
  end;

  Exit(FInstance.createConnection);
end;

constructor TConexoesLista.create;
begin
  inherited;
  FMaxId := 0;
end;

function TConexoesLista.createConnection: TConnetion;
begin
  Result := TConnetion.create(nil);

  if TSystemConfig.GetInstancia.tipoSGBD = tpPostgreSQL then
  begin
    Result.DPhysPgDriverLink := TFDPhysPgDriverLink.create(nil);
    Result.DPhysPgDriverLink.VendorHome :=
      TSystemConfig.GetInstancia.caminhoaplicacao + '\pgbin32\';
    Result.DPhysPgDriverLink.VendorLib := 'libpq.dll';
    Result.DPhysPgDriverLink.Release;
    Result.DriverName := 'PG';
  end
  else
    Result.DriverName := 'FB';

  Result.LoginPrompt := False;
  Result.Params.Values['User_Name'] := TSystemConfig.GetInstancia.username;
  // 'SYSDBA';
  Result.Params.Values['Password'] := TSystemConfig.GetInstancia.password;
  // 'masterkey';
  Result.Params.Values['Protocol'] := 'TCPIP';
  Result.Params.Values['Server'] := TSystemConfig.GetInstancia.server;
  // 'localhost';
  Result.Params.Values['Database'] := TSystemConfig.GetInstancia.database;

  Result.Params.Values['CharacterSet'] := TSystemConfig.GetInstancia.charset;
  // 'ISO8859_1';

  Result.Open;


  Result.query := TFDQuery.Create(nil);
  Result.query.Connection := Result;
  Result.query.FetchOptions.Mode := fmAll;
  Result.query.FetchOptions.Unidirectional := False;
  // Fquery.FetchOptions.RecordCountMode := cmTotal;

  Result.id := FInstance.MaxId + 1;
  FInstance.FMaxId := Result.id;

  FInstance.Add(Result);
end;

constructor TConexoesLista.CreatePrivate;
begin
  FInstance := TConexoesLista.create;
end;

function TConexoesLista.getConnectionPorId(id: Integer): TConnetion;
var
  conn: TConnetion;
  myList: TList<TConnetion>;
begin
  myList := Self.LockList;
  for conn in myList do
    if conn.id = id then
      Exit(conn);

  Result := nil;
end;

class procedure TConexoesLista.Release(AConnection: TConnetion);
begin
  FInstance.Remove(AConnection);
  AConnection.FreeOnRelease;
end;

end.
