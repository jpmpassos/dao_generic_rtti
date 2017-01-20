unit UDBConnection;

interface

uses FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error,
  FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Comp.Client, FireDAC.VCLUI.Wait,
  FireDAC.Comp.UI, FireDAC.Phys.IBBase, FireDAC.Phys.FB, FireDAC.Phys.PG;

type
  TDBConnection = class
  strict private
    Fconexao: TFDConnection;
    Fquery: TFDQuery;
    FDPhysPgDriverLink: TFDPhysPgDriverLink;
    class var Fautocommit: Boolean;
    class var FInstance: TDBConnection;

    constructor CreatePrivate;
    procedure carregarPG;
    procedure carregarFB;
    procedure getTFDConnection();
  public
    constructor Create;
    class function GetInstance: TDBConnection;
    property query: TFDQuery read Fquery write Fquery;
    class property autocommit: Boolean read Fautocommit write Fautocommit;

    class procedure iniciarTransacao();
    class procedure fecharTransacao();

  end;

implementation

uses
  System.SysUtils, Vcl.Forms, USystemConfig;

{ TDBConnection }

constructor TDBConnection.Create;
begin
  raise Exception.Create
    ('Para obter uma instância de TDBConnection    utilize  TDBConnection.GetInatance ');
end;

constructor TDBConnection.CreatePrivate;
begin
  if TSystemConfig.GetInstancia.tipoSGBD = tpFirebird then
  begin
    carregarFB;
  end
  else if TSystemConfig.GetInstancia.tipoSGBD = tpPostgreSQL then
  begin
    carregarPG
  end;

  Fquery := TFDQuery.Create(nil);
  Fquery.Connection := Fconexao;
  Fquery.FetchOptions.Mode := fmAll;
  Fquery.FetchOptions.Unidirectional := False;
  // Fquery.FetchOptions.RecordCountMode := cmTotal;
  FInstance.autocommit := true;

end;

class procedure TDBConnection.fecharTransacao;
begin
  try
    try
      FInstance.autocommit := true;
      FInstance.query.Connection.Commit;
    except
      on E: Exception do
      begin
        try
          if FInstance.query.Connection.InTransaction then
            FInstance.query.Connection.Rollback;
        finally
          raise Exception.Create('Erro ao realizar commit. Erro: ' + E.Message);
        end;
      end;
    end;
  finally
    try
      if Assigned(FInstance.query) then
      begin
        FInstance.query.Close;
        FreeAndNil(FInstance.Fquery);
      end;
    except
      on E: Exception do
    end;

    try
      if Assigned(FInstance.Fconexao) then
      begin
        FreeAndNil(FInstance.Fconexao);
      end;
    except
      on E: Exception do
    end;

    try
      if Assigned(FInstance) then
      begin
        FreeAndNil(FInstance);
      end;
    except
      on E: Exception do
    end;
  end;

end;

class function TDBConnection.GetInstance: TDBConnection;
begin
  if not Assigned(FInstance) then
    FInstance := TDBConnection.CreatePrivate;

  Result := FInstance;
end;

procedure TDBConnection.getTFDConnection;
begin

  Fconexao := TFDConnection.Create(nil);
  with Fconexao do
  begin
    DriverName := 'FB';
    LoginPrompt := False;
    Params.Add('User_Name=SYSDBA');
    Params.Add('Password= masterkey');
    Params.Add('Protocol=TCPIP');
    Params.Add('Server=localhost');
    // Params.Add('Database=' + ExtractFileDir(Application.ExeName) +
    // '\DB\DBCONTATO.FDB');

    Params.Add('Database=' + ExtractFileDir(Application.ExeName) +
      '\DB\DB_PAF_ECF.FDB');
    Params.Add('CharacterSet=ISO8859_1');

    Open;
  end;
end;

procedure TDBConnection.carregarFB;
begin
  Fconexao := TFDConnection.Create(nil);

  Fconexao.DriverName := 'FB';
  Fconexao.LoginPrompt := False;
  Fconexao.Params.Values['User_Name'] := TSystemConfig.GetInstancia.username;//'SYSDBA';
  Fconexao.Params.Values['Password'] := TSystemConfig.GetInstancia.password;//'masterkey';
  Fconexao.Params.Values['Protocol'] := 'TCPIP';
  Fconexao.Params.Values['Server'] := TSystemConfig.GetInstancia.server;//'localhost';
  Fconexao.Params.Values['Database'] := TSystemConfig.GetInstancia.database;//ExtractFileDir(Application.ExeName) +    '\DB\DB_PAF_ECF.FDB';
  Fconexao.Params.Values['CharacterSet'] := TSystemConfig.GetInstancia.charset;//'ISO8859_1';

  Fconexao.Open;
end;


procedure TDBConnection.carregarPG;
begin
  FDPhysPgDriverLink := TFDPhysPgDriverLink.Create(nil);
  FDPhysPgDriverLink.VendorHome := ExtractFileDir(Application.ExeName) +
    '\pgbin32\';
  FDPhysPgDriverLink.VendorLib := 'libpq.dll';
  FDPhysPgDriverLink.Release;

  Fconexao := TFDConnection.Create(nil);

  Fconexao.DriverName := 'PG';
  Fconexao.LoginPrompt := False;
  Fconexao.Params.Values['User_Name'] := TSystemConfig.GetInstancia.username;
  Fconexao.Params.Values['Password'] := TSystemConfig.GetInstancia.password;
  Fconexao.Params.Values['Protocol'] := 'TCPIP';
  Fconexao.Params.Values['Server'] := TSystemConfig.GetInstancia.server;
  Fconexao.Params.Values['Port'] := TSystemConfig.GetInstancia.port;
  Fconexao.Params.Values['Database'] := TSystemConfig.GetInstancia.database;

  Fconexao.Open;
end;

class procedure TDBConnection.iniciarTransacao;
begin
  GetInstance;
  FInstance.autocommit := False;
  FInstance.query.Connection.StartTransaction;
end;

end.
